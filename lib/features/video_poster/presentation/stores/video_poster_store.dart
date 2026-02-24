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
import 'package:scraki/features/video_poster/domain/entities/custom_text_overlay.dart';
import 'package:scraki/features/video_poster/domain/entities/video_composition.dart';
import 'package:scraki/features/video_poster/domain/repositories/video_processing_repository.dart';
import 'package:scraki/features/video_poster/domain/services/anti_reup_service.dart';
import 'package:scraki/features/video_poster/domain/entities/anti_reup_config.dart';
import 'package:uuid/uuid.dart';

part 'video_poster_store.g.dart';

/// Dashboard tab index for Video Poster
const int _kVideoEditorTabIndex = 2;

@injectable
// ignore: library_private_types_in_public_api
class VideoPosterStore = _VideoPosterStore with _$VideoPosterStore;

abstract class _VideoPosterStore with Store {
  final VideoProcessingRepository _repository;
  final AntiReupService _antiReupService;
  final DashboardStore _dashboardStore = inject<DashboardStore>();

  // Initialization flag to prevent re-initialization on hot restart
  bool _isInitialized = false;

  _VideoPosterStore(this._repository, this._antiReupService) {
    if (!_isInitialized) {
      initializePlayer();

      // Initialize with 'Maximize Stealth' (Random Config) by default
      // This ensures strict duration enforcement (15-25s) is active out-of-the-box.
      antiReupConfig = _antiReupService.maximizeStealth();

      _isInitialized = true;
    }
  }

  // ─── Source Video State ───────────────────────────────────────────────────

  @observable
  ObservableList<String> sourceVideoPaths = ObservableList<String>();

  @observable
  bool isProcessing = false;

  @observable
  String? generatedVideoPath;

