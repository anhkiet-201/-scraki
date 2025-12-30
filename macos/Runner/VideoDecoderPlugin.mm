//
//  VideoDecoderPlugin.mm
//  Runner
//
//  Custom low-latency video decoder using FFmpeg
//

#import "VideoDecoderPlugin.h"

// FFmpeg and AVFoundation both define AVMediaType differently
// FFmpeg: enum AVMediaType
// AVFoundation: typedef NSString * AVMediaType
// Workaround: Temporarily rename system's AVMediaType during FFmpeg import

extern "C" {
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libavutil/imgutils.h>
#include <libavutil/opt.h>
#include <libswscale/swscale.h>
}

// Now import Apple frameworks
// Use macro to avoid conflict: rename system's AVMediaType
#define AVMediaType SystemAVMediaType
#import <AVFoundation/AVFoundation.h>
#import <CoreVideo/CoreVideo.h>
#undef AVMediaType

#include <thread>
#include <queue>
#include <mutex>
#include <condition_variable>
#include <atomic>
#include <arpa/inet.h>
#include <sys/socket.h>

// macOS doesn't have be64toh, define it
#ifndef be64toh
#include <libkern/OSByteOrder.h>
#define be64toh(x) OSSwapBigToHostInt64(x)
#endif

@interface VideoDecoderPlugin()

@property(nonatomic, strong) id<FlutterTextureRegistry> textureRegistry;
@property(nonatomic, strong) NSObject<FlutterPluginRegistrar>* registrar;
@property(nonatomic, assign) int64_t textureId;
@property(nonatomic, strong) FlutterMethodChannel* channel;

// Decoder state (using pointers for C++ objects)
@property(nonatomic, assign) std::atomic<bool>* isDecoding;
@property(nonatomic, assign) std::thread* decoderThread;
@property(nonatomic, assign) CVPixelBufferRef latestPixelBuffer;
@property(nonatomic, assign) std::mutex* pixelBufferMutex;

// FFmpeg contexts
@property(nonatomic, assign) AVCodecContext* codecContext;
@property(nonatomic, assign) const AVCodec* codec;
@property(nonatomic, assign) struct SwsContext* swsContext;
@property(nonatomic, assign) AVPacket* packet;
@property(nonatomic, assign) AVFrame* frame;

// Network
@property(nonatomic, assign) int socketFd;
@property(nonatomic, copy) NSString* streamUrl;

@end

@implementation VideoDecoderPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
        methodChannelWithName:@"scraki/video_decoder"
              binaryMessenger:[registrar messenger]];
    
    VideoDecoderPlugin* instance = [[VideoDecoderPlugin alloc] initWithRegistrar:registrar];
    instance.channel = channel;
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)initWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    self = [super init];
    if (self) {
        _registrar = registrar;
        _textureRegistry = [registrar textures];
        _isDecoding = new std::atomic<bool>(false);
        _pixelBufferMutex = new std::mutex();
        _latestPixelBuffer = nil;
        _socketFd = -1;
        _decoderThread = nullptr;
        
        // Initialize FFmpeg
        NSLog(@"[VideoDecoder] Initializing FFmpeg...");
    }
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"startDecoding" isEqualToString:call.method]) {
        NSDictionary* args = call.arguments;
        NSString* url = args[@"url"];
        
        if (!url) {
            result([FlutterError errorWithCode:@"INVALID_ARGS"
                                       message:@"Missing url parameter"
                                       details:nil]);
            return;
        }
        
        [self startDecodingWithUrl:url result:result];
        
    } else if ([@"stopDecoding" isEqualToString:call.method]) {
        [self stopDecoding];
        result(nil);
        
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)startDecodingWithUrl:(NSString*)url result:(FlutterResult)result {
    NSLog(@"[VideoDecoder] Starting decoder with URL: %@", url);
    
    // Stop any existing decoding
    [self stopDecoding];
    
    _streamUrl = url;
    
    // Register texture
    _textureId = [_textureRegistry registerTexture:self];
    NSLog(@"[VideoDecoder] Registered texture ID: %lld", _textureId);
    
    // Parse URL to get host and port
    // Expected format: tcp://127.0.0.1:PORT
    NSString* urlStr = [url stringByReplacingOccurrencesOfString:@"tcp://" withString:@""];
    NSArray* parts = [urlStr componentsSeparatedByString:@":"];
    
    if (parts.count != 2) {
        result([FlutterError errorWithCode:@"INVALID_URL"
                                   message:@"URL must be in format tcp://host:port"
                                   details:nil]);
        return;
    }
    
    NSString* host = parts[0];
    int port = [parts[1] intValue];
    
    // Initialize decoder in background thread
    *_isDecoding = true;
    _decoderThread = new std::thread([self, host, port, result]() {
        [self decoderThreadMain:host port:port result:result];
    });
    
    // Return texture ID immediately
    result(@(_textureId));
}

