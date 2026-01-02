#define _CRT_SECURE_NO_WARNINGS
#include "VideoDecoderPlugin.h"
#include <iostream>
#include <string>

#include <windows.h>
#include <sstream>
#include <chrono>
#include <iomanip>

#pragma comment(lib, "ws2_32.lib")

#include <cstdarg>
#include <condition_variable>
#include <queue>

static std::mutex g_ffmpeg_init_mutex;
std::atomic<int64_t> g_active_buffers{0};
std::atomic<int64_t> g_total_pixels_allocated{0};
std::atomic<int> g_active_sessions{0};

static void LogTrace(const char* format, ...) {
    va_list args;
    va_start(args, format);
    
    char message[2048];
    vsnprintf(message, sizeof(message), format, args);
    va_end(args);

    SYSTEMTIME st;
    GetLocalTime(&st);
    char full_log[2500];
    sprintf(full_log, "[%02d:%02d:%02d.%03d] [TID:%lu] [VideoDecoder] %s\n", 
            st.wHour, st.wMinute, st.wSecond, st.wMilliseconds, GetCurrentThreadId(), message);
    
    // Always to Debug Console (fast)
    OutputDebugStringA(full_log);
    
    // For investigation, we only log errors and lifecycle to file
    bool is_important = strstr(message, "Error") || strstr(message, "failed") || 
                        strstr(message, "CRITICAL") || strstr(message, "FATAL") ||
                        strstr(message, "Constructor") || strstr(message, "Destructor") ||
                        strstr(message, "Cleanup");

    if (is_important) {
        FILE* f = fopen("C:\\Users\\Public\\scraki_errors.log", "a");
        if (f) {
            fprintf(f, "%s", full_log);
            fclose(f);
        }
        fprintf(stderr, "%s", full_log);
        fflush(stderr);
    }
}

// Singleton to manage thread joining in a central worker thread
class GlobalThreadJoiner {
public:
    static GlobalThreadJoiner& GetInstance() {
        static GlobalThreadJoiner instance;
        return instance;
    }

    void AddThread(std::unique_ptr<std::thread> t) {
        if (!t) return;
        {
            std::lock_guard<std::mutex> lock(mutex_);
            threads_to_join_.push(std::move(t));
        }
        cv_.notify_one();
    }

private:
    GlobalThreadJoiner() : active_(true) {
        worker_thread_ = std::thread([this]() {
            while (active_ || !threads_to_join_.empty()) {
                std::unique_ptr<std::thread> t;
                {
                    std::unique_lock<std::mutex> lock(mutex_);
                    cv_.wait(lock, [this] { return !active_ || !threads_to_join_.empty(); });
                    
                    if (!threads_to_join_.empty()) {
                        t = std::move(threads_to_join_.front());
                        threads_to_join_.pop();
                    } else if (!active_) {
                        break;
                    }
                }
                
                if (t && t->joinable()) {
                    // Actual cleanup happens here on a background thread
                    t->join();
                }
            }
        });
    }

    ~GlobalThreadJoiner() {
        active_ = false;
        cv_.notify_all(); // Use notify_all for safety
        if (worker_thread_.joinable()) {
            worker_thread_.join();
        }
        // CRITICAL FIX: Join any remaining threads in the queue
        // In C++, destroying a joinable std::thread calls std::terminate()!
        while (!threads_to_join_.empty()) {
            auto t = std::move(threads_to_join_.front());
            threads_to_join_.pop();
            if (t && t->joinable()) {
                t->join();
            }
        }
    }

    std::queue<std::unique_ptr<std::thread>> threads_to_join_;
    std::mutex mutex_;
    std::condition_variable cv_;
    std::thread worker_thread_;
    std::atomic<bool> active_;
};

// Background thread manager to avoid blocking UI thread during join
// Now uses GlobalThreadJoiner to avoid spawning 100 extra management threads
static void SafeThreadJoin(std::unique_ptr<std::thread> t) {
    GlobalThreadJoiner::GetInstance().AddThread(std::move(t));
}

static void FFmpegLogCallback(void* ptr, int level, const char* fmt, va_list vl) {
    if (level > av_log_get_level()) return;
    char line[1024];
    vsnprintf(line, sizeof(line), fmt, vl);
    LogTrace("[FFmpeg] %s", line);
}

