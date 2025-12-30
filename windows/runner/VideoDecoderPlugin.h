#ifndef VIDEO_DECODER_PLUGIN_H_
#define VIDEO_DECODER_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <flutter/texture_registrar.h>

#include <memory>
#include <thread>
#include <atomic>
#include <mutex>
#include <vector>

// Winsock2
#include <winsock2.h>
#include <ws2tcpip.h>

// FFmpeg
extern "C" {
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libavutil/imgutils.h>
#include <libswscale/swscale.h>
}

class VideoDecoderPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  VideoDecoderPlugin(flutter::TextureRegistrar* texture_registrar);

  virtual ~VideoDecoderPlugin();

  // Disallow copy and assign.
  VideoDecoderPlugin(const VideoDecoderPlugin&) = delete;
  VideoDecoderPlugin& operator=(const VideoDecoderPlugin&) = delete;

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void StartDecoding(const std::string& url,
                     std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void StopDecoding();

  // Decoding loop running in a separate thread
  void DecodingLoop(const std::string& host, int port);
  bool ConnectToServer(const std::string& host, int port);
  bool InitializeDecoder();
  void CleanupDecoder();
  void DecodePacket(const std::vector<uint8_t>& data);
  void ProcessFrame(AVFrame* frame);


  flutter::TextureRegistrar* texture_registrar_;
  int64_t texture_id_ = -1;
  std::unique_ptr<flutter::TextureVariant> texture_;

  // Threading
  std::thread decoder_thread_;
  std::atomic<bool> is_decoding_{false};
  std::mutex pixel_buffer_mutex_;

  // FFmpeg
  AVCodecContext* codec_context_ = nullptr;
  const AVCodec* codec_ = nullptr;
  AVPacket* packet_ = nullptr;
  AVFrame* frame_ = nullptr;
  SwsContext* sws_context_ = nullptr;

  // Frame buffer
  std::vector<uint8_t> pixel_buffer_;
  int width_ = 0;
  int height_ = 0;

  // Network
  SOCKET socket_ = INVALID_SOCKET;
};

#endif  // VIDEO_DECODER_PLUGIN_H_
