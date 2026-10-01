//
//  VideoDecoderPlugin.mm
//  Runner
//
//  Low-latency video decoder using VideoToolbox (no FFmpeg dependency).
//  Supports H264 and HEVC. Auto-detects codec from scrcpy config packets.
//

#import "VideoDecoderPlugin.h"

#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>
#import <VideoToolbox/VideoToolbox.h>

#include <arpa/inet.h>
#include <atomic>
#include <mutex>
#include <sys/socket.h>
#include <thread>
#include <vector>

#include <libkern/OSByteOrder.h>
#ifndef be64toh
#define be64toh(x) OSSwapBigToHostInt64(x)
#endif

// ---------------------------------------------------------------------------
// Codec type
// ---------------------------------------------------------------------------

typedef enum : NSInteger {
  VideoCodecUnknown = 0,
  VideoCodecH264,
  VideoCodecHEVC,
} VideoCodecType;

// ---------------------------------------------------------------------------
// Helper: Parse Annex-B → list of (firstByte, NAL data) pairs
// ---------------------------------------------------------------------------

static std::vector<std::pair<uint8_t, std::vector<uint8_t>>>
parseNalUnits(const std::vector<uint8_t> &data) {
  std::vector<std::pair<uint8_t, std::vector<uint8_t>>> result;
  size_t offset = 0;

  while (offset + 3 <= data.size()) {
    // Find start code (3 or 4 byte)
    size_t scStart = SIZE_MAX, scLen = 0;
    for (size_t i = offset; i + 3 <= data.size(); i++) {
      if (data[i] == 0 && data[i + 1] == 0) {
        if (data[i + 2] == 1) {
          scStart = i;
          scLen = 3;
          break;
        } else if (i + 4 <= data.size() && data[i + 2] == 0 &&
                   data[i + 3] == 1) {
          scStart = i;
          scLen = 4;
          break;
        }
      }
    }
    if (scStart == SIZE_MAX)
      break;

    size_t nalStart = scStart + scLen;
    if (nalStart >= data.size())
      break;

    // Find end of this NAL (next start code)
    size_t nalEnd = data.size();
    for (size_t i = nalStart; i + 3 <= data.size(); i++) {
      if (data[i] == 0 && data[i + 1] == 0) {
        if (data[i + 2] == 1) {
          nalEnd = i;
          break;
        } else if (i + 4 <= data.size() && data[i + 2] == 0 &&
                   data[i + 3] == 1) {
          nalEnd = i;
          break;
        }
      }
    }

    if (nalStart < nalEnd) {
      result.push_back(
          {data[nalStart],
           std::vector<uint8_t>(data.begin() + nalStart, data.begin() + nalEnd)});
    }
    offset = nalEnd;
  }
  return result;
}

// ---------------------------------------------------------------------------
// Helper: Convert Annex-B stream → length-prefixed (AVCC/HVCC) for VT.
// Also filters out in-band parameter sets (VPS, SPS, PPS) since VideoToolbox
// has them in CMVideoFormatDescription and rejects them in CMSampleBuffer (-12909).
// ---------------------------------------------------------------------------

static std::vector<uint8_t>
annexBToLengthPrefixed(const std::vector<uint8_t> &annexB, VideoCodecType codecType) {
  std::vector<uint8_t> out;
  out.reserve(annexB.size());

  auto nalUnits = parseNalUnits(annexB);
  for (const auto &pair : nalUnits) {
    uint8_t firstByte = pair.first;
    const auto &nal = pair.second;
    if (nal.empty()) continue;

    // Filter in-band parameter sets from CMSampleBuffer to avoid
    // kVTVideoDecoderBadDataErr (-12909).
    if (codecType == VideoCodecHEVC) {
      uint8_t hevcType = (firstByte >> 1) & 0x3F;
      if (hevcType == 32 || hevcType == 33 || hevcType == 34) {
        continue; // VPS, SPS, PPS
      }
    } else if (codecType == VideoCodecH264) {
      uint8_t h264Type = firstByte & 0x1F;
      if (h264Type == 7 || h264Type == 8) {
        continue; // SPS, PPS
      }
    }

    uint32_t len = (uint32_t)nal.size();
    // Standard Big-Endian 4-byte length prefix (AVCC/HVCC)
    out.push_back((len >> 24) & 0xFF);
    out.push_back((len >> 16) & 0xFF);
    out.push_back((len >> 8) & 0xFF);
    out.push_back(len & 0xFF);
    out.insert(out.end(), nal.begin(), nal.end());
  }
  return out;
}