static int SwsScaleSafe(SwsContext* context, uint8_t* src_data[], int src_linesize[], int src_y, int src_h, uint8_t* dst_data[], int dst_linesize[]) {
    __try {
        return sws_scale(context, src_data, src_linesize, src_y, src_h, dst_data, dst_linesize);
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        return -1;
    }
}

static int AvCodecSendPacketSafe(AVCodecContext* ctx, AVPacket* pkt) {
    __try {
        return avcodec_send_packet(ctx, pkt);
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        return -1;
    }
}

static int AvCodecReceiveFrameSafe(AVCodecContext* ctx, AVFrame* frame) {
    __try {
        return avcodec_receive_frame(ctx, frame);
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        return -1;
    }
}



VideoDecoderPlugin::VideoDecoderPlugin(flutter::TextureRegistrar* texture_registrar)
    : texture_registrar_(texture_registrar) {
  LogTrace("Plugin Constructor - Initializing Winsock");
  WSADATA wsaData;
  WSAStartup(MAKEWORD(2, 2), &wsaData);
  av_log_set_callback(FFmpegLogCallback);
  av_log_set_level(AV_LOG_ERROR);
}

VideoDecoderPlugin::~VideoDecoderPlugin() {
  StopAllDecoding();
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
    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (arguments) {
        auto tid_it = arguments->find(flutter::EncodableValue("textureId"));
        if (tid_it != arguments->end()) {
            int64_t texture_id = tid_it->second.LongValue();
            StopDecoding(texture_id);
            result->Success();
            return;
        }
    }
    result->Success();
  } else {
    result->NotImplemented();
  }
}

void VideoDecoderPlugin::StartDecoding(const std::string& url,
                                       std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    try {
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

        auto session = std::make_unique<VideoSession>(texture_registrar_, host, port);
        int64_t texture_id = session->texture_id();
        
        if (texture_id == -1) {
            result->Error("TEXTURE_ERROR", "Failed to register texture");
            return;
        }

        {
            std::lock_guard<std::mutex> lock(sessions_mutex_);
            sessions_[texture_id] = std::move(session);
        }

        result->Success(flutter::EncodableValue(texture_id));
    } catch (const std::exception& e) {
        result->Error("START_ERROR", e.what());
    }
}

void VideoDecoderPlugin::StopDecoding(int64_t texture_id) {
    std::lock_guard<std::mutex> lock(sessions_mutex_);
    auto it = sessions_.find(texture_id);
    if (it != sessions_.end()) {
        sessions_.erase(it);
    }
}

void VideoDecoderPlugin::StopAllDecoding() {
    std::lock_guard<std::mutex> lock(sessions_mutex_);
    sessions_.clear();
}

// VideoSessionState Implementation
VideoDecoderPlugin::VideoSessionState::~VideoSessionState() {
    LogTrace("VideoSessionState Destructor [%lld] - START", texture_id);
    
    // The actual cleanup happens here, only when shared_ptr count reaches 0!
    // This is safe because both UI and Decoder threads have finished.
    if (socket != INVALID_SOCKET) {
        shutdown(socket, SD_BOTH);
        closesocket(socket);
        socket = INVALID_SOCKET;
    }

    if (sws_context) { sws_freeContext(sws_context); sws_context = nullptr; }
    if (frame) av_frame_free(&frame);
    if (packet) av_packet_free(&packet);
    if (codec_context) avcodec_free_context(&codec_context);
    
    front_buffer.reset();
    last_front_buffer.reset();
    buffer_pool.clear();
    
    LogTrace("VideoSessionState Destructor [%lld] - END", texture_id);
}

