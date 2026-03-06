import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:scraki/core/mixins/di_mixin.dart';
import 'package:scraki/features/dashboard/presentation/stores/dashboard_store.dart';
import 'package:scraki/features/video_poster/data/services/batch_video_service.dart';
import 'package:scraki/features/video_poster/domain/entities/custom_text_overlay.dart';
import 'package:uuid/uuid.dart';

part 'video_poster_store.g.dart';

/// Dashboard tab index for Video Poster
const int _kVideoEditorTabIndex = 2;

@injectable
// ignore: library_private_types_in_public_api
class VideoPosterStore = _VideoPosterStore with _$VideoPosterStore;

abstract class _VideoPosterStore with Store {
  final DashboardStore _dashboardStore = inject<DashboardStore>();

  // Initialization flag to prevent re-initialization on hot restart
  bool _isInitialized = false;

  _VideoPosterStore() {
    if (!_isInitialized) {
      initializePlayer();
      _isInitialized = true;
    }
  }

  // ─── Source Video State ───────────────────────────────────────────────────

  @observable
  ObservableList<String> sourceVideoPaths = ObservableList<String>();

  @observable
  int currentVideoIndex = 0;

  // ─── Custom Text Overlays ─────────────────────────────────────────────────

  @observable
  ObservableList<CustomTextOverlay> customTexts =
      ObservableList<CustomTextOverlay>();

  @observable
  String? selectedCustomTextId;

  @action
  void addCustomText() {
    final id = const Uuid().v4();
    customTexts.add(
      CustomTextOverlay(
        id: id,
        label: 'Text',
        // Place new text in the center of the 720x1280 canvas
        x: 0.5,
        y: 0.5,
      ),
    );
    // Auto-select the newly created text
    selectedCustomTextId = id;
  }

  @action
  void removeCustomText(String id) {
    customTexts.removeWhere((t) => t.id == id);
    if (selectedCustomTextId == id) {
      selectedCustomTextId = null;
    }
  }

  @action
  void selectCustomText(String? id) {
    selectedCustomTextId = id;
  }

  @action
  void updateCustomTextPosition(String id, double x, double y) {
    final index = customTexts.indexWhere((t) => t.id == id);
    if (index == -1) return;
    customTexts[index] = customTexts[index].copyWith(x: x, y: y);
  }

  @action
  void updateCustomTextFontSize(String id, double size) {
    final index = customTexts.indexWhere((t) => t.id == id);
    if (index == -1) return;
    customTexts[index] = customTexts[index].copyWith(
      fontSize: size.clamp(8.0, 200.0),
    );
  }

  @action
  void updateCustomTextLabel(String id, String value) {
    final index = customTexts.indexWhere((t) => t.id == id);
    if (index == -1) return;
    customTexts[index] = customTexts[index].copyWith(label: value);
  }

  @action
  void updateCustomTextStyle(
    String id, {
    Color? color,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    TextAlign? textAlign,
    Color? backgroundColor,
    bool clearBackgroundColor = false,
    double? backgroundOpacity,
    double? backgroundRadius,
    double? textHeight,
    bool clearTextHeight = false,
    String? fontFamily,
  }) {
    final index = customTexts.indexWhere((t) => t.id == id);
    if (index == -1) return;
    customTexts[index] = customTexts[index].copyWith(
      color: color,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      textAlign: textAlign,
      backgroundColor: backgroundColor,
      clearBackgroundColor: clearBackgroundColor,
      backgroundOpacity: backgroundOpacity,
      backgroundRadius: backgroundRadius,
      textHeight: textHeight,
      clearTextHeight: clearTextHeight,
      fontFamily: fontFamily,
    );
  }

  // ─── Batch Video Creation ────────────────────────────────────────────────────────

  @observable
  int batchOutputCount = 10;

  @observable
  bool isBatchCreating = false;

  @observable
  ObservableList<String> batchLogs = ObservableList<String>();

  @observable
  String? batchOutputDir;

  BatchVideoService? _batchService;
  StreamSubscription<String>? _batchSub;

