
/// Interface for the video decoder service.
/// This service manages native video decoding sessions across platforms.
abstract class IVideoDecoderService {
  /// Initializes the service and starts listening to app lifecycle changes.
  void initialize();

  /// Starts a video decoding session for the given [url].
  /// Returns the texture ID if successful, null otherwise.
  Future<int?> start(String url, String sessionId);

  /// Stops the video decoding session for the given [url].
  Future<void> stop(String url);

  /// Sets the visibility of the video stream for the given [url].
  /// [visible] indicates if the stream is currently visible in the UI.
  Future<void> setVisibility(String url, bool visible);

  /// Flushes the decoder buffers for the given [url].
  Future<void> flush(String url);

  /// Disposes of the service and its resources.
  void dispose();
}