// VideoSession Implementation
VideoDecoderPlugin::VideoSession::VideoSession(flutter::TextureRegistrar* texture_registrar, const std::string& host, int port) {
    int current_sessions = ++g_active_sessions;
    LogTrace("VideoSession Constructor [%d active] - Host: %s Port: %d", current_sessions, host.c_str(), port);
    state_ = std::make_shared<VideoSessionState>(texture_registrar);

    auto weak_state = std::weak_ptr<VideoSessionState>(state_);

    state_->texture = std::make_unique<flutter::TextureVariant>(
        flutter::PixelBufferTexture([weak_state](size_t width, size_t height) -> const FlutterDesktopPixelBuffer* {
            try {
                auto s = weak_state.lock();
                if (!s || !s->is_alive) return nullptr;

                std::lock_guard<std::recursive_mutex> lock(s->pixel_buffer_mutex);
                if (!s->front_buffer) return nullptr;
                
                s->flutter_pixel_buffer.buffer = s->front_buffer->pixels.data();
                s->flutter_pixel_buffer.width = s->front_buffer->width;
                s->flutter_pixel_buffer.height = s->front_buffer->height;
                return &s->flutter_pixel_buffer;
            } catch (...) {
                return nullptr;
            }
        }));

    state_->texture_id = texture_registrar->RegisterTexture(state_->texture.get());
    LogTrace("Texture Registered, ID: %lld", state_->texture_id);
    
    if (state_->texture_id != -1) {
        state_->is_decoding = true;
        try {
            LogTrace("Launching Decoder Thread for ID: %lld...", state_->texture_id);
            decoder_thread_ = std::make_unique<std::thread>([s = state_, h = host, p = port]() {
                unsigned long tid = GetCurrentThreadId();
                {
                    char buf[256];
                    sprintf(buf, "[DEBUG] TID:%lu Thread LAMBDA START for ID:%lld\n", tid, s->texture_id);
                    OutputDebugStringA(buf);
                }
                
                LogTrace("TID %lu - Entering DecodingLoop for ID: %lld", tid, s->texture_id);
                VideoSession::DecodingLoop(s, h, p);
                LogTrace("TID %lu - Exited DecodingLoop for ID: %lld", tid, s->texture_id);
            });
            LogTrace("Decoder Thread Managed for ID: %lld. Sessions: %d", state_->texture_id, g_active_sessions.load());
        } catch (const std::exception& e) {
            LogTrace("CRITICAL: Failed to launch decoder thread: %s", e.what());
            state_->is_decoding = false;
        }
    }
}

VideoDecoderPlugin::VideoSession::~VideoSession() {
    int current = --g_active_sessions;
    int64_t tid = state_ ? state_->texture_id : -1;
    LogTrace("VideoSession Destructor [%lld] - START. Sessions left: %d", tid, current);
    
    if (state_) {
        // 1. Signal immediate stop to threads
        state_->is_decoding = false;
        state_->is_alive = false;
        
        // 2. Break any blocking recv() immediately
        if (state_->socket != INVALID_SOCKET) {
            LogTrace("VideoSession Destructor [%lld] - Forcing socket shutdown", tid);
            shutdown(state_->socket, SD_BOTH);
            closesocket(state_->socket);
            state_->socket = INVALID_SOCKET;
        }

        // 3. Mark texture as gone so engine callbacks return null
        {
            std::lock_guard<std::recursive_mutex> lock(state_->pixel_buffer_mutex);
            state_->texture_id = -1;
        }

        // 4. Unregister from engine
        if (tid != -1) {
            state_->texture_registrar->UnregisterTexture(tid);
        }
    }

    // 5. Thread will exit DecodingLoop and destroy its shared_ptr<VideoSessionState>
    // only then will the actual FFmpeg resources be freed in ~VideoSessionState.
    if (decoder_thread_) {
        SafeThreadJoin(std::move(decoder_thread_));
    }
    LogTrace("VideoSession Destructor [%lld] - END", tid);
}

