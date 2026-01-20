import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:scraki/features/poster/domain/entities/poster_data.dart';
import 'package:scraki/features/video_poster/domain/entities/video_composition.dart';
import 'package:scraki/features/video_poster/domain/repositories/video_processing_repository.dart';
import 'package:uuid/uuid.dart';

part 'video_poster_store.g.dart';

@injectable
class VideoPosterStore = _VideoPosterStore with _$VideoPosterStore;

abstract class _VideoPosterStore with Store {
  final VideoProcessingRepository _repository;

  _VideoPosterStore(this._repository) {
    initializePlayer();
  }

  @observable
  ObservableList<String> sourceVideoPaths = ObservableList<String>();

  @observable
  PosterData? selectedPosterData;

  @observable
  bool isProcessing = false;

  @observable
  String? generatedVideoPath;

  @observable
  String? errorMessage;

  // --- Pro Editor State ---

  @observable
  double titleX = 0.5;
  @observable
  double titleY = 0.15;

  @observable
  double salaryX = 0.5;
  @observable
  double salaryY = 0.25;

  @observable
  double companyX = 0.5;
  @observable
  double companyY = 0.85;

  @observable
  double requirementsX = 0.1;
  @observable
  double requirementsY = 0.4;

  @observable
  double benefitsX = 0.1;
  @observable
  double benefitsY = 0.6;

  @observable
  double contactX = 0.5;
  @observable
  double contactY = 0.92;

  @observable
  double headlineX = 0.5;
  @observable
  double headlineY = 0.08;

  @observable
  double saturation = 1.2;
  @observable
  double contrast = 1.0;
  @observable
  double playbackSpeed = 1.0;
  @observable
  double zoomIntensity = 0.0;

  @observable
  bool enableAntiReup = true;

  // --- V4 UX State ---
  @observable
  double volume = 1.0;
  @observable
  bool applyBlur = false;
  @observable
  double blurIntensity = 5.0;

  @observable
  double locationX = 0.5;
  @observable
  double locationY = 0.3;

  @observable
  ObservableMap<String, String> thumbnails = ObservableMap<String, String>();

  // --- Player & Playback State ---
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

  // --- Navigation State ---
  @observable
  int activeNavIndex = 0; // 0: Job Hub, 1: Media Library, 2: Effects/Content

  @observable
  bool isFocusMode = false;

  // --- Form Controllers ---
  final titleController = TextEditingController(
    text: "Hiring Flutter Developer",
  );
  final salaryController = TextEditingController(text: "\$2000 - \$4000");
  final companyController = TextEditingController(text: "Scraki Inc.");
  final locationController = TextEditingController(text: "Từ xa");
  final contactController = TextEditingController(text: "Tuyển dụng");
  final headlineController = TextEditingController(
    text: "Cơ hội việc làm hấp dẫn!",
  );
  final captionController = TextEditingController(
    text: "#tuyendung #vieclam #flutter",
  );
  final requirementsController = TextEditingController(
    text: "Có kinh nghiệm Flutter\nThành thạo Dart\nBiết sử dụng MobX",
  );
  final benefitsController = TextEditingController(
    text: "Lương thưởng hấp dẫn\nBảo hiểm đầy đủ\nMôi trường chuyên nghiệp",
  );
  final jobSearchController = TextEditingController();

  // Preview capture key
  final previewKey = GlobalKey();

  // --- Actions ---

  @action
  void addSourceVideos(List<String> paths) {
    sourceVideoPaths.addAll(paths);
    _generateThumbnails(paths);
  }

  @action
  void removeSourceVideo(int index) {
    if (index >= 0 && index < sourceVideoPaths.length) {
      sourceVideoPaths.removeAt(index);
    }
  }

  @action
  void updatePosition(String type, double x, double y) {
    switch (type) {
      case 'title':
        titleX = x;
        titleY = y;
        break;
      case 'salary':
        salaryX = x;
        salaryY = y;
        break;
      case 'company':
        companyX = x;
        companyY = y;
        break;
      case 'requirements':
        requirementsX = x;
        requirementsY = y;
        break;
      case 'benefits':
        benefitsX = x;
        benefitsY = y;
        break;
      case 'contact':
        contactX = x;
        contactY = y;
        break;
      case 'headline':
        headlineX = x;
        headlineY = y;
        break;
      case 'location':
        locationX = x;
        locationY = y;
        break;
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
        break;
      case 'zoom':
        zoomIntensity = value;
        break;
      case 'anti_reup':
        enableAntiReup = value > 0.5;
        break;
      case 'volume':
        volume = value;
        break;
      case 'blur_intensity':
        blurIntensity = value;
        break;
    }
  }

  @action
  void toggleBlur(bool value) {
    applyBlur = value;
  }

  @action
  void setPlaybackSpeed(double value) {
    playbackSpeed = value;
  }

  @action
  void setVolume(double value) {
    volume = value;
  }

  @action
  void setApplyBlur(bool value) {
    applyBlur = value;
  }

  @action
  void setBlurIntensity(double value) {
    blurIntensity = value;
  }

  @action
  void selectPosterData(PosterData data) {
    selectedPosterData = data;
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

    // Setup stream listeners with runInAction for observable updates
    _durationSub = player.stream.duration.listen(
      (d) => runInAction(() => duration = d),
    );
    _positionSub = player.stream.position.listen(
      (p) => runInAction(() => position = p),
    );
    _playingSub = player.stream.playing.listen(
      (p) => runInAction(() => isPlaying = p),
    );

    // Initial updates
    updatePosterDataFromControllers();
    syncPlaylist();
  }

