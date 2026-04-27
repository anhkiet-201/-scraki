
typedef ProbeResult = ({
  int duration, 
  bool hasAudio, 
  ({String transfer, String primaries, String pixFmt}) colorInfo
});

abstract class VideoMetadataAnalyzer {
  Future<ProbeResult> probeSourceVideo(String path);
  bool isHdr({required String transfer, required String pixFmt});
  void clearCache();
}
