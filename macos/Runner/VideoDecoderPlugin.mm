//
//  VideoDecoderPlugin.mm
//  Runner
//
//  Multi-session low-latency video decoder using FFmpeg
//

#import "VideoDecoderPlugin.h"

// FFmpeg imports
extern "C" {
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libavutil/imgutils.h>
#include <libavutil/opt.h>
#include <libswscale/swscale.h>
}

// System imports (rename conflicting types)
#define AVMediaType SystemAVMediaType
#import <AVFoundation/AVFoundation.h>
#import <CoreVideo/CoreVideo.h>
#undef AVMediaType

#include <thread>
#include <queue>
#include <mutex>
#include <atomic>
#include <map>
#include <arpa/inet.h>
#include <sys/socket.h>

#ifndef be64toh
#include <libkern/OSByteOrder.h>
#define be64toh(x) OSSwapBigToHostInt64(x)
#endif

//------------------------------------------------------------------------------
// VideoDecoder Class (Handles one video stream)
//------------------------------------------------------------------------------
@interface VideoDecoder : NSObject <FlutterTexture>

@property(nonatomic, assign) int64_t textureId;
@property(nonatomic, weak) id<FlutterTextureRegistry> registry;

// State
@property(nonatomic, assign) std::atomic<bool>* isDecoding;
@property(nonatomic, assign) std::thread* decoderThread;
@property(nonatomic, assign) std::mutex* pixelBufferMutex;
@property(nonatomic, assign) CVPixelBufferRef latestPixelBuffer;

// FFmpeg
@property(nonatomic, assign) AVCodecContext* codecContext;
@property(nonatomic, assign) struct SwsContext* swsContext;
@property(nonatomic, assign) AVPacket* packet;
@property(nonatomic, assign) AVFrame* frame;

// Network
@property(nonatomic, assign) int socketFd;

- (instancetype)initWithRegistry:(id<FlutterTextureRegistry>)registry;
- (void)startWithHost:(NSString*)host port:(int)port result:(FlutterResult)result;
- (void)stop;

@end

@implementation VideoDecoder

- (instancetype)initWithRegistry:(id<FlutterTextureRegistry>)registry {
    self = [super init];
    if (self) {
        _registry = registry;
        _isDecoding = new std::atomic<bool>(false);
        _pixelBufferMutex = new std::mutex();
        _latestPixelBuffer = nil;
        _socketFd = -1;
        _decoderThread = nullptr;
        
        // Initialize FFmpeg structures to null
        _codecContext = nullptr;
        _swsContext = nullptr;
        _packet = nullptr;
        _frame = nullptr;
    }
    return self;
}

- (void)dealloc {
    [self stop];
    delete _isDecoding;
    delete _pixelBufferMutex;
}

- (CVPixelBufferRef)copyPixelBuffer {
    std::lock_guard<std::mutex> lock(*_pixelBufferMutex);
    if (_latestPixelBuffer) {
        CVPixelBufferRetain(_latestPixelBuffer);
        return _latestPixelBuffer;
    }
    return nullptr;
}

- (void)startWithHost:(NSString*)host port:(int)port result:(FlutterResult)result {
    // Register texture first to get ID
    _textureId = [_registry registerTexture:self];
    NSLog(@"[VideoDecoder] Created session for %@:%d with TextureID: %lld", host, port, _textureId);
    
    // Start thread
    *_isDecoding = true;
    _decoderThread = new std::thread([self, host, port]() {
        [self decoderThreadMain:host port:port];
    });
    
    // Return texture ID to Flutter
    result(@(_textureId));
}

- (void)stop {
    if (!*_isDecoding) return; // Already stopped
    
    NSLog(@"[VideoDecoder] Stopping session TextureID: %lld", _textureId);
    *_isDecoding = false;
    
    // Close socket to unblock recv()
    if (_socketFd >= 0) {
        shutdown(_socketFd, SHUT_RDWR);
        close(_socketFd);
        _socketFd = -1;
    }
    
    if (_decoderThread) {
        if (_decoderThread->joinable()) {
            _decoderThread->join();
        }
        delete _decoderThread;
        _decoderThread = nullptr;
    }
    
    if (_textureId != 0) {
        [_registry unregisterTexture:_textureId];
        _textureId = 0;
    }
    
    [self cleanupDecoder];
}

- (void)decoderThreadMain:(NSString*)host port:(int)port {
    @try {
        if (![self connectToServer:host port:port]) return;
        if (![self initializeDecoder]) return;
        [self decodingLoop];
    } @catch (NSException *e) {
        NSLog(@"[VideoDecoder] Exception: %@", e);
    } @finally {
        [self cleanupDecoder];
    }
}