  @action
  void setBatchOutputCount(int count) {
    batchOutputCount = count.clamp(1, 999);
  }

  @action
  Future<void> createBatchVideos() async {
    if (sourceVideoPaths.isEmpty || isBatchCreating) return;

    _batchService = BatchVideoService();

    // 1. Capture text overlay BEFORE setting isBatchCreating=true
    // Because isBatchCreating=true will hide the RepaintBoundary from the screen
    Uint8List? overlayBytes;
    if (customTexts.isNotEmpty) {
      try {
        overlayBytes = await capturePreviewAsPng();
      } catch (e) {
        batchLogs.add('❌ Lỗi capture text: $e');
        return;
      }
    }

    // 2. Now it's safe to switch UI to full-screen batch mode
    isBatchCreating = true;
    batchLogs.clear();
    _progressLineIndices.clear();
    batchOutputDir = null;

    if (customTexts.isNotEmpty) {
      batchLogs.add('🖼️ Đã chụp Text Overlay thành công.');
    }

    final config = BatchVideoConfig(
      outputCount: batchOutputCount,
      overlayBytes: overlayBytes,
    );

    final stream = _batchService!.createBatchVideos(
      sourceVideoPaths: List<String>.from(sourceVideoPaths),
      config: config,
      onOutputDir: (dir) => runInAction(() => batchOutputDir = dir),
      onLog: (line) => runInAction(() => _handleLogUpdate(line)),
    );

    _batchSub = stream.listen(
      (line) => runInAction(() => _handleLogUpdate(line)),
      onDone: () => runInAction(() => isBatchCreating = false),
      onError: (Object e) => runInAction(() {
        batchLogs.add('❌ Lỗi: $e');
        isBatchCreating = false;
      }),
    );
  }

  final Map<String, int> _progressLineIndices = {};

  void _handleLogUpdate(String line) {
    if (line.startsWith('_PROGRESS_')) {
      final colonIndex = line.indexOf(':');
      if (colonIndex != -1) {
        final prefix = line.substring(0, colonIndex); // e.g., "_PROGRESS_V1"
        final text = line.substring(colonIndex + 1).trimLeft();

        if (_progressLineIndices.containsKey(prefix) &&
            _progressLineIndices[prefix]! < batchLogs.length) {
          batchLogs[_progressLineIndices[prefix]!] = text;
        } else {
          batchLogs.add(text);
          _progressLineIndices[prefix] = batchLogs.length - 1;
        }
        return;
      }
    }

    if (line.startsWith('_UPDATE_')) {
      final spaceIndex = line.indexOf(' ');
      if (spaceIndex != -1) {
        final prefix = line.substring(0, spaceIndex); // e.g., "_UPDATE_V1"
        final progressPrefix = prefix.replaceFirst('_UPDATE_', '_PROGRESS_');
        final text = line.substring(spaceIndex + 1).trimLeft();

        if (_progressLineIndices.containsKey(progressPrefix) &&
            _progressLineIndices[progressPrefix]! < batchLogs.length) {
          batchLogs[_progressLineIndices[progressPrefix]!] = text;
        } else {
          batchLogs.add(text);
        }
        return;
      } else {
        final text = line.replaceFirst('_UPDATE_', '').trimLeft();
        batchLogs.add(text);
        return;
      }
    }

    batchLogs.add(line);
  }

  @action
  void cancelBatchVideos() {
    _batchService?.cancel();
    _batchSub?.cancel();
    _batchSub = null;
    _batchService = null;
    isBatchCreating = false;
    batchLogs.add('🛑 Đã dừng.');
  }

  // ─── Effects State ─────────────────────────────────────────────────────────────

  @observable
  double playbackSpeed = 1.0;

  // ─── Player & Playback State ──────────────────────────────────────────────

  late final Player player;
  late final VideoController videoController;

  @observable
  Duration duration = Duration.zero;

  @observable
  Duration position = Duration.zero;

  @observable
  bool isPlaying = false;

