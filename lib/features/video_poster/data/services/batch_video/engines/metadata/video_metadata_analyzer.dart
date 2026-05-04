/// A record containing essential metadata for a video source.
typedef ProbeResult = ({
  /// Duration in seconds.
  int duration, 
  /// Whether the file contains an audio stream.
  bool hasAudio, 
  /// Color space and pixel format details.
  ({String transfer, String primaries, String pixFmt}) colorInfo
});

/// Interface for analyzing video file metadata using ffprobe.
abstract class VideoMetadataAnalyzer {
  /// Probes a video file and returns duration, audio presence, and color info.
  Future<ProbeResult> probeSourceVideo(String path);
  
  /// Determines if a video uses High Dynamic Range (HDR) based on its metadata.
  bool isHdr({required String transfer, required String pixFmt});
  
  /// Clears any cached probe results.
  void clearCache();
}