- (BOOL)connectToServer:(NSString*)host port:(int)port {
    struct sockaddr_in serverAddr;
    _socketFd = socket(AF_INET, SOCK_STREAM, 0);
    if (_socketFd < 0) return NO;
    
    memset(&serverAddr, 0, sizeof(serverAddr));
    serverAddr.sin_family = AF_INET;
    serverAddr.sin_port = htons(port);
    inet_pton(AF_INET, [host UTF8String], &serverAddr.sin_addr);
    
    if (connect(_socketFd, (struct sockaddr*)&serverAddr, sizeof(serverAddr)) < 0) {
        NSLog(@"[VideoDecoder] Connect failed");
        close(_socketFd);
        _socketFd = -1;
        return NO;
    }
    return YES;
}

- (BOOL)initializeDecoder {
    const AVCodec* codec = avcodec_find_decoder(AV_CODEC_ID_HEVC);
    if (!codec) return NO;
    
    _codecContext = avcodec_alloc_context3(codec);
    _codecContext->flags |= AV_CODEC_FLAG_LOW_DELAY;
    _codecContext->flags2 |= AV_CODEC_FLAG2_FAST;
    _codecContext->thread_count = 1; // Multi-threading here adds latency?
    
    // Hardware accel
    AVBufferRef* hw_device_ctx = nullptr;
    if (av_hwdevice_ctx_create(&hw_device_ctx, AV_HWDEVICE_TYPE_VIDEOTOOLBOX, nullptr, nullptr, 0) >= 0) {
        _codecContext->hw_device_ctx = av_buffer_ref(hw_device_ctx);
        av_buffer_unref(&hw_device_ctx);
    }
    
    if (avcodec_open2(_codecContext, codec, nullptr) < 0) {
        avcodec_free_context(&_codecContext);
        return NO;
    }
    
    _packet = av_packet_alloc();
    _frame = av_frame_alloc();
    return YES;
}

- (void)cleanupDecoder {
    if (_swsContext) { sws_freeContext(_swsContext); _swsContext = nullptr; }
    if (_frame) { av_frame_free(&_frame); _frame = nullptr; }
    if (_packet) { av_packet_free(&_packet); _packet = nullptr; }
    if (_codecContext) { avcodec_free_context(&_codecContext); _codecContext = nullptr; }
    
    std::lock_guard<std::mutex> lock(*_pixelBufferMutex);
    if (_latestPixelBuffer) {
        CVPixelBufferRelease(_latestPixelBuffer);
        _latestPixelBuffer = nil;
    }
}

- (void)decodingLoop {
    std::vector<uint8_t> buffer;
    buffer.reserve(1024 * 1024);
    uint8_t tempBuf[65536];
    
    bool readingHeader = true;
    int neededBytes = 12;
    int payloadSize = 0;
    bool isConfigPacket = false;
    
    while (*_isDecoding) {
        ssize_t bytesRead = recv(_socketFd, tempBuf, sizeof(tempBuf), 0);
        if (bytesRead <= 0) break;
        
        buffer.insert(buffer.end(), tempBuf, tempBuf + bytesRead);
        
        while (buffer.size() >= neededBytes) {
            if (readingHeader) {
                // PTS (8) + SIZE (4)
                int64_t pts; memcpy(&pts, buffer.data(), 8);
                uint32_t size; memcpy(&size, buffer.data() + 8, 4);
                size = ntohl(size);
                pts = be64toh(pts);
                
                isConfigPacket = (pts < 0); // Scrcpy config packet flag
                payloadSize = size;
                buffer.erase(buffer.begin(), buffer.begin() + 12);
                neededBytes = payloadSize;
                readingHeader = false;
            } else {
                std::vector<uint8_t> payload(buffer.begin(), buffer.begin() + payloadSize);
                buffer.erase(buffer.begin(), buffer.begin() + payloadSize);
                
                if (isConfigPacket) {
                    NSLog(@"[VideoDecoder] Received Config Packet (Size: %d)", (int)payload.size());
                    [self decodePacket:payload];
                } else {
                    // NSLog(@"[VideoDecoder] Received Frame Packet (Size: %d)", (int)payload.size());
                    [self decodePacket:payload];
                }
                neededBytes = 12;
                readingHeader = true;
            }
        }
    }
}

