//
//  VideoDecoderPlugin.h
//  Runner
//
//  Custom low-latency video decoder plugin for Flutter
//

#import <FlutterMacOS/FlutterMacOS.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VideoDecoderPlugin : NSObject<FlutterPlugin, FlutterTexture>

@end

NS_ASSUME_NONNULL_END