// ---------------------------------------------------------------------------
// VideoDecoder – one per mirroring session
// ---------------------------------------------------------------------------

@interface VideoDecoder : NSObject <FlutterTexture>

@property(nonatomic, assign) int64_t textureId;
@property(nonatomic, weak) id<FlutterTextureRegistry> registry;

// Thread / socket state
@property(nonatomic, assign) std::atomic<bool> *isDecodingPtr;
@property(nonatomic, assign) std::thread *decoderThread;
@property(nonatomic, assign) int socketFd;

// Pixel buffer (shared with Flutter)
@property(nonatomic, assign) std::mutex *pixelBufferMutex;
@property(nonatomic, assign) CVPixelBufferRef latestPixelBuffer;
@property(nonatomic, assign) std::atomic<bool> *isVisiblePtr;

// VideoToolbox
@property(nonatomic, assign) VTDecompressionSessionRef decompressionSession;
@property(nonatomic, assign) CMFormatDescriptionRef formatDescription;
@property(nonatomic, assign) VideoCodecType codecType;

// Stored parameter sets (rebuilt on config packet)
@property(nonatomic, strong) NSData *vpsData; // HEVC VPS
@property(nonatomic, strong) NSData *spsData;
@property(nonatomic, strong) NSData *ppsData;

- (instancetype)initWithRegistry:(id<FlutterTextureRegistry>)registry;
- (void)startWithHost:(NSString *)host
                 port:(int)port
               result:(FlutterResult)result;
- (void)stop;
- (void)setVisibility:(BOOL)visible;

@end

@implementation VideoDecoder

- (instancetype)initWithRegistry:(id<FlutterTextureRegistry>)registry {
  self = [super init];
  if (self) {
    _registry = registry;
    _isDecodingPtr = new std::atomic<bool>(false);
    _pixelBufferMutex = new std::mutex();
    _latestPixelBuffer = nil;
    _socketFd = -1;
    _decoderThread = nullptr;
    _isVisiblePtr = new std::atomic<bool>(true);
    _decompressionSession = NULL;
    _formatDescription = NULL;
    _codecType = VideoCodecUnknown;
  }
  return self;
}

- (void)dealloc {
  [self stop];
  delete _isDecodingPtr;
  delete _pixelBufferMutex;
  delete _isVisiblePtr;
}

- (CVPixelBufferRef)copyPixelBuffer {
  std::lock_guard<std::mutex> lock(*_pixelBufferMutex);
  if (_latestPixelBuffer) {
    CVPixelBufferRetain(_latestPixelBuffer);
    return _latestPixelBuffer;
  }
  return nullptr;
}

- (void)setVisibility:(BOOL)visible {
  _isVisiblePtr->store(visible);
}

- (void)startWithHost:(NSString *)host
                 port:(int)port
               result:(FlutterResult)result {
  _textureId = [_registry registerTexture:self];
  *_isDecodingPtr = true;
  _decoderThread = new std::thread(
      [self, host, port]() { [self decoderThreadMain:host port:port]; });
  result(@(_textureId));
}