  // Stream subscriptions (private)
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<double>? _rateSub;

  // ─── Navigation State ─────────────────────────────────────────────────────

  @observable
  int activeNavIndex = 0;

  // Preview capture key
  final previewKey = GlobalKey();

  // ─── Actions ──────────────────────────────────────────────────────────────

  @action
  void addSourceVideos(List<String> paths) {
    // Only add videos when on Video Editor tab to prevent conflicts with PhoneView
    if (paths.isEmpty ||
        _dashboardStore.selectedIndex != _kVideoEditorTabIndex) {
      return;
    }
    sourceVideoPaths.addAll(paths);
  }

  @action
  void removeSourceVideo(int index) {
    if (index < 0 || index >= sourceVideoPaths.length) return;

    sourceVideoPaths.removeAt(index);

    if (sourceVideoPaths.isEmpty) {
      player.stop();
      currentVideoIndex = 0;
      return;
    }

    // If removed the current or a previous video, adjust index
    if (index <= currentVideoIndex) {
      currentVideoIndex = (currentVideoIndex - 1).clamp(
        0,
        sourceVideoPaths.length - 1,
      );
      _playCurrentVideo();
    }
  }

  /// Initialize player, controller, and stream listeners
  @action
  void initializePlayer() {
    player = Player();
    videoController = VideoController(
      player,
      configuration: const VideoControllerConfiguration(
        enableHardwareAcceleration: true,
      ),
    );

    _durationSub = player.stream.duration.listen(
      (d) => runInAction(() => duration = d),
    );
    _positionSub = player.stream.position.listen(
      (p) => runInAction(() => position = p),
    );
    _playingSub = player.stream.playing.listen(
      (p) => runInAction(() => isPlaying = p),
    );
    _rateSub = player.stream.rate.listen(
      (r) => runInAction(() => playbackSpeed = r),
    );
  }

  /// Dispose player, controller, subscriptions, and any running batch job.
  @action
  void disposePlayer() {
    cancelBatchVideos();
    _durationSub?.cancel();
    _positionSub?.cancel();
    _playingSub?.cancel();
    _rateSub?.cancel();
    player.dispose();
  }

  /// Start a new project by clearing all inputs and outputs
  @action
  void resetProject() {
    sourceVideoPaths.clear();
    customTexts.clear();
    currentVideoIndex = 0;
    player.stop();

    // Clear batch output data
    batchLogs.clear();
    batchOutputDir = null;
  }

  @action
  void setActiveNavIndex(int index) {
    activeNavIndex = index;
  }

  /// Play a specific video by index
  @action
  void playVideoAtIndex(int index) {
    if (index < 0 || index >= sourceVideoPaths.length) return;
    currentVideoIndex = index;
    _playCurrentVideo();
  }

  void _playCurrentVideo() {
    if (sourceVideoPaths.isEmpty) return;
    player.open(Media(sourceVideoPaths[currentVideoIndex]));
    player.play();
  }

  /// Capture preview widget as PNG at 720x1280 resolution
  @action
  Future<Uint8List> capturePreviewAsPng() async {
    try {
      if (previewKey.currentContext == null) {
        debugPrint(
          'Warning: previewKey.currentContext is null. UI likely not rendered.',
        );
        throw 'Please add at least one text or video element before exporting.';
      }

      // Deselect all overlays to hide handles before capture
      final previousSelection = selectedCustomTextId;
      selectCustomText(null);

      await Future<void>.delayed(const Duration(milliseconds: 300));

      final renderObject = previewKey.currentContext?.findRenderObject();
      if (renderObject == null || renderObject is! RenderRepaintBoundary) {
        throw 'Preview render object not found.';
      }

      // Standardize export to 1080p — pixel ratio 1.5 on 720px = 1080px
      const pixelRatio = 1.5;

      final image = await renderObject.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      // Restore selection
      selectCustomText(previousSelection);

      if (byteData == null) throw 'Failed to encode overlay image.';

      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing preview: $e');
      rethrow;
    }
  }
}