bool VideoDecoderPlugin::VideoSession::ConnectToServer(std::shared_ptr<VideoSessionState> state, const std::string& host, int port) {
    LogTrace("Connecting to server: %s:%d", host.c_str(), port);
    state->socket = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (state->socket == INVALID_SOCKET) {
        int err = WSAGetLastError();
        LogTrace("ConnectToServer - Socket creation failed. Error: %d", err);
        return false;
    }

    // Optimization for 100 devices: Increase socket receive buffer to 1MB
    int rcvbuf = 1024 * 1024;
    setsockopt(state->socket, SOL_SOCKET, SO_RCVBUF, (const char*)&rcvbuf, sizeof(rcvbuf));
    
    // Disable Nagle's algorithm for lower latency if needed
    BOOL nodelay = TRUE;
    setsockopt(state->socket, IPPROTO_TCP, TCP_NODELAY, (const char*)&nodelay, sizeof(nodelay));

    sockaddr_in clientService;
    clientService.sin_family = AF_INET;
    clientService.sin_addr.s_addr = inet_addr(host.c_str());
    clientService.sin_port = htons(port);

    if (connect(state->socket, (SOCKADDR*)&clientService, sizeof(clientService)) == SOCKET_ERROR) {
        int err = WSAGetLastError();
        LogTrace("ConnectToServer - Connection to %s:%d failed. Error: %d", host.c_str(), port, err);
        closesocket(state->socket);
        state->socket = INVALID_SOCKET;
        return false;
    }
    LogTrace("ConnectToServer - Connected to %s:%d successfully", host.c_str(), port);
    return true;
}

bool VideoDecoderPlugin::VideoSession::InitializeDecoder(std::shared_ptr<VideoSessionState> state) {
    LogTrace("InitializeDecoder Start");
    state->codec = avcodec_find_decoder(AV_CODEC_ID_HEVC);
    if (!state->codec) {
        LogTrace("HEVC decoder not found");
        return false;
    }

    state->codec_context = avcodec_alloc_context3(state->codec);
    if (!state->codec_context) {
        LogTrace("Codec context alloc failed");
        return false;
    }

    state->codec_context->flags |= AV_CODEC_FLAG_LOW_DELAY;
    state->codec_context->flags2 |= AV_CODEC_FLAG2_FAST;
    state->codec_context->thread_count = 1;

    // For mass concurrency, we still need protection for the sensitive avcodec_open2
    {
        std::lock_guard<std::mutex> lock(g_ffmpeg_init_mutex);
        if (avcodec_open2(state->codec_context, state->codec, NULL) < 0) {
            LogTrace("InitializeDecoder [%lld] - Codec open failed", state->texture_id);
            return false;
        }
    }

    state->packet = av_packet_alloc();
    state->frame = av_frame_alloc();
    if (!state->packet || !state->frame) {
        LogTrace("InitializeDecoder [%lld] - Packet/Frame alloc failed", state->texture_id);
        return false;
    }
    
    LogTrace("FFmpeg initialized successfully");
    return true;
}