- (void)stop {
  if (!*_isDecodingPtr)
    return;

  *_isDecodingPtr = false;

  if (_socketFd >= 0) {
    shutdown(_socketFd, SHUT_RDWR);
    close(_socketFd);
    _socketFd = -1;
  }

  int64_t tid = _textureId;
  if (tid != 0) {
    [_registry unregisterTexture:tid];
    _textureId = 0;
  }

  std::thread *t = _decoderThread;
  _decoderThread = nullptr;

  dispatch_async(
      dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (t) {
          if (t->joinable())
            t->join();
          delete t;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
          [self cleanupDecoder];
        });
      });
}

- (void)cleanupDecoder {
  if (_decompressionSession) {
    VTDecompressionSessionInvalidate(_decompressionSession);
    CFRelease(_decompressionSession);
    _decompressionSession = NULL;
  }
  if (_formatDescription) {
    CFRelease(_formatDescription);
    _formatDescription = NULL;
  }
  std::lock_guard<std::mutex> lock(*_pixelBufferMutex);
  if (_latestPixelBuffer) {
    CVPixelBufferRelease(_latestPixelBuffer);
    _latestPixelBuffer = nil;
  }
}

// ---------------------------------------------------------------------------
// Networking
// ---------------------------------------------------------------------------

- (void)decoderThreadMain:(NSString *)host port:(int)port {
  @try {
    if (![self connectToServer:host port:port])
      return;
    [self decodingLoop];
  } @catch (NSException *e) {
    NSLog(@"[VideoDecoder] Exception: %@", e);
  }
  [self cleanupDecoder];
}

