#include "VideoDecoderPlugin.h"

#include <iostream>
#include <string>

#pragma comment(lib, "ws2_32.lib")

// Helper to convert std::string to std::wstring
std::wstring Utf8ToWide(const std::string& str) {
  if (str.empty()) return std::wstring();
  int size_needed = MultiByteToWideChar(CP_UTF8, 0, &str[0], (int)str.size(), NULL, 0);
  std::wstring wstrTo(size_needed, 0);
  MultiByteToWideChar(CP_UTF8, 0, &str[0], (int)str.size(), &wstrTo[0], size_needed);
  return wstrTo;
}

// Pixel buffer texture
class PixelBufferTexture : public flutter::Texture {
 public:
  PixelBufferTexture(std::vector<uint8_t>* buffer, std::mutex* mutex, int width, int height)
      : buffer_(buffer), mutex_(mutex), width_(width), height_(height) {}

  virtual ~PixelBufferTexture() = default;

  const flutter::TextureVariant* OnGetTextureVariant(
      const flutter::FlutterView* view, 
      const flutter::TextureVariant* old_variant) override {
    return nullptr; // Not using hardware texture variant yet
  }
  
  // Flutter Windows Texture API is ... basic. It mostly supports PixelBuffer.
  // We need to implement the struct FlutterDesktopPixelBuffer.
  // Wait, the C++ API wrapper simplifies this.
  // Actually, we usually register a callback.
  // Let's check standard implementation. 
  // Flutter C++ API: TextureRegistrar->RegisterTexture(TextureVariant)
  // TextureVariant is a std::variant<PixelBufferTexture, ...>
  // We are implementing flutter::Texture? No wait.
  // The C++ API uses flutter::Texture derived classes? No.
  // Let's check flutter_texture_registrar.h in headers if possible.
  // Standard way: RegisterTexture accepts a generic texture object.
  // Let's use the simpler C API style via C++ wrapper if simpler, or standard C++ class.
  // Actually, standard C++ plugins usually implement a class inheriting from flutter::Texture.
};

// Start simple: Use the C-style struct approach if C++ wrapper is complex or undocumented in my knowledge base.
// BUT, we are in C++ runner.
// Let's look at `flutter::TextureRegistrar` implementation.
// It has `RegisterTexture(TextureVariant* texture)`.
// We need to provide a `flutter::PixelBufferTexture`.

// Re-implementing:
void VideoDecoderPlugin::RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar) {
  auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      registrar->messenger(), "scraki/video_decoder",
      &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<VideoDecoderPlugin>(registrar->texture_registrar());

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto& call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

VideoDecoderPlugin::VideoDecoderPlugin(flutter::TextureRegistrar* texture_registrar)
    : texture_registrar_(texture_registrar) {
    // Initialize Winsock
    WSADATA wsaData;
    WSAStartup(MAKEWORD(2, 2), &wsaData);
}

VideoDecoderPlugin::~VideoDecoderPlugin() {
  StopDecoding();
  WSACleanup();
}

void VideoDecoderPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("startDecoding") == 0) {
    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (arguments) {
      auto url_it = arguments->find(flutter::EncodableValue("url"));
      if (url_it != arguments->end()) {
        std::string url = std::get<std::string>(url_it->second);
        StartDecoding(url, std::move(result));
        return;
      }
    }
    result->Error("INVALID_ARGS", "Missing url parameter");
  } else if (method_call.method_name().compare("stopDecoding") == 0) {
    StopDecoding();
    result->Success();
  } else {
    result->NotImplemented();
  }
}

void VideoDecoderPlugin::StartDecoding(const std::string& url,
                                       std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    StopDecoding();

    // Parse URL (tcp://127.0.0.1:PORT)
    std::string prefix = "tcp://";
    std::string url_str = url;
    if (url.find(prefix) == 0) {
        url_str = url.substr(prefix.length());
    }
    
    size_t colon_pos = url_str.find(':');
    if (colon_pos == std::string::npos) {
        result->Error("INVALID_URL", "URL must be in format tcp://host:port");
        return;
    }

    std::string host = url_str.substr(0, colon_pos);
    int port = std::stoi(url_str.substr(colon_pos + 1));

    // Register Texture
    texture_ = std::make_unique<flutter::TextureVariant>(
        flutter::PixelBufferTexture([this](size_t width, size_t height) -> const FlutterDesktopPixelBuffer* {
            std::lock_guard<std::mutex> lock(pixel_buffer_mutex_);
            if (pixel_buffer_.empty() || this->width_ == 0 || this->height_ == 0) {
                return nullptr;
            }
            
            static FlutterDesktopPixelBuffer flutter_pixel_buffer;
            flutter_pixel_buffer.buffer = pixel_buffer_.data();
            flutter_pixel_buffer.width = this->width_;
            flutter_pixel_buffer.height = this->height_;
            return &flutter_pixel_buffer;
        }));

    texture_id_ = texture_registrar_->RegisterTexture(texture_.get());
    
    // Start Thread
    is_decoding_ = true;
    decoder_thread_ = std::thread(&VideoDecoderPlugin::DecodingLoop, this, host, port);

    result->Success(flutter::EncodableValue(texture_id_));
}

void VideoDecoderPlugin::StopDecoding() {
    is_decoding_ = false;
    if (socket_ != INVALID_SOCKET) {
        closesocket(socket_);
        socket_ = INVALID_SOCKET;
    }
    if (decoder_thread_.joinable()) {
        decoder_thread_.join();
    }
    if (texture_id_ != -1) {
        texture_registrar_->UnregisterTexture(texture_id_);
        texture_id_ = -1;
    }
    CleanupDecoder();
}