- (void)decoderThreadMain:(NSString*)host port:(int)port result:(FlutterResult)result {
    NSLog(@"[VideoDecoder] Decoder thread started");
    
    @try {
        // 1. Connect to video proxy
        if (![self connectToServer:host port:port]) {
            NSLog(@"[VideoDecoder] ERROR: Failed to connect to server");
            *_isDecoding = false;
            return;
        }
        
        // 2. Initialize FFmpeg decoder
        if (![self initializeDecoder]) {
            NSLog(@"[VideoDecoder] ERROR: Failed to initialize decoder");
            *_isDecoding = false;
            [self disconnectFromServer];
            return;
        }
        
        // 3. Start decoding loop
        [self decodingLoop];
        
    } @catch (NSException *exception) {
        NSLog(@"[VideoDecoder] Exception in decoder thread: %@", exception);
    } @finally {
        [self cleanupDecoder];
        [self disconnectFromServer];
        *_isDecoding = false;
        NSLog(@"[VideoDecoder] Decoder thread finished");
    }
}

- (BOOL)connectToServer:(NSString*)host port:(int)port {
    struct sockaddr_in serverAddr;
    
    _socketFd = socket(AF_INET, SOCK_STREAM, 0);
    if (_socketFd < 0) {
        NSLog(@"[VideoDecoder] ERROR: Failed to create socket");
        return NO;
    }
    
    memset(&serverAddr, 0, sizeof(serverAddr));
    serverAddr.sin_family = AF_INET;
    serverAddr.sin_port = htons(port);
    
    if (inet_pton(AF_INET, [host UTF8String], &serverAddr.sin_addr) <= 0) {
        NSLog(@"[VideoDecoder] ERROR: Invalid address");
        close(_socketFd);
        _socketFd = -1;
        return NO;
    }
    
    if (connect(_socketFd, (struct sockaddr*)&serverAddr, sizeof(serverAddr)) < 0) {
        NSLog(@"[VideoDecoder] ERROR: Connection failed");
        close(_socketFd);
        _socketFd = -1;
        return NO;
    }
    
    NSLog(@"[VideoDecoder] Connected to %@:%d", host, port);
    return YES;
}

- (void)disconnectFromServer {
    if (_socketFd >= 0) {
        close(_socketFd);
        _socketFd = -1;
        NSLog(@"[VideoDecoder] Disconnected from server");
    }
}

- (BOOL)initializeDecoder {
    // Find H.265/HEVC decoder
    _codec = avcodec_find_decoder(AV_CODEC_ID_HEVC);
    if (!_codec) {
        NSLog(@"[VideoDecoder] ERROR: HEVC decoder not found");
        return NO;
    }
    
    _codecContext = avcodec_alloc_context3(_codec);
    if (!_codecContext) {
        NSLog(@"[VideoDecoder] ERROR: Failed to allocate codec context");
        return NO;
    }
    
    // Low latency settings
    _codecContext->flags |= AV_CODEC_FLAG_LOW_DELAY;
    _codecContext->thread_count = 1;
    _codecContext->flags2 |= AV_CODEC_FLAG2_FAST;
    
    // Try hardware acceleration (VideoToolbox)
    AVBufferRef* hw_device_ctx = nullptr;
    int ret = av_hwdevice_ctx_create(&hw_device_ctx, AV_HWDEVICE_TYPE_VIDEOTOOLBOX, nullptr, nullptr, 0);
    if (ret >= 0) {
        _codecContext->hw_device_ctx = av_buffer_ref(hw_device_ctx);
        NSLog(@"[VideoDecoder] VideoToolbox hardware acceleration enabled");
        av_buffer_unref(&hw_device_ctx);
    } else {
        NSLog(@"[VideoDecoder] VideoToolbox not available, using software decode");
    }
    
    // Open codec
    ret = avcodec_open2(_codecContext, _codec, nullptr);
    if (ret < 0) {
        NSLog(@"[VideoDecoder] ERROR: Failed to open codec");
        avcodec_free_context(&_codecContext);
        return NO;
    }
    
    // Allocate packet and frame
    _packet = av_packet_alloc();
    _frame = av_frame_alloc();
    
    if (!_packet || !_frame) {
        NSLog(@"[VideoDecoder] ERROR: Failed to allocate packet/frame");
        return NO;
    }
    
    NSLog(@"[VideoDecoder] FFmpeg decoder initialized successfully");
    return YES;
}