- (BOOL)connectToServer:(NSString *)host port:(int)port {
  struct sockaddr_in addr;
  _socketFd = socket(AF_INET, SOCK_STREAM, 0);
  if (_socketFd < 0)
    return NO;

  memset(&addr, 0, sizeof(addr));
  addr.sin_family = AF_INET;
  addr.sin_port = htons(port);
  inet_pton(AF_INET, [host UTF8String], &addr.sin_addr);

  if (connect(_socketFd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
    NSLog(@"[VideoDecoder] Connect failed to %@:%d", host, port);
    close(_socketFd);
    _socketFd = -1;
    return NO;
  }
  return YES;
}

- (void)decodingLoop {
  std::vector<uint8_t> buffer;
  buffer.reserve(1024 * 1024);
  uint8_t tempBuf[65536];

  bool readingHeader = true;
  int neededBytes = 12;
  int payloadSize = 0;
  bool isConfigPacket = false;

  while (*_isDecodingPtr) {
    ssize_t n = recv(_socketFd, tempBuf, sizeof(tempBuf), 0);
    if (n <= 0)
      break;

    buffer.insert(buffer.end(), tempBuf, tempBuf + n);

    while ((int)buffer.size() >= neededBytes) {
      if (readingHeader) {
        int64_t pts;
        memcpy(&pts, buffer.data(), 8);
        uint32_t size;
        memcpy(&size, buffer.data() + 8, 4);
        size = ntohl(size);
        pts = be64toh(pts);

        isConfigPacket = (pts < 0);
        payloadSize = (int)size;
        buffer.erase(buffer.begin(), buffer.begin() + 12);
        neededBytes = payloadSize;
        readingHeader = false;
      } else {
        std::vector<uint8_t> payload(buffer.begin(),
                                     buffer.begin() + payloadSize);
        buffer.erase(buffer.begin(), buffer.begin() + payloadSize);

        if (isConfigPacket) {
          [self processConfigPacket:payload];
        } else {
          [self processFramePacket:payload];
        }

        neededBytes = 12;
        readingHeader = true;
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Config packet: detect codec, extract param sets, create VT session
// ---------------------------------------------------------------------------

- (void)processConfigPacket:(const std::vector<uint8_t> &)data {
  auto nalUnits = parseNalUnits(data);
  if (nalUnits.empty()) {
    NSLog(@"[VideoDecoder] Config packet: no NAL units found");
    return;
  }

  NSData *vps = nil, *sps = nil, *pps = nil;
  VideoCodecType detected = VideoCodecUnknown;

  for (auto &nalPair : nalUnits) {
    uint8_t firstByte = nalPair.first;
    const auto &nal = nalPair.second;
    uint8_t h264Type = firstByte & 0x1F;
    uint8_t hevcType = (firstByte >> 1) & 0x3F;
    NSData *d = [NSData dataWithBytes:nal.data() length:nal.size()];

    if (h264Type == 7) { // H264 SPS
      sps = d;
      detected = VideoCodecH264;
    } else if (h264Type == 8) { // H264 PPS
      pps = d;
      detected = VideoCodecH264;
    } else if (hevcType == 32) { // HEVC VPS
      vps = d;
      detected = VideoCodecHEVC;
    } else if (hevcType == 33) { // HEVC SPS
      sps = d;
      detected = VideoCodecHEVC;
    } else if (hevcType == 34) { // HEVC PPS
      pps = d;
      detected = VideoCodecHEVC;
    }
  }

  if (detected == VideoCodecUnknown || !sps || !pps) {
    NSLog(@"[VideoDecoder] Config: could not parse param sets (codec=%ld "
          @"sps=%@ pps=%@)",
          (long)detected, sps ? @"OK" : @"nil", pps ? @"OK" : @"nil");
    return;
  }

  _codecType = detected;
  _vpsData = vps;
  _spsData = sps;
  _ppsData = pps;

  [self recreateSession];
}

- (void)recreateSession {
  // Tear down existing session
  if (_decompressionSession) {
    VTDecompressionSessionInvalidate(_decompressionSession);
    CFRelease(_decompressionSession);
    _decompressionSession = NULL;
  }
  if (_formatDescription) {
    CFRelease(_formatDescription);
    _formatDescription = NULL;
  }

  OSStatus status;

  // --- Create format description ---
  if (_codecType == VideoCodecH264) {
    const uint8_t *params[2] = {(const uint8_t *)_spsData.bytes,
                                 (const uint8_t *)_ppsData.bytes};
    size_t sizes[2] = {_spsData.length, _ppsData.length};
    status = CMVideoFormatDescriptionCreateFromH264ParameterSets(
        kCFAllocatorDefault, 2, params, sizes, 4, &_formatDescription);
  } else {
    NSMutableArray<NSData *> *sets = [NSMutableArray array];
    if (_vpsData)
      [sets addObject:_vpsData];
    [sets addObject:_spsData];
    [sets addObject:_ppsData];

    size_t count = sets.count;
    const uint8_t **params =
        (const uint8_t **)malloc(sizeof(uint8_t *) * count);
    size_t *sizes = (size_t *)malloc(sizeof(size_t) * count);
    for (size_t i = 0; i < count; i++) {
      params[i] = (const uint8_t *)sets[i].bytes;
      sizes[i] = sets[i].length;
    }
    status = CMVideoFormatDescriptionCreateFromHEVCParameterSets(
        kCFAllocatorDefault, count, params, sizes, 4, nullptr,
        &_formatDescription);
    free(params);
    free(sizes);
  }

  if (status != noErr) {
    NSLog(@"[VideoDecoder] CMVideoFormatDescriptionCreate failed: %d",
          (int)status);
    return;
  }

  // --- Create decompression session ---
  NSDictionary *outputAttrs = @{
    (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA),
    (id)kCVPixelBufferIOSurfacePropertiesKey : @{},
    (id)kCVPixelBufferMetalCompatibilityKey : @YES,
  };

  VTDecompressionOutputCallbackRecord callback;
  callback.decompressionOutputCallback = vtOutputCallback;
  callback.decompressionOutputRefCon = (__bridge void *)self;

  NSDictionary *sessionAttrs = @{
    (id)kVTDecompressionPropertyKey_RealTime : @YES,
  };

  status = VTDecompressionSessionCreate(
      kCFAllocatorDefault, _formatDescription,
      (__bridge CFDictionaryRef)sessionAttrs,
      (__bridge CFDictionaryRef)outputAttrs, &callback,
      &_decompressionSession);

  if (status != noErr) {
    NSLog(@"[VideoDecoder] VTDecompressionSessionCreate failed: %d",
          (int)status);
    _decompressionSession = NULL;
    return;
  }
}

// ---------------------------------------------------------------------------
// VideoToolbox output callback (called on an internal VT thread)
// ---------------------------------------------------------------------------

static void vtOutputCallback(void *refCon, void *sourceFrameRefCon,
                              OSStatus status,
                              VTDecodeInfoFlags infoFlags,
                              CVImageBufferRef imageBuffer,
                              CMTime presentationTimeStamp,
                              CMTime presentationDuration) {
  if (status != noErr || imageBuffer == NULL) {
    if (status != noErr)
      NSLog(@"[VideoDecoder] VT decode error in callback: %d", (int)status);
    return;
  }

  VideoDecoder *decoder = (__bridge VideoDecoder *)refCon;

  if (!decoder.isVisiblePtr->load())
    return;

  CVPixelBufferRef pb = (CVPixelBufferRef)imageBuffer;
  CVPixelBufferRetain(pb);

  {
    std::lock_guard<std::mutex> lock(*decoder.pixelBufferMutex);
    if (decoder.latestPixelBuffer)
      CVPixelBufferRelease(decoder.latestPixelBuffer);
    decoder.latestPixelBuffer = pb;
  }

  __weak VideoDecoder *weak = decoder;
  dispatch_async(dispatch_get_main_queue(), ^{
    VideoDecoder *strong = weak;
    if (strong && strong.textureId != 0)
      [strong.registry textureFrameAvailable:strong.textureId];
  });
}

// ---------------------------------------------------------------------------
// Frame packet: convert Annex-B → length-prefixed → CMSampleBuffer → VT
// ---------------------------------------------------------------------------

- (void)processFramePacket:(const std::vector<uint8_t> &)data {
  if (!_decompressionSession || !_formatDescription)
    return; // Config not received yet

  if (data.empty()) return;

  std::vector<uint8_t> lpData = annexBToLengthPrefixed(data, _codecType);
  if (lpData.empty()) {
    // If all NALs in this packet were parameter sets, update configuration
    auto nalUnits = parseNalUnits(data);
    for (const auto &pair : nalUnits) {
      uint8_t firstByte = pair.first;
      if (_codecType == VideoCodecHEVC) {
        uint8_t hevcType = (firstByte >> 1) & 0x3F;
        if (hevcType == 32 || hevcType == 33 || hevcType == 34) {
          [self processConfigPacket:data];
          break;
        }
      } else if (_codecType == VideoCodecH264) {
        uint8_t h264Type = firstByte & 0x1F;
        if (h264Type == 7 || h264Type == 8) {
          [self processConfigPacket:data];
          break;
        }
      }
    }
    return;
  }

  // CMBlockBuffer takes ownership of heapCopy via kCFAllocatorMalloc
  CMBlockBufferRef blockBuf = NULL;
  void *heapCopy = malloc(lpData.size());
  if (!heapCopy) return;
  memcpy(heapCopy, lpData.data(), lpData.size());

  OSStatus status = CMBlockBufferCreateWithMemoryBlock(
      kCFAllocatorDefault,
      heapCopy,
      lpData.size(),
      kCFAllocatorMalloc, // CM will call free() on heapCopy
      NULL, 0, lpData.size(), 0,
      &blockBuf);

  if (status != noErr || !blockBuf) {
    free(heapCopy);
    NSLog(@"[VideoDecoder] CMBlockBufferCreate failed: %d", (int)status);
    return;
  }

  // CMSampleBuffer: 0 timing entries indicates untimed / real-time frames
  size_t sampleSize = lpData.size();
  CMSampleBufferRef sampleBuf = NULL;
  status = CMSampleBufferCreateReady(kCFAllocatorDefault, blockBuf,
                                     _formatDescription, 1, 0, NULL, 1,
                                     &sampleSize, &sampleBuf);
  CFRelease(blockBuf);

  if (status != noErr || !sampleBuf) {
    NSLog(@"[VideoDecoder] CMSampleBufferCreateReady failed: %d", (int)status);
    return;
  }

  VTDecodeInfoFlags flagsOut = 0;
  status = VTDecompressionSessionDecodeFrame(
      _decompressionSession, sampleBuf,
      kVTDecodeFrame_EnableAsynchronousDecompression, NULL, &flagsOut);

  CFRelease(sampleBuf);

  if (status != noErr) {
    static int errCount = 0;
    if (++errCount <= 10 || errCount % 100 == 0) {
      NSLog(@"[VideoDecoder] VTDecompressionSessionDecodeFrame error: %d (sampleSize=%zu, count=%d)",
            (int)status, lpData.size(), errCount);
    }
  }
}


@end

// ---------------------------------------------------------------------------
// VideoDecoderPlugin – channel handler / session manager
// ---------------------------------------------------------------------------

@interface VideoDecoderPlugin ()
@property(nonatomic, strong) NSObject<FlutterPluginRegistrar> *registrar;
@property(nonatomic, strong)
    NSMutableDictionary<NSNumber *, VideoDecoder *> *sessions;
@end

@implementation VideoDecoderPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FlutterMethodChannel *channel = [FlutterMethodChannel
      methodChannelWithName:@"com.scraki.video_decoder"
            binaryMessenger:[registrar messenger]];
  VideoDecoderPlugin *instance =
      [[VideoDecoderPlugin alloc] initWithRegistrar:registrar];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)initWithRegistrar:
    (NSObject<FlutterPluginRegistrar> *)registrar {
  self = [super init];
  if (self) {
    _registrar = registrar;
    _sessions = [NSMutableDictionary dictionary];
  }
  return self;
}

- (void)handleMethodCall:(FlutterMethodCall *)call
                  result:(FlutterResult)result {
  if ([@"startDecoding" isEqualToString:call.method]) {
    NSString *url = call.arguments[@"url"];
    if (!url) {
      result([FlutterError errorWithCode:@"BAD_ARGS"
                                 message:@"No URL"
                                 details:nil]);
      return;
    }

    // Parse tcp://host:port
    NSString *stripped =
        [url stringByReplacingOccurrencesOfString:@"tcp://" withString:@""];
    NSArray *parts = [stripped componentsSeparatedByString:@":"];
    if (parts.count != 2) {
      result([FlutterError errorWithCode:@"BAD_URL"
                                 message:@"Invalid URL format"
                                 details:nil]);
      return;
    }

    NSString *host = parts[0];
    int port = [parts[1] intValue];

    VideoDecoder *decoder =
        [[VideoDecoder alloc] initWithRegistry:[_registrar textures]];
    [decoder startWithHost:host
                      port:port
                    result:^(id textureId) {
                      if ([textureId isKindOfClass:[NSNumber class]]) {
                        self.sessions[textureId] = decoder;
                      }
                      result(textureId);
                    }];

  } else if ([@"stopDecoding" isEqualToString:call.method]) {
    NSNumber *textureId = call.arguments[@"textureId"];
    if (textureId) {
      VideoDecoder *decoder = _sessions[textureId];
      if (decoder) {
        [decoder stop];
        [_sessions removeObjectForKey:textureId];
      }
    }
    result(nil);

  } else if ([@"flush" isEqualToString:call.method]) {
    // No-op for VideoToolbox: VT handles frame ordering internally.
    result(nil);

  } else if ([@"setVisibility" isEqualToString:call.method]) {
    NSNumber *textureId = call.arguments[@"textureId"];
    BOOL visible = [call.arguments[@"visible"] boolValue];
    if (textureId) {
      VideoDecoder *decoder = _sessions[textureId];
      [decoder setVisibility:visible];
    }
    result(nil);

  } else {
    result(FlutterMethodNotImplemented);
  }
}

@end