- (void)decodePacket:(const std::vector<uint8_t>&)data {
    _packet->data = (uint8_t*)data.data();
    _packet->size = (int)data.size();
    
    if (avcodec_send_packet(_codecContext, _packet) < 0) return;
    
    while (avcodec_receive_frame(_codecContext, _frame) == 0) {
        CVPixelBufferRef pb = [self convertFrameToPixelBuffer:_frame];
        if (pb) {
            {
                std::lock_guard<std::mutex> lock(*_pixelBufferMutex);
                if (_latestPixelBuffer) CVPixelBufferRelease(_latestPixelBuffer);
                _latestPixelBuffer = pb;
            }
            // Notify Flutter
            __weak VideoDecoder* weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                VideoDecoder* strongSelf = weakSelf;
                if (strongSelf && strongSelf.textureId != 0) {
                    [strongSelf.registry textureFrameAvailable:strongSelf.textureId];
                }
            });
        }
        av_frame_unref(_frame);
    }
    av_packet_unref(_packet);
}

- (CVPixelBufferRef)convertFrameToPixelBuffer:(AVFrame*)frame {
    CVPixelBufferRef pixelBuffer = nullptr;
    NSDictionary* options = @{
        (id)kCVPixelBufferCGImageCompatibilityKey: @YES,
        (id)kCVPixelBufferCGBitmapContextCompatibilityKey: @YES,
        (id)kCVPixelBufferIOSurfacePropertiesKey: @{} // Critical for Metal/Flutter Texture
    };
    
    if (CVPixelBufferCreate(kCFAllocatorDefault, frame->width, frame->height,
                            kCVPixelFormatType_32BGRA, (__bridge CFDictionaryRef)options, &pixelBuffer) != kCVReturnSuccess) {
        return nullptr;
    }
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    if (!_swsContext || _codecContext->width != frame->width || _codecContext->height != frame->height) {
        if (_swsContext) sws_freeContext(_swsContext);
        _swsContext = sws_getContext(frame->width, frame->height, (AVPixelFormat)frame->format,
                                     frame->width, frame->height, AV_PIX_FMT_BGRA,
                                     SWS_FAST_BILINEAR, nullptr, nullptr, nullptr);
    }
    
    uint8_t* dest[1] = { (uint8_t*)CVPixelBufferGetBaseAddress(pixelBuffer) };
    int destStride[1] = { (int)CVPixelBufferGetBytesPerRow(pixelBuffer) };
    
    sws_scale(_swsContext, frame->data, frame->linesize, 0, frame->height, dest, destStride);
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    return pixelBuffer;
}

@end


//------------------------------------------------------------------------------
// VideoDecoderPlugin Class (Manager)
//------------------------------------------------------------------------------
@interface VideoDecoderPlugin()
@property(nonatomic, strong) NSObject<FlutterPluginRegistrar>* registrar;
@property(nonatomic, strong) NSMutableDictionary<NSNumber*, VideoDecoder*>* sessions;
@end

@implementation VideoDecoderPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"scraki/video_decoder"
                                     binaryMessenger:[registrar messenger]];
    VideoDecoderPlugin* instance = [[VideoDecoderPlugin alloc] initWithRegistrar:registrar];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)initWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    self = [super init];
    if (self) {
        _registrar = registrar;
        _sessions = [NSMutableDictionary dictionary];
        av_log_set_level(AV_LOG_ERROR);
    }
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"startDecoding" isEqualToString:call.method]) {
        NSString* url = call.arguments[@"url"];
        if (!url) { result([FlutterError errorWithCode:@"BAD_ARGS" message:@"No URL" details:nil]); return; }
        
        // Parse URL tcp://host:port
        NSString* urlStr = [url stringByReplacingOccurrencesOfString:@"tcp://" withString:@""];
        NSArray* parts = [urlStr componentsSeparatedByString:@":"];
        if (parts.count != 2) {
             result([FlutterError errorWithCode:@"BAD_URL" message:@"Invalid URL" details:nil]); return;
        }
        
        NSString* host = parts[0];
        int port = [parts[1] intValue];
        
        // Create NEW session
        VideoDecoder* decoder = [[VideoDecoder alloc] initWithRegistry:[_registrar textures]];
        [decoder startWithHost:host port:port result:^(id textureId) {
            if ([textureId isKindOfClass:[NSNumber class]]) {
                self.sessions[textureId] = decoder;
            }
            result(textureId);
        }];
        
    } else if ([@"stopDecoding" isEqualToString:call.method]) {
        NSNumber* textureId = call.arguments[@"textureId"];
        if (textureId) {
            VideoDecoder* decoder = _sessions[textureId];
            if (decoder) {
                [decoder stop];
                [_sessions removeObjectForKey:textureId];
            }
        }
        result(nil);
    } else {
        result(FlutterMethodNotImplemented);
    }
}

@end