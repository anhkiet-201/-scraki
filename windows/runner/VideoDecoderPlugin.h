#ifndef VIDEO_DECODER_PLUGIN_H_
#define VIDEO_DECODER_PLUGIN_H_

#include <winsock2.h>
#include <ws2tcpip.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <flutter/texture_registrar.h>

#include <memory>
#include <thread>
#include <atomic>
#include <mutex>
#include <vector>
#include <map>
#include <string>
#include <stdexcept>
#include <iostream>
#include <cstring>

extern std::atomic<int64_t> g_active_buffers;
extern std::atomic<int64_t> g_total_pixels_allocated;

// FFmpeg
extern "C" {
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libavutil/imgutils.h>
#include <libswscale/swscale.h>
}

class VideoDecoderPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(FlutterDesktopPluginRegistrarRef registrar);

  VideoDecoderPlugin(flutter::TextureRegistrar* texture_registrar);

  virtual ~VideoDecoderPlugin();

  // Disallow copy and assign.
  VideoDecoderPlugin(const VideoDecoderPlugin&) = delete;
  VideoDecoderPlugin& operator=(const VideoDecoderPlugin&) = delete;

  struct VideoSessionState {
      flutter::TextureRegistrar* texture_registrar;
      int64_t texture_id = -1;
      std::unique_ptr<flutter::TextureVariant> texture;
      
      struct RGBAFrame {
          std::vector<uint8_t> pixels;
          int width = 0;
          int height = 0;
          RGBAFrame(int w, int h);
          ~RGBAFrame();
      };

      std::recursive_mutex pixel_buffer_mutex;
      std::shared_ptr<RGBAFrame> front_buffer;
      std::shared_ptr<RGBAFrame> last_front_buffer;
      std::vector<std::shared_ptr<RGBAFrame>> buffer_pool;
      
      int width = 0; // Current decoder width
      int height = 0; // Current decoder height
      FlutterDesktopPixelBuffer flutter_pixel_buffer;
      
      std::atomic<bool> is_alive{true};
      std::atomic<bool> is_decoding{false};
      SOCKET socket = INVALID_SOCKET;

      // FFmpeg
      AVCodecContext* codec_context = nullptr;
      const AVCodec* codec = nullptr;
      AVPacket* packet = nullptr;
      AVFrame* frame = nullptr;
      SwsContext* sws_context = nullptr;

      VideoSessionState(flutter::TextureRegistrar* registrar) : texture_registrar(registrar), texture_id(-1) {
          memset(&flutter_pixel_buffer, 0, sizeof(flutter_pixel_buffer));
      }

      ~VideoSessionState();
  };

  class VideoSession {
   public:
    VideoSession(flutter::TextureRegistrar* texture_registrar, const std::string& host, int port);
    ~VideoSession();

    int64_t texture_id() const { return state_ ? state_->texture_id : -1; }

   private:
    static void DecodingLoop(std::shared_ptr<VideoSessionState> state, std::string host, int port);
    static bool ConnectToServer(std::shared_ptr<VideoSessionState> state, const std::string& host, int port);
    static bool InitializeDecoder(std::shared_ptr<VideoSessionState> state);
    static void DecodePacket(std::shared_ptr<VideoSessionState> state, const std::vector<uint8_t>& data);
    static void ProcessFrame(std::shared_ptr<VideoSessionState> state, AVFrame* frame);

    std::shared_ptr<VideoSessionState> state_;
    std::unique_ptr<std::thread> decoder_thread_;
  };

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void StartDecoding(const std::string& url,
                     std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void StopDecoding(int64_t texture_id);
  void StopAllDecoding();

  flutter::TextureRegistrar* texture_registrar_;
  std::map<int64_t, std::unique_ptr<VideoSession>> sessions_;
  std::mutex sessions_mutex_;
};

#endif  // VIDEO_DECODER_PLUGIN_H_
