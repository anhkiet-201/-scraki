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
import 'package:scraki/features/poster/domain/entities/poster_data.dart';
import 'package:scraki/features/poster/presentation/stores/poster_creation_store.dart';
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
  final PosterCreationStore creationStore;
  final AntiReupService _antiReupService;
  final DashboardStore _dashboardStore = inject<DashboardStore>();

  // Initialization flag to prevent re-initialization on hot restart
  bool _isInitialized = false;

  // Reaction disposer
  ReactionDisposer? _jobSyncDisposer;

  _VideoPosterStore(
    this._repository,
    this.creationStore,
    this._antiReupService,
  ) {
    if (!_isInitialized) {
      initializePlayer();
      _setupJobSyncReaction();

      // Initialize with 'Maximize Stealth' (Random Config) by default
      // This ensures strict duration enforcement (15-25s) is active out-of-the-box.
      antiReupConfig = _antiReupService.maximizeStealth();

      _isInitialized = true;
    }
  }

  /// Setup reaction to sync job data from PosterCreationStore
  void _setupJobSyncReaction() {
    _jobSyncDisposer = reaction((_) => creationStore.currentPosterData, (
      PosterData? data,
    ) {
      if (data != null) {
        // Sync to controllers
        titleController.text = data.jobTitle;
        companyController.text = data.companyName;
        salaryController.text = data.salaryRange;
        locationController.text = data.location;
        contactController.text = data.contactInfo;
        headlineController.text = data.catchyHeadline ?? "";
        captionController.text = data.tikTokCaption ?? "";
        requirementsController.text = data.requirements.join('\n');
        benefitsController.text = data.benefits.join('\n');
      }
    });
  }

  @observable
  ObservableList<String> sourceVideoPaths = ObservableList<String>();

  @observable
  PosterData? _selectedPosterData;

  @computed
  PosterData? get selectedPosterData => _selectedPosterData?.copyWith(
    benefits:
        _selectedPosterData?.benefits
            .map((e) => _filterRiskyKeywords(e))
            .toList() ??
        [],
  );

  /// Filters risky keywords from text to avoid TikTok's recruitment scam flags.
  /// Uses case-insensitive regex for robust matching and replaces with safe synonyms.
  String _filterRiskyKeywords(String text) {
    if (text.isEmpty) return text;

    String filtered = text;

    final replacements = {
      // Money & Salary
      r'Lương': 'Lúa',
      r'Tiền': 'Thóc',
      r'Triệu': 'Củ',
      r'VNĐ': 'Xu',
      r'Thu nhập': 'Thu hoạch',
      r'Hoa hồng': 'Tip',

      // Off-platform & Contact
      r'Zalo': 'App xanh',
      r'Telegram': 'Tele',
      r'Link': 'Liên kết',
      r'Bio': 'Thông tin',
      r'Phone': 'Liên hệ',
      r'SĐT': 'Số hotline',
      r'Gọi': 'Kết nối',
      r'Call': 'Kết nối',
      r'Website': 'Trang chủ',
      r'Inbox|Inb': 'Nhắn tin',

      // Recruitment & Urgency
      r'Apply|Ứng tuyển': 'Tham gia',
      r'Tuyển': 'Mời',
      r'Việc nhẹ': 'Công việc',
      r'Lương cao': 'Thu nhập tốt',
      r'Tại nhà': 'Linh hoạt',
      r'Gấp|Ngay': 'Liền',

      // Benefits & Perks (User requested)
      r'Thưởng': 'Quà',
      r'Bao cơm|Cơm': 'Ăn uống',
      r'Phụ cấp': 'Hỗ trợ',
    };

    replacements.forEach((key, value) {
      filtered = filtered.replaceAll(RegExp(key, caseSensitive: false), value);
    });

    return filtered;
  }

  set selectedPosterData(PosterData? data) {
    runInAction(() => _selectedPosterData = data);
  }

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
  String? selectedOverlayType;

  // --- Per-overlay Font Sizes (Standardized 720p base) ---
  @observable
  double titleFontSize = 48;
  @observable
  double salaryFontSize = 38;
  @observable
  double companyFontSize = 32;
  @observable
  double locationFontSize = 28;
  @observable
  double requirementsFontSize = 26;
  @observable
  double benefitsFontSize = 26;
  @observable
  double contactFontSize = 30;
  @observable
  double headlineFontSize = 40;

  @observable
  double saturation = 1.2;
  @observable
  double contrast = 1.0;
  @observable
  double playbackSpeed = 1.0;
  @observable
  double zoomIntensity = 0.0;

  @observable
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

  // --- Navigation State ---
  @observable
  int activeNavIndex = 0; // 0: Job Hub, 1: Media Library, 2: Effects/Content

  @observable
  bool isFocusMode = false;

  // --- Form Controllers ---
  final titleController = TextEditingController(text: "");
  final salaryController = TextEditingController(text: "");
  final companyController = TextEditingController(text: "");
  final locationController = TextEditingController(text: "");
  final contactController = TextEditingController(text: "");
  final headlineController = TextEditingController(text: "");
  final captionController = TextEditingController(text: "");
  final requirementsController = TextEditingController(text: "");
  final benefitsController = TextEditingController(text: "");
  final jobSearchController = TextEditingController();

  // Preview capture key
  final previewKey = GlobalKey();

  // --- Actions ---

  @action
  void addSourceVideos(List<String> paths) {
    // Only add videos when on Video Editor tab to prevent conflicts with PhoneView
    if (paths.isEmpty ||
        _dashboardStore.selectedIndex != _kVideoEditorTabIndex) {
      return;
    }
    // Calculate start index for new items
    final startIndex = sourceVideoPaths.length;

    // Add paths and placeholder durations
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
        // Ensure index is still valid (user might have deleted items)
        if (targetIndex < clipDurations.length) {
          runInAction(() => clipDurations[targetIndex] = d);
        }
      } catch (e) {
        debugPrint("Error getting duration for $path: $e");
        // Already zero placeholder, no action needed
      }
    }
  }

  @action
  void removeSourceVideo(int index) {
    if (index >= 0 && index < sourceVideoPaths.length) {
      // 1. Pause player first to prevent issues
      player.pause();

      // 2. Remove from data lists
      sourceVideoPaths.removeAt(index);
      if (index < clipDurations.length) {
        clipDurations.removeAt(index);
      }

      // 3. Re-sync playlist
      // This is crucial because the player needs to know the media list changed.
      // Simply removing from sourceVideoPaths doesn't update the active player playlist.
      if (sourceVideoPaths.isEmpty) {
        // If no videos left, stop and clear player
        player.stop();
      } else {
        // Re-open playlist with remaining videos
        // If we removed the current video, logic effectively resets to start or next video
        syncPlaylist();

        // Optional: If you want to try and keep position in other videos, it gets complex.
        // For now, resetting (done by syncPlaylist which usually starts at 0) is safer UX.
      }
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

  @action
  void selectPosterData(PosterData? data) {
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
    _rateSub?.cancel();
    _playlistSub?.cancel();
    _widthSub?.cancel();
    _heightSub?.cancel();
    _jobSyncDisposer?.call();
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

  /// Select an overlay type for editing
  @action
  void setSelectedOverlayType(String? type) {
    selectedOverlayType = type;
  }

  /// Update font size for a specific overlay
  @action
  void updateFontSize(String type, double newSize) {
    // Clamp to reasonable limits
    final size = newSize.clamp(12.0, 120.0);
    switch (type) {
      case 'title':
        titleFontSize = size;
        break;
      case 'salary':
        salaryFontSize = size;
        break;
      case 'company':
        companyFontSize = size;
        break;
      case 'location':
        locationFontSize = size;
        break;
      case 'requirements':
        requirementsFontSize = size;
        break;
      case 'benefits':
        benefitsFontSize = size;
        break;
      case 'contact':
        contactFontSize = size;
        break;
      case 'headline':
        headlineFontSize = size;
        break;
    }
  }

  /// Update text content from canvas editing
  @action
  void updateTextContent(String type, String value) {
    switch (type) {
      case 'title':
        titleController.text = value;
        break;
      case 'salary':
        salaryController.text = value;
        break;
      case 'company':
        companyController.text = value;
        break;
      case 'location':
        locationController.text = value;
        break;
      case 'contact':
        contactController.text = value;
        break;
      case 'headline':
        headlineController.text = value;
        break;
      case 'requirements':
      case 'benefits':
        // Parse list format back to controller format
        // Input format: "Header:\n• Item 1\n• Item 2"
        // Output format: "Item 1\nItem 2"
        final lines = value.split('\n');
        final cleanLines = lines
            .where(
              (line) =>
                  !line.startsWith('📋') && // Remove header
                  !line.startsWith('🎁') && // Remove header
                  line.trim().isNotEmpty,
            )
            .map(
              (line) => line.replaceAll(RegExp(r'^•\s*'), ''),
            ) // Remove bullet
            .toList();

        if (type == 'requirements') {
          requirementsController.text = cleanLines.join('\n');
        } else {
          benefitsController.text = cleanLines.join('\n');
        }
        break;
    }
    updatePosterDataFromControllers();
  }

  /// Update poster data from form controllers
  @action
  void updatePosterDataFromControllers() {
    // Create PosterData from current controller values
    final data = PosterData(
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
    );

    // Update selected poster data
    selectPosterData(data);
  }

  /// Capture preview widget as PNG at 720x1280 resolution
  @action
  Future<Uint8List> capturePreviewAsPng() async {
    try {
      // Safety check: if preview is not mounted, return empty or throw clear error
      if (previewKey.currentContext == null) {
        debugPrint(
          'Warning: previewKey.currentContext is null. UI likely not rendered.',
        );
        // If no poster data selected, we can't generate overlay.
        // Return empty list which repo handles as "no overlay" or throw specific error?
        // Let's throw a user-friendly error string that handleExportVideo can catch.
        throw 'Please select a Job Position to generate overlay.';
      }

      // Deselect all overlays to hide handles/borders before capture
      final previousSelection = selectedOverlayType;
      setSelectedOverlayType(null);

      // Wait for UI to update and remove handles
      await Future<void>.delayed(const Duration(milliseconds: 300));

      final renderObject = previewKey.currentContext?.findRenderObject();
      if (renderObject == null || renderObject is! RenderRepaintBoundary) {
        throw 'Preview render object not found.';
      }
      final boundary = renderObject;

      // Standardize export to 1080p (Full HD)
      // Virtual Canvas is 720px, so pixelRatio 1.5 = 1080px width
      const pixelRatio = 1.5;

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      // Restore previous selection after capture
      setSelectedOverlayType(previousSelection);

      if (byteData == null) throw 'Failed to encode overlay image.';

      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing preview: $e');
      rethrow;
    }
  }

  @computed
  Duration get totalDuration {
    // If Anti-Reup has a target duration (randomized or manual), that is the output duration.
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

    // Robust check for index sync
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
        // Found the clip
        final seekPos = target - temp;

        if (i == currentPlaylistIndex) {
          // Same clip: Seek immediately
          _seekDebounceTimer?.cancel();
          await player.seek(seekPos);
        } else {
          // Different clip: Debounce the jump to prevent rapid switching
          if (_seekDebounceTimer?.isActive ?? false) {
            _seekDebounceTimer!.cancel();
          }

          _seekDebounceTimer = Timer(
            const Duration(milliseconds: 150),
            () async {
              await player.jump(i);
              // Wait briefly for player to catch up after jump
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

  @observable
  AntiReupConfig antiReupConfig = const AntiReupConfig(); // Use Config object

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
      // Generate random configuration immediately so the UI (and duration)
      // reflects exactly what will be exported.
      antiReupConfig = _antiReupService.maximizeStealth();
    } else {
      // Turn off randomization but keep current values (or reset? usually keep is better UX)
      // Removing targetDuration implies reverting to source length
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

  /// Handle video export by capturing preview and generating video
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

    // Preserve current index if it's still valid
    int savedIndex = currentPlaylistIndex;
    if (savedIndex >= sourceVideoPaths.length) {
      savedIndex = 0;
    }

    debugPrint('syncPlaylist: opening playlist with index $savedIndex');
    final medias = sourceVideoPaths.map((p) => Media(p)).toList();
    player.open(Playlist(medias, index: savedIndex));
    player.pause();
  }

  /// Play specific video by path
  @action
  void playVideoAtIndex(int index) {
    if (index >= 0 && index < sourceVideoPaths.length) {
      currentPlaylistIndex = index; // Optimistic update
      player.jump(index);
      player.play();
    }
  }

  /// Play specific video by path (Deprecated, finds first occurrence)
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
    if (sourceVideoPaths.isEmpty || selectedPosterData == null) {
      errorMessage = "Please add videos and select recruitment info.";
      return;
    }

    isProcessing = true;
    errorMessage = null;

    try {
      final random = DateTime.now().millisecondsSinceEpoch % 1000;

      // If randomized, regenerate config NOW to ensure every export has a unique hash.
      if (antiReupConfig.isRandomized) {
        antiReupConfig = _antiReupService.maximizeStealth().copyWith(
          targetDuration: antiReupConfig.targetDuration,
        );
      }
      final finalConfig = antiReupConfig;

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
        contrast: contrast,
        saturation: saturation,
        playbackSpeed: playbackSpeed,
        zoomIntensity: zoomIntensity,
        antiReupConfig: finalConfig, // Pass the config
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