void VideoDecoderPlugin::VideoSession::DecodingLoop(std::shared_ptr<VideoSessionState> state, std::string host, int port) {
    LogTrace("DecodingLoop [%lld] - Starting Connection Steps", state->texture_id);
    try {
        if (!ConnectToServer(state, host, port)) {
            LogTrace("DecodingLoop [%lld] - Connection failed", state->texture_id);
            state->is_decoding = false;
            return;
        }
        
        if (!InitializeDecoder(state)) {
            LogTrace("DecodingLoop [%lld] - Decoder init failed", state->texture_id);
            state->is_decoding = false;
            return;
        }

        LogTrace("DecodingLoop [%lld] - Entering receive loop", state->texture_id);

        std::vector<uint8_t> buffer;
        buffer.reserve(1024 * 1024);
        char temp_buf[8192];
        bool reading_header = true;
        int needed_bytes = 12;
        int payload_size = 0;
        bool is_config_packet = false;
        std::vector<uint8_t> config_data;

        while (state->is_decoding) {
            int bytes_read = recv(state->socket, temp_buf, sizeof(temp_buf), 0);
            if (bytes_read <= 0) {
                LogTrace("Socket recv <= 0, breaking loop. Error: %d", WSAGetLastError());
                break;
            }

            buffer.insert(buffer.end(), temp_buf, temp_buf + bytes_read);

            // CPU/Network Congestion Protection: Limit buffer size per session
            if (buffer.size() > 5 * 1024 * 1024) { // 5MB limit
                LogTrace("DecodingLoop [%lld] - BUFFER OVERFLOW (%zu bytes). Clearing to prevent OOM.", 
                         state->texture_id, buffer.size());
                buffer.clear();
                needed_bytes = 12;
                reading_header = true;
                continue;
            }

            while (buffer.size() >= (size_t)needed_bytes) {
                if (reading_header) {
                    // (PTS and payload size logic...)
                    uint64_t pts_raw = 0;
                    memcpy(&pts_raw, buffer.data(), 8);
                    uint8_t* p64 = (uint8_t*)&pts_raw;
                    uint64_t pts = ((uint64_t)p64[0] << 56) | ((uint64_t)p64[1] << 48) |
                                   ((uint64_t)p64[2] << 40) | ((uint64_t)p64[3] << 32) |
                                   ((uint64_t)p64[4] << 24) | ((uint64_t)p64[5] << 16) |
                                   ((uint64_t)p64[6] << 8)  |  (uint64_t)p64[7];

                    uint32_t size_raw = 0;
                    memcpy(&size_raw, buffer.data() + 8, 4);
                    uint8_t* p32 = (uint8_t*)&size_raw;
                    payload_size = (p32[0] << 24) | (p32[1] << 16) | (p32[2] << 8) | p32[3];

                    if (payload_size < 0 || payload_size > 20 * 1024 * 1024) {
                        LogTrace("Invalid payload size: %d", payload_size);
                        state->is_decoding = false;
                        break;
                    }

                    is_config_packet = (pts & 0x8000000000000000) != 0;
                    buffer.erase(buffer.begin(), buffer.begin() + 12);
                    needed_bytes = (payload_size > 0) ? payload_size : 12;
                    reading_header = (payload_size > 0) ? false : true;
                } else {
                    if (payload_size > 0) {
                        std::vector<uint8_t> payload(buffer.begin(), buffer.begin() + payload_size);
                        buffer.erase(buffer.begin(), buffer.begin() + payload_size);

                        if (is_config_packet) {
                            config_data = payload;
                        } else {
                            if (!config_data.empty()) {
                                std::vector<uint8_t> merged;
                                merged.reserve(config_data.size() + payload.size());
                                merged.insert(merged.end(), config_data.begin(), config_data.end());
                                merged.insert(merged.end(), payload.begin(), payload.end());
                                DecodePacket(state, merged);
                                config_data.clear();
                            } else {
                                DecodePacket(state, payload);
                            }
                        }
                    }
                    needed_bytes = 12;
                    reading_header = true;
                }
            }
        }
    } catch (const std::exception& e) {
        LogTrace("DecodingLoop [%lld] - Standard exception: %s", state->texture_id, e.what());
    } catch (...) {
        LogTrace("DecodingLoop [%lld] - Unknown exception", state->texture_id);
    }
    LogTrace("DecodingLoop [%lld] - Loop exited, cleaning up", state->texture_id);
    state->is_decoding = false;
}

void VideoDecoderPlugin::VideoSession::DecodePacket(std::shared_ptr<VideoSessionState> state, const std::vector<uint8_t>& data) {
    if (!state || !state->is_decoding || !state->is_alive || !state->codec_context) return;
    if (!state->packet || !state->frame) return; // EXTRA SAFETY

    state->packet->data = (uint8_t*)data.data();
    state->packet->size = (int)data.size();

    int ret = AvCodecSendPacketSafe(state->codec_context, state->packet);
    if (ret < 0) {
        if (ret == -1) LogTrace("CRITICAL [%lld] - Access Violation in avcodec_send_packet!", state->texture_id);
        else if (ret != AVERROR(EAGAIN)) {
            LogTrace("DecodePacket [%lld] - send_packet error: %d", state->texture_id, ret);
        }
        return;
    }

    while (state->is_decoding) {
        ret = AvCodecReceiveFrameSafe(state->codec_context, state->frame);
        if (ret == AVERROR(EAGAIN) || ret == AVERROR_EOF) break;
        if (ret < 0) {
            if (ret == -1) LogTrace("CRITICAL [%lld] - Access Violation in avcodec_receive_frame!", state->texture_id);
            else LogTrace("DecodePacket [%lld] - receive_frame error: %d", state->texture_id, ret);
            break;
        }
        ProcessFrame(state, state->frame);
    }
    av_packet_unref(state->packet);
}