bool VideoDecoderPlugin::ConnectToServer(const std::string& host, int port) {
    socket_ = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (socket_ == INVALID_SOCKET) return false;

    sockaddr_in clientService;
    clientService.sin_family = AF_INET;
    clientService.sin_addr.s_addr = inet_addr(host.c_str());
    clientService.sin_port = htons(port);

    if (connect(socket_, (SOCKADDR*)&clientService, sizeof(clientService)) == SOCKET_ERROR) {
        closesocket(socket_);
        socket_ = INVALID_SOCKET;
        return false;
    }
    return true;
}

bool VideoDecoderPlugin::InitializeDecoder() {
    codec_ = avcodec_find_decoder(AV_CODEC_ID_HEVC); // Assuming H.265/HEVC per macOS impl
    if (!codec_) return false;

    codec_context_ = avcodec_alloc_context3(codec_);
    if (!codec_context_) return false;

    codec_context_->flags |= AV_CODEC_FLAG_LOW_DELAY;
    codec_context_->flags2 |= AV_CODEC_FLAG2_FAST;
    codec_context_->thread_count = 1;

    if (avcodec_open2(codec_context_, codec_, NULL) < 0) return false;

    packet_ = av_packet_alloc();
    frame_ = av_frame_alloc();
    return true;
}

void VideoDecoderPlugin::CleanupDecoder() {
    if (sws_context_) { sws_freeContext(sws_context_); sws_context_ = nullptr; }
    if (frame_) av_frame_free(&frame_);
    if (packet_) av_packet_free(&packet_);
    if (codec_context_) avcodec_free_context(&codec_context_);
}

void VideoDecoderPlugin::DecodingLoop(const std::string& host, int port) {
    if (!ConnectToServer(host, port)) {
        is_decoding_ = false;
        return;
    }

    if (!InitializeDecoder()) {
        is_decoding_ = false;
        return;
    }

    // Decoding Loop
    std::vector<uint8_t> buffer;
    buffer.reserve(1024 * 1024);
    
    char temp_buf[4096];
    bool reading_header = true;
    int needed_bytes = 12; // Scrcpy packet header
    int payload_size = 0;
    bool is_config_packet = false;
    
    std::vector<uint8_t> config_data;

    while (is_decoding_) {
        int bytes_read = recv(socket_, temp_buf, sizeof(temp_buf), 0);
        if (bytes_read <= 0) break;

        buffer.insert(buffer.end(), temp_buf, temp_buf + bytes_read);

        while (buffer.size() >= needed_bytes) {
            if (reading_header) {
                // Parse Header
                uint64_t pts = 0;
                memcpy(&pts, buffer.data(), 8);
                // ntohll needed? buffer is big endian from scrcpy usually?
                // macOS impl used be64toh.
                uint32_t size = 0;
                memcpy(&size, buffer.data() + 8, 4);
                // ntohl needed?

                // Manual endian swap if needed. Assuming network order (BE).
                // size = ntohl(size); 
                // Let's implement ntohl:
                uint8_t* p = (uint8_t*)&size;
                uint32_t size_be = (p[0] << 24) | (p[1] << 16) | (p[2] << 8) | p[3];
                size = size_be;

                is_config_packet = (pts & 0x8000000000000000) != 0; // Check MSB for config
                payload_size = size;

                buffer.erase(buffer.begin(), buffer.begin() + 12);
                needed_bytes = payload_size;
                reading_header = false;

            } else {
                // Read Payload
                std::vector<uint8_t> payload(buffer.begin(), buffer.begin() + payload_size);
                buffer.erase(buffer.begin(), buffer.begin() + payload_size);

                if (is_config_packet) {
                    config_data = payload;
                } else {
                    if (!config_data.empty()) {
                        std::vector<uint8_t> merged;
                        merged.insert(merged.end(), config_data.begin(), config_data.end());
                        merged.insert(merged.end(), payload.begin(), payload.end());
                        DecodePacket(merged);
                        config_data.clear();
                    } else {
                        DecodePacket(payload);
                    }
                }

                needed_bytes = 12;
                reading_header = true;
            }
        }
    }
}

void VideoDecoderPlugin::DecodePacket(const std::vector<uint8_t>& data) {
    if (!codec_context_) return;

    packet_->data = (uint8_t*)data.data();
    packet_->size = (int)data.size();

    if (avcodec_send_packet(codec_context_, packet_) < 0) return;

    while (avcodec_receive_frame(codec_context_, frame_) >= 0) {
        ProcessFrame(frame_);
    }
    av_packet_unref(packet_);
}

void VideoDecoderPlugin::ProcessFrame(AVFrame* frame) {
    std::lock_guard<std::mutex> lock(pixel_buffer_mutex_);

    // Init SWS Context
    if (!sws_context_ || width_ != frame->width || height_ != frame->height) {
        width_ = frame->width;
        height_ = frame->height;
        if (sws_context_) sws_freeContext(sws_context_);

        sws_context_ = sws_getContext(
            width_, height_, (AVPixelFormat)frame->format,
            width_, height_, AV_PIX_FMT_BGRA, // Flutter expects BGRA
            SWS_FAST_BILINEAR, NULL, NULL, NULL
        );
        
        // Resize buffer (Width * Height * 4 bytes)
        pixel_buffer_.resize(width_ * height_ * 4);
    }

    uint8_t* dest[4] = { pixel_buffer_.data(), NULL, NULL, NULL };
    int dest_linesize[4] = { width_ * 4, 0, 0, 0 };

    sws_scale(sws_context_, frame->data, frame->linesize, 0, height_, dest, dest_linesize);

    // Notify Flutter
    texture_registrar_->MarkTextureFrameAvailable(texture_id_);
}