- (void)decodingLoop {
    NSLog(@"[VideoDecoder] Starting decoding loop");
    
    std::vector<uint8_t> buffer;
    buffer.reserve(1024 * 1024); // 1MB buffer
    
    // Scrcpy packet parsing state
    bool readingHeader = true;
    int neededBytes = 12; // Packet header size
    int payloadSize = 0;
    bool isConfigPacket = false;
    
    std::vector<uint8_t> configData; // Store SPS/PPS
    
    uint8_t tempBuf[65536];
    
    while (*_isDecoding) {
        // Read from socket
        ssize_t bytesRead = recv(_socketFd, tempBuf, sizeof(tempBuf), 0);
        
        if (bytesRead <= 0) {
            if (bytesRead == 0) {
                NSLog(@"[VideoDecoder] Connection closed by server");
            } else {
                NSLog(@"[VideoDecoder] Socket read error");
            }
            break;
        }
        
        buffer.insert(buffer.end(), tempBuf, tempBuf + bytesRead);
        
        // Parse Scrcpy packets
        while (buffer.size() >= neededBytes) {
            if (readingHeader) {
                // Parse 12-byte packet header: [8 bytes PTS][4 bytes SIZE]
                int64_t pts = 0;
                memcpy(&pts, buffer.data(), 8);
                pts = be64toh(pts); // Big endian to host
                
                uint32_t size = 0;
                memcpy(&size, buffer.data() + 8, 4);
                size = ntohl(size); // Network to host byte order
                
                isConfigPacket = (pts < 0); // MSB set indicates config
                payloadSize = size;
                
                buffer.erase(buffer.begin(), buffer.begin() + 12);
                neededBytes = payloadSize;
                readingHeader = false;
                
            } else {
                // Read payload
                std::vector<uint8_t> payload(buffer.begin(), buffer.begin() + payloadSize);
                buffer.erase(buffer.begin(), buffer.begin() + payloadSize);
                
                if (isConfigPacket) {
                    // Store config (SPS/PPS)
                    configData = payload;
                    NSLog(@"[VideoDecoder] Config packet received (%zu bytes)", payload.size());
                } else {
                    // Decode frame
                    // Merge config with first frame if needed
                    if (!configData.empty()) {
                        std::vector<uint8_t> merged;
                        merged.insert(merged.end(), configData.begin(), configData.end());
                        merged.insert(merged.end(), payload.begin(), payload.end());
                        [self decodePacket:merged];
                        configData.clear();
                    } else {
                        [self decodePacket:payload];
                    }
                }
                
                // Reset for next packet
                neededBytes = 12;
                readingHeader = true;
            }
        }
    }
    
    NSLog(@"[VideoDecoder] Decoding loop finished");
}

- (void)decodePacket:(const std::vector<uint8_t>&)data {
    _packet->data = (uint8_t*)data.data();
    _packet->size = (int)data.size();
    
    // Send packet to decoder
    int ret = avcodec_send_packet(_codecContext, _packet);
    if (ret < 0) {
        NSLog(@"[VideoDecoder] Error sending packet to decoder");
        return;
    }
    
    // Receive frames (there may be multiple frames per packet)
    while (ret >= 0) {
        ret = avcodec_receive_frame(_codecContext, _frame);
        
        if (ret == AVERROR(EAGAIN) || ret == AVERROR_EOF) {
            break;
        } else if (ret < 0) {
            NSLog(@"[VideoDecoder] Error receiving frame");
            break;
        }
        
        // Frame decoded successfully
        [self processFrame:_frame];
        av_frame_unref(_frame);
    }
    
    av_packet_unref(_packet);
}