  /// Dispose player, controller, subscriptions, and form controllers
  @action
  void disposePlayer() {
    _durationSub?.cancel();
    _positionSub?.cancel();
    _playingSub?.cancel();
    player.dispose();
    titleController.dispose();
    salaryController.dispose();
    companyController.dispose();
    locationController.dispose();
    contactController.dispose();
    headlineController.dispose();
    captionController.dispose();
    requirementsController.dispose();
    benefitsController.dispose();
    jobSearchController.dispose();
  }

  /// Set active navigation index and reset focus mode if needed
  @action
  void setActiveNavIndex(int index) {
    activeNavIndex = index;
    if (index != 2) {
      isFocusMode = false;
    }
  }

  /// Toggle focus mode
  @action
  void toggleFocusMode() {
    isFocusMode = !isFocusMode;
  }

  /// Update poster data from form controllers
  @action
  void updatePosterDataFromControllers() {
    selectPosterData(
      PosterData(
        jobTitle: titleController.text,
        companyName: companyController.text,
        location: locationController.text,
        salaryRange: salaryController.text,
        contactInfo: contactController.text,
        catchyHeadline: headlineController.text,
        tikTokCaption: captionController.text,
        requirements: requirementsController.text
            .split('\n')
            .where((s) => s.trim().isNotEmpty)
            .toList(),
        benefits: benefitsController.text
            .split('\n')
            .where((s) => s.trim().isNotEmpty)
            .toList(),
      ),
    );
  }

  /// Capture preview widget as PNG at 720x1280 resolution
  @action
  Future<Uint8List> capturePreviewAsPng() async {
    try {
      final boundary =
          previewKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData!.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing preview: $e');
      rethrow;
    }
  }

  /// Handle video export by capturing preview and generating video
  @action
  Future<void> handleExportVideo() async {
    try {
      final overlayPng = await capturePreviewAsPng();
      await generateVideoWithOverlay(overlayPng);
    } catch (e) {
      debugPrint('Error during export: $e');
    }
  }

  /// Sync playlist from source video paths
  @action
  void syncPlaylist() {
    if (sourceVideoPaths.isEmpty) return;
    final medias = sourceVideoPaths.map((p) => Media(p)).toList();
    player.open(Playlist(medias));
    player.pause();
  }

  /// Play specific video by path
  @action
  void playVideo(String path) {
    final index = sourceVideoPaths.indexOf(path);
    if (index != -1) {
      player.jump(index);
      player.play();
    } else {
      player.open(Media(path));
      player.play();
    }
  }

  @action
  Future<void> generateVideoWithOverlay(Uint8List overlayPng) async {
    if (sourceVideoPaths.isEmpty || selectedPosterData == null) {
      errorMessage = "Please add videos and select recruitment info.";
      return;
    }

    isProcessing = true;
    errorMessage = null;

    try {
      final random = DateTime.now().millisecondsSinceEpoch % 1000;

      final composition = VideoComposition(
        id: const Uuid().v4(),
        posterData: selectedPosterData!,
        sourceVideoPaths: sourceVideoPaths,
        headlineX: headlineX,
        headlineY: headlineY,
        titleX: titleX,
        titleY: titleY,
        companyX: companyX,
        companyY: companyY,
        locationX: locationX,
        locationY: locationY,
        salaryX: salaryX,
        salaryY: salaryY,
        contactX: contactX,
        contactY: contactY,
        requirementsX: requirementsX,
        requirementsY: requirementsY,
        benefitsX: benefitsX,
        benefitsY: benefitsY,
        contrast: enableAntiReup ? (1.0 + (random % 15) / 200.0) : 1.0,
        saturation: enableAntiReup ? (0.5 + (random % 10) / 100.0) : 0.5,
        noiseLevel: enableAntiReup ? (random % 5) / 100.0 : 0.0,
        hueShift: enableAntiReup ? (random % 10 - 5) / 100.0 : 0.0,
        brightnessDelta: enableAntiReup ? (random % 10 - 5) / 200.0 : 0.0,
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

  @action
  Future<void> generateVideo() async {
    if (sourceVideoPaths.isEmpty || selectedPosterData == null) {
      errorMessage = "Please add videos and select recruitment info.";
      return;
    }

    try {
      isProcessing = true;
      errorMessage = null;

      final random = DateTime.now().millisecondsSinceEpoch;
      final composition = VideoComposition(
        id: const Uuid().v4(),
        sourceVideoPaths: sourceVideoPaths.toList(),
        posterData: selectedPosterData!,
        titleX: titleX,
        titleY: titleY,
        salaryX: salaryX,
        salaryY: salaryY,
        companyX: companyX,
        companyY: companyY,
        requirementsX: requirementsX,
        requirementsY: requirementsY,
        benefitsX: benefitsX,
        benefitsY: benefitsY,
        contactX: contactX,
        contactY: contactY,
        headlineX: headlineX,
        headlineY: headlineY,
        locationX: locationX,
        locationY: locationY,
        saturation: saturation,
        contrast: contrast,
        playbackSpeed: playbackSpeed,
        zoomIntensity: zoomIntensity,
        noiseLevel: enableAntiReup ? 0.05 : 0.0,
        hueShift: enableAntiReup ? (random % 10 - 5) / 100.0 : 0.0, // +/- 0.05
        brightnessDelta: enableAntiReup
            ? (random % 10 - 5) / 200.0
            : 0.0, // +/- 0.025
        randomSeed: random,
      );

      // TODO: Replace with actual preview capture in Phase 4
      generatedVideoPath = await _repository.generateVideo(
        composition,
        Uint8List(0), // Temporary placeholder
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
          print('Failed to extract thumbnail: $e');
        }
      }
    }
  }
}