void VideoDecoderPlugin::VideoSession::ProcessFrame(std::shared_ptr<VideoSessionState> state, AVFrame* frame) {
    if (!state || !frame) return;

    // 1. Get a buffer from pool or create new one
    std::shared_ptr<VideoSessionState::RGBAFrame> back_buffer;
    {
        std::lock_guard<std::recursive_mutex> lock(state->pixel_buffer_mutex);
        if (!state->is_decoding || !state->is_alive || state->texture_id == -1) return;

        if (state->width != frame->width || state->height != frame->height) {
            LogTrace("ProcessFrame [%lld] - Resolution change: %dx%d -> %dx%d", 
                     state->texture_id, state->width, state->height, frame->width, frame->height);
            state->buffer_pool.clear();
            state->width = frame->width;
            state->height = frame->height;
        }

        for (auto it = state->buffer_pool.begin(); it != state->buffer_pool.end(); ++it) {
            if ((*it).use_count() == 1) {
                back_buffer = *it;
                state->buffer_pool.erase(it);
                break;
            }
        }
    }

    if (!back_buffer) {
        back_buffer = std::make_shared<VideoSessionState::RGBAFrame>(frame->width, frame->height);
    }

    // 2. Scale frame (No lock needed for pixel data - back_buffer is private here)
    {
        // Internal FFmpeg context needs brief protection during check/init
        std::lock_guard<std::recursive_mutex> lock(state->pixel_buffer_mutex);
        if (!state->is_alive) return;

        if (!state->sws_context || state->width != frame->width || state->height != frame->height) {
            if (state->sws_context) sws_freeContext(state->sws_context);
            std::lock_guard<std::mutex> ffmpeg_lock(g_ffmpeg_init_mutex);
            state->sws_context = sws_getContext(
                frame->width, frame->height, (AVPixelFormat)frame->format,
                frame->width, frame->height, AV_PIX_FMT_RGBA,
                SWS_FAST_BILINEAR, NULL, NULL, NULL
            );
        }
    }

    if (!state->sws_context) return;

    uint8_t* dest[4] = { back_buffer->pixels.data(), NULL, NULL, NULL };
    int dest_linesize[4] = { back_buffer->width * 4, 0, 0, 0 };
    
    if (!frame->data[0] || !dest[0]) return;

    // sws_scale runs UNLOCKED - this is where parallelism happens
    int scaled_h = SwsScaleSafe(state->sws_context, frame->data, frame->linesize, 0, frame->height, dest, dest_linesize);
    if (scaled_h <= 0) return;

    // 3. Swap to front and put old front back to pool
    {
        std::lock_guard<std::recursive_mutex> lock(state->pixel_buffer_mutex);
        if (!state->is_alive || state->texture_id == -1) return;
        
        if (state->last_front_buffer) {
            state->buffer_pool.push_back(state->last_front_buffer);
        }
        state->last_front_buffer = state->front_buffer;
        state->front_buffer = back_buffer;
        
        if (state->buffer_pool.size() > 5) { 
            state->buffer_pool.erase(state->buffer_pool.begin());
        }

        state->texture_registrar->MarkTextureFrameAvailable(state->texture_id);
    }
}

void VideoDecoderPlugin::RegisterWithRegistrar(FlutterDesktopPluginRegistrarRef registrar_ref) {
    LogTrace("RegisterWithRegistrar Start");
    auto* registrar = flutter::PluginRegistrarManager::GetInstance()
                        ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar_ref);

    auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
        registrar->messenger(), "scraki/video_decoder",
        &flutter::StandardMethodCodec::GetInstance());

    auto plugin = std::make_unique<VideoDecoderPlugin>(registrar->texture_registrar());

    channel->SetMethodCallHandler(
        [plugin_pointer = plugin.get()](const auto& call, auto result) {
            plugin_pointer->HandleMethodCall(call, std::move(result));
        });

    registrar->AddPlugin(std::move(plugin));
    LogTrace("RegisterWithRegistrar End");
}

VideoDecoderPlugin::VideoSessionState::RGBAFrame::RGBAFrame(int w, int h) : width(w), height(h) {
    size_t size = static_cast<size_t>(w) * h * 4;
    pixels.assign(size, 0);
    g_active_buffers++;
    g_total_pixels_allocated += (static_cast<int64_t>(w) * h);
}

VideoDecoderPlugin::VideoSessionState::RGBAFrame::~RGBAFrame() {
    g_active_buffers--;
    g_total_pixels_allocated -= (static_cast<int64_t>(width) * height);
}