- (void)processFrame:(AVFrame*)frame {
    // Convert AVFrame to CVPixelBuffer
    CVPixelBufferRef pixelBuffer = [self convertFrameToPixelBuffer:frame];
    
    if (pixelBuffer) {
        // Update texture (with frame dropping)
        std::lock_guard<std::mutex> lock(*_pixelBufferMutex);
        
        // Drop old frame if exists
        if (_latestPixelBuffer) {
            CVPixelBufferRelease(_latestPixelBuffer);
        }
        
        _latestPixelBuffer = pixelBuffer;
        
        // Notify Flutter to render new frame
        dispatch_async(dispatch_get_main_queue(), ^{
            [self->_textureRegistry textureFrameAvailable:self->_textureId];
        });
    }
}

- (CVPixelBufferRef)convertFrameToPixelBuffer:(AVFrame*)frame {
    // Create pixel buffer
    CVPixelBufferRef pixelBuffer = nullptr;
    
    NSDictionary* options = @{
        (id)kCVPixelBufferCGImageCompatibilityKey: @YES,
        (id)kCVPixelBufferCGBitmapContextCompatibilityKey: @YES,
        (id)kCVPixelBufferIOSurfacePropertiesKey: @{}
    };
    
    CVReturn status = CVPixelBufferCreate(
        kCFAllocatorDefault,
        frame->width,
        frame->height,
        kCVPixelFormatType_32BGRA,
        (__bridge CFDictionaryRef)options,
        &pixelBuffer
    );
    
    if (status != kCVReturnSuccess) {
        NSLog(@"[VideoDecoder] Failed to create pixel buffer");
        return nullptr;
    }
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    void* pixelData = CVPixelBufferGetBaseAddress(pixelBuffer);
    int bytesPerRow = (int)CVPixelBufferGetBytesPerRow(pixelBuffer);
    
    // Initialize SwsContext for color conversion (YUV -> BGRA)
    if (!_swsContext || _codecContext->width != frame->width || _codecContext->height != frame->height) {
        if (_swsContext) {
            sws_freeContext(_swsContext);
        }
        
        _swsContext = sws_getContext(
            frame->width, frame->height, (AVPixelFormat)frame->format,
            frame->width, frame->height, AV_PIX_FMT_BGRA,
            SWS_FAST_BILINEAR, nullptr, nullptr, nullptr
        );
    }
    
    // Convert
    uint8_t* dest[1] = { (uint8_t*)pixelData };
    int destStride[1] = { bytesPerRow };
    
    sws_scale(_swsContext, frame->data, frame->linesize, 0, frame->height, dest, destStride);
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    return pixelBuffer;
}

- (void)cleanupDecoder {
    NSLog(@"[VideoDecoder] Cleaning up decoder");
    
    if (_swsContext) {
        sws_freeContext(_swsContext);
        _swsContext = nullptr;
    }
    
    if (_frame) {
        av_frame_free(&_frame);
    }
    
    if (_packet) {
        av_packet_free(&_packet);
    }
    
    if (_codecContext) {
        avcodec_free_context(&_codecContext);
    }
    
    std::lock_guard<std::mutex> lock(*_pixelBufferMutex);
    if (_latestPixelBuffer) {
        CVPixelBufferRelease(_latestPixelBuffer);
        _latestPixelBuffer = nil;
    }
}

- (void)stopDecoding {
    NSLog(@"[VideoDecoder] Stopping decoder");
    
    *_isDecoding = false;
    
    if (_decoderThread) {
        if (_decoderThread->joinable()) {
            _decoderThread->join();
        }
        delete _decoderThread;
        _decoderThread = nullptr;
    }
    
    if (_textureId != 0) {
        [_textureRegistry unregisterTexture:_textureId];
        _textureId = 0;
    }
}

- (void)dealloc {
    [self stopDecoding];
    
    // Cleanup C++ objects
    delete _isDecoding;
    delete _pixelBufferMutex;
}

#pragma mark - FlutterTexture

- (CVPixelBufferRef)copyPixelBuffer {
    std::lock_guard<std::mutex> lock(*_pixelBufferMutex);
    
    if (_latestPixelBuffer) {
        CVPixelBufferRetain(_latestPixelBuffer);
        return _latestPixelBuffer;
    }
    
    return nullptr;
}

@end