  @observable
  String? errorMessage;

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
    );
  }

  // ─── Effects State ────────────────────────────────────────────────────────

  @observable
  double saturation = 1.2;
  @observable
  double contrast = 1.0;
  @observable
  double playbackSpeed = 1.0;
  @observable
  double zoomIntensity = 0.0;
  @observable
  double volume = 1.0;
  @observable
  bool applyBlur = false;
  @observable
  double blurIntensity = 5.0;

  // ─── Player & Playback State ──────────────────────────────────────────────

  late final Player player;
  late final VideoController videoController;

  @observable
  Duration duration = Duration.zero;

  @observable
  Duration position = Duration.zero;

  @observable
  ObservableList<Duration> clipDurations = ObservableList<Duration>();

  @observable
  int currentPlaylistIndex = 0;

  @observable
  bool isPlaying = false;

  @observable
  int videoWidth = 720;

  @observable
  int videoHeight = 1280;

  // Stream subscriptions (private)
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<double>? _rateSub;
  StreamSubscription<Playlist>? _playlistSub;
  StreamSubscription<int?>? _widthSub;
  StreamSubscription<int?>? _heightSub;

  // ─── Navigation State ─────────────────────────────────────────────────────

  @observable
  int activeNavIndex = 0;

  @observable
  bool isFocusMode = false;

  // ─── Anti-Reup State ──────────────────────────────────────────────────────

  @observable
  ObservableMap<String, String> thumbnails = ObservableMap<String, String>();

  // Preview capture key
  final previewKey = GlobalKey();

  @observable
  AntiReupConfig antiReupConfig = const AntiReupConfig();

  // ─── Actions ──────────────────────────────────────────────────────────────

  @action
  void addSourceVideos(List<String> paths) {
    // Only add videos when on Video Editor tab to prevent conflicts with PhoneView
    if (paths.isEmpty ||
        _dashboardStore.selectedIndex != _kVideoEditorTabIndex) {
      return;
    }
    final startIndex = sourceVideoPaths.length;

    sourceVideoPaths.addAll(paths);
    for (int i = 0; i < paths.length; i++) {
      clipDurations.add(Duration.zero);
    }

    _generateThumbnails(paths);
    _fetchDurations(paths, startIndex);
  }

  Future<void> _fetchDurations(List<String> paths, int startIndex) async {
    for (int i = 0; i < paths.length; i++) {
      final path = paths[i];
      final targetIndex = startIndex + i;

      try {
        final d = await _repository.getVideoDuration(path);
        if (targetIndex < clipDurations.length) {
          runInAction(() => clipDurations[targetIndex] = d);
        }
      } catch (e) {
        debugPrint("Error getting duration for $path: $e");
      }
    }
  }

  @action
  void removeSourceVideo(int index) {
    if (index >= 0 && index < sourceVideoPaths.length) {
      player.pause();

      sourceVideoPaths.removeAt(index);
      if (index < clipDurations.length) {
        clipDurations.removeAt(index);
      }

      if (sourceVideoPaths.isEmpty) {
        player.stop();
      } else {
        syncPlaylist();
      }
    }
  }

  @action
  void toggleBlur(bool value) {
    applyBlur = value;
  }

  @action
  void setPlaybackSpeed(double value) {
    playbackSpeed = value;
    player.setRate(value);
  }

  @action
  void setVolume(double value) {
    volume = value;
    player.setVolume(value * 100);
  }

  @action
  void setApplyBlur(bool value) {
    applyBlur = value;
  }

  @action
  void setBlurIntensity(double value) {
    blurIntensity = value;
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
    _playlistSub = player.stream.playlist.listen((p) {
      runInAction(() => currentPlaylistIndex = p.index);
    });
    _widthSub = player.stream.width.listen((w) {
      if (w != null && w > 0) runInAction(() => videoWidth = w);
    });
    _heightSub = player.stream.height.listen((h) {
      if (h != null && h > 0) runInAction(() => videoHeight = h);
    });

    syncPlaylist();
  }

  /// Dispose player, controller, and subscriptions
  @action
  void disposePlayer() {
    _durationSub?.cancel();
    _positionSub?.cancel();
    _playingSub?.cancel();
    _rateSub?.cancel();
    _playlistSub?.cancel();
    _widthSub?.cancel();
    _heightSub?.cancel();
    player.dispose();
  }

  @action
  void setActiveNavIndex(int index) {
    activeNavIndex = index;
    if (index != 2) {
      isFocusMode = false;
    }
  }

  @action
  void toggleFocusMode() {
    isFocusMode = !isFocusMode;
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

  @computed
  Duration get totalDuration {
    if (antiReupConfig.targetDuration != null) {
      return Duration(
        milliseconds: (antiReupConfig.targetDuration! * 1000).toInt(),
      );
    }

    if (clipDurations.isEmpty) return Duration.zero;
    return clipDurations.fold(Duration.zero, (prev, curr) => prev + curr);
  }

  @computed
  Duration get totalPosition {
    if (clipDurations.isEmpty) return Duration.zero;

    if (currentPlaylistIndex >= clipDurations.length) {
      return totalDuration;
    }

    Duration positionBefore = Duration.zero;
    for (int i = 0; i < currentPlaylistIndex; i++) {
      positionBefore += clipDurations[i];
    }
    return positionBefore + position;
  }

  Timer? _seekDebounceTimer;

  @action
  Future<void> seekTimeline(Duration target) async {
    if (clipDurations.isEmpty) return;

    Duration temp = Duration.zero;
    for (int i = 0; i < clipDurations.length; i++) {
      final clipEnd = temp + clipDurations[i];
      if (target < clipEnd || i == clipDurations.length - 1) {
        final seekPos = target - temp;

        if (i == currentPlaylistIndex) {
          _seekDebounceTimer?.cancel();
          await player.seek(seekPos);
        } else {
          if (_seekDebounceTimer?.isActive ?? false) {
            _seekDebounceTimer!.cancel();
          }

          _seekDebounceTimer = Timer(
            const Duration(milliseconds: 150),
            () async {
              await player.jump(i);
              await Future<void>.delayed(const Duration(milliseconds: 50));
              await player.seek(seekPos);
            },
          );
        }
        return;
      }
      temp = clipEnd;
    }
  }

  @action
  void updateEffect(String type, double value) {
    switch (type) {
      case 'saturation':
        saturation = value;
        break;
      case 'contrast':
        contrast = value;
        break;
      case 'speed':
        playbackSpeed = value;
        player.setRate(value);
        break;
      case 'zoom':
        zoomIntensity = value;
        break;
      case 'volume':
        volume = value;
        player.setVolume(value * 100);
        break;
      case 'blur_intensity':
        blurIntensity = value;
        break;
    }
  }

  @action
  void toggleRandomizeAntiReup(bool value) {
    if (value) {
      antiReupConfig = _antiReupService.maximizeStealth();
    } else {
      antiReupConfig = antiReupConfig.copyWith(
        isRandomized: false,
        targetDuration: null,
      );
    }
  }

  @action
  void updateAntiReupConfig(AntiReupConfig config) {
    antiReupConfig = config;
  }

  /// Handle video export
  @action
  Future<void> handleExportVideo() async {
    try {
      final overlayPng = await capturePreviewAsPng();
      await generateVideoWithOverlay(overlayPng);
    } catch (e) {
      debugPrint('Error during export: $e');
      runInAction(() {
        errorMessage = e.toString();
        isProcessing = false;
      });
    }
  }

  /// Sync playlist from source video paths
  @action
  void syncPlaylist() {
    if (sourceVideoPaths.isEmpty) return;

    int savedIndex = currentPlaylistIndex;
    if (savedIndex >= sourceVideoPaths.length) {
      savedIndex = 0;
    }

    final medias = sourceVideoPaths.map((p) => Media(p)).toList();
    player.open(Playlist(medias, index: savedIndex));
    player.pause();
  }

  @action
  void playVideoAtIndex(int index) {
    if (index >= 0 && index < sourceVideoPaths.length) {
      currentPlaylistIndex = index;
      player.jump(index);
      player.play();
    }
  }

  @action
  void playVideo(String path) {
    final index = sourceVideoPaths.indexOf(path);
    if (index != -1) {
      playVideoAtIndex(index);
    } else {
      player.open(Media(path));
      player.play();
    }
  }

  @action
  Future<void> generateVideoWithOverlay(Uint8List overlayPng) async {
    if (sourceVideoPaths.isEmpty) {
      errorMessage = 'Please add at least one video.';
      return;
    }

    isProcessing = true;
    errorMessage = null;

    try {
      final random = DateTime.now().millisecondsSinceEpoch % 1000;

      if (antiReupConfig.isRandomized) {
        antiReupConfig = _antiReupService.maximizeStealth().copyWith(
          targetDuration: antiReupConfig.targetDuration,
        );
      }
      final finalConfig = antiReupConfig;

      // Overlay is captured as PNG from the canvas — no poster data needed.
      final composition = VideoComposition(
        id: const Uuid().v4(),
        sourceVideoPaths: List<String>.from(sourceVideoPaths),
        contrast: contrast,
        saturation: saturation,
        playbackSpeed: playbackSpeed,
        zoomIntensity: zoomIntensity,
        antiReupConfig: finalConfig,
        randomSeed: random,
      );

      generatedVideoPath = await _repository.generateVideo(
        composition,
        overlayPng,
      );
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isProcessing = false;
    }
  }

  Future<void> _generateThumbnails(List<String> paths) async {
    for (final path in paths) {
      if (!thumbnails.containsKey(path)) {
        try {
          final thumb = await _repository.extractThumbnail(path);
          thumbnails[path] = thumb;
        } catch (e) {
          debugPrint('Failed to extract thumbnail: $e');
        }
      }
    }
  }
}
