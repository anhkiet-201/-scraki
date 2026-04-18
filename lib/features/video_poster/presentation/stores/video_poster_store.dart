import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:google_fonts/google_fonts.dart';
import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:scraki/core/mixins/di_mixin.dart';
import 'package:scraki/features/dashboard/presentation/stores/dashboard_store.dart';
import 'package:scraki/features/video_poster/data/services/batch_video_service.dart';
import 'package:scraki/features/video_poster/data/repositories/recent_color_repository.dart';
import 'package:scraki/features/video_poster/domain/entities/custom_text_overlay.dart';
import 'package:scraki/features/video_poster/domain/entities/custom_image_overlay.dart';
import 'package:scraki/features/video_poster/domain/entities/favorite_image.dart';
import 'package:scraki/features/video_poster/domain/repositories/favorite_image_repository.dart';
import 'package:scraki/features/video_poster/domain/entities/slide_model.dart';
import 'package:scraki/features/video_poster/domain/entities/image_poster_config.dart';
import 'package:scraki/features/video_poster/data/services/image_poster_service.dart';
import 'package:uuid/uuid.dart';

part 'video_poster_store.g.dart';

/// Dashboard tab index for Video Poster
const int _kVideoEditorTabIndex = 2;

@injectable
// ignore: library_private_types_in_public_api
class VideoPosterStore = _VideoPosterStore with _$VideoPosterStore;

abstract class _VideoPosterStore with Store {
  final DashboardStore _dashboardStore = inject<DashboardStore>();
  final RecentColorRepository _recentColorRepo =
      inject<RecentColorRepository>();
  final FavoriteImageRepository _favoriteImageRepo =
      inject<FavoriteImageRepository>();

  // Initialization flag to prevent re-initialization on hot restart
  bool _isInitialized = false;

  _VideoPosterStore() {
    if (!_isInitialized) {
      initializePlayer();
      _loadRecentColors();
      _watchFavorites();
      
      // Initialize with one default slide
      addSlide();
      
      _isInitialized = true;
    }
  }

  // ─── Favorite Images ──────────────────────────────────────────────────────

  @observable
  ObservableList<FavoriteImage> favoriteImages =
      ObservableList<FavoriteImage>();

  @observable
  bool isLoadingFavorites = false;

  StreamSubscription<List<FavoriteImage>>? _favoritesSubscription;

  @action
  void _watchFavorites() {
    isLoadingFavorites = true;
    _favoritesSubscription?.cancel();
    _favoritesSubscription = _favoriteImageRepo.watchFavorites().listen(
      (list) {
        runInAction(() {
          favoriteImages.clear();
          favoriteImages.addAll(list);
          isLoadingFavorites = false;
        });
      },
      onError: (Object e) {
        debugPrint('Error watching favorites: $e');
        runInAction(() => isLoadingFavorites = false);
      },
    );
  }

  @action
  Future<void> toggleFavorite(String url, {bool isGif = false}) async {
    if (!url.startsWith('http')) {
      debugPrint(' toggleFavorite Local images are not supported');
      return;
    }

    final existingItem = favoriteImages.where((f) => f.url == url).firstOrNull;
    if (existingItem != null) {
      try {
        await _favoriteImageRepo.removeFavorite(existingItem.id);
      } catch (e) {
        debugPrint(' toggleFavorite Remove API failed: $e');
      }
    } else {
      final newItem = FavoriteImage(
        id: const Uuid().v4(),
        url: url,
        isGif: isGif,
        createdAt: DateTime.now(),
      );
      try {
        await _favoriteImageRepo.addFavorite(newItem);
      } catch (e) {
        debugPrint(' toggleFavorite Add API failed: $e');
      }
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

  // ─── Custom Image Overlays ────────────────────────────────────────────────

  @observable
  ObservableList<CustomImageOverlay> customImages =
      ObservableList<CustomImageOverlay>();

  @observable
  String? selectedCustomImageId;

  // ─── Slides Management ───────────────────────────────────────────────────

  @observable
  ObservableList<SlideModel> slides = ObservableList<SlideModel>();

  @observable
  int currentSlideIndex = 0;

  @action
  void addSlide() {
    final id = const Uuid().v4();
    slides.add(SlideModel(id: id, name: ''));
    _updateSlideNames();
    
    // If it's the first slide, select it
    if (slides.length == 1) {
      currentSlideIndex = 0;
    }
  }

  @action
  void selectSlide(int index) {
    if (index < 0 || index >= slides.length) return;
    
    // 1. Save current overlays to previous slide
    final prevSlide = slides[currentSlideIndex];
    slides[currentSlideIndex] = prevSlide.copyWith(
      texts: customTexts.toList(),
      images: customImages.toList(),
    );
    
    // 2. Switch index
    currentSlideIndex = index;
    
    // 3. Load overlays from new slide
    final newSlide = slides[currentSlideIndex];
    customTexts.clear();
    customTexts.addAll(newSlide.texts);
    customImages.clear();
    customImages.addAll(newSlide.images);
    
    // Reset selection
    selectedCustomTextId = null;
    selectedCustomImageId = null;
  }

  @action
  void removeSlide(int index) {
    if (slides.length <= 1) return; // Must have at least one slide
    
    slides.removeAt(index);
    _updateSlideNames();
    if (currentSlideIndex >= slides.length) {
      currentSlideIndex = slides.length - 1;
    }
    
    // Reload state for current index
    final current = slides[currentSlideIndex];
    customTexts.clear();
    customTexts.addAll(current.texts);
    customImages.clear();
    customImages.addAll(current.images);
  }

  @action
  void updateSlideName(int index, String name) {
    if (index < 0 || index >= slides.length) return;
    slides[index] = slides[index].copyWith(name: name);
  }

  @action
  void reorderSlides(int oldIndex, int newIndex) {
    if (slides.isEmpty) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    // Ensure valid currentSlideIndex before access
    final safeCurrentIndex = currentSlideIndex.clamp(0, slides.length - 1);
    final selectedSlideId = slides[safeCurrentIndex].id;

    final item = slides.removeAt(oldIndex);
    slides.insert(newIndex, item);
    _updateSlideNames();

    // Update currentSlideIndex so it still points to the same slide content
    final foundIndex = slides.indexWhere((s) => s.id == selectedSlideId);
    if (foundIndex != -1) {
      currentSlideIndex = foundIndex;
    }
  }

  void _updateSlideNames() {
    for (int i = 0; i < slides.length; i++) {
      slides[i] = slides[i].copyWith(name: 'Slide ${i + 1}');
    }
  }

  @action
  void addCustomImage(
    String imageUrl,
    double x,
    double y, {
    bool isGif = false,
  }) {
    // Thêm ảnh ngay với kích thước mặc định — không block UI thread
    final id = const Uuid().v4();
    runInAction(() {
      customImages.add(
        CustomImageOverlay(
          id: id,
          imageUrl: imageUrl,
          isGif: isGif,
          x: x,
          y: y,
          width: 200.0,
          height: 200.0,
        ),
      );
      selectedCustomImageId = id;
      selectedCustomTextId = null;
    });

    // Load kích thước thực ảnh bất đồng bộ — cập nhật sau khi xong
    _resolveImageSizeAsync(id, imageUrl);
  }

  /// Resolve kích thước ảnh bất đồng bộ, cập nhật store sau khi load xong.
  /// Không block UI thread.
  Future<void> _resolveImageSizeAsync(String id, String imageUrl) async {
    try {
      final ImageProvider provider;
      if (imageUrl.startsWith('http')) {
        provider = NetworkImage(imageUrl);
      } else if (imageUrl.startsWith('assets/')) {
        provider = AssetImage(imageUrl);
      } else {
        provider = FileImage(File(imageUrl));
      }

      final completer = Completer<ui.Image>();
      provider
          .resolve(const ImageConfiguration())
          .addListener(
            ImageStreamListener(
              (info, _) {
                if (!completer.isCompleted) completer.complete(info.image);
              },
              onError: (e, s) {
                if (!completer.isCompleted) completer.completeError(e);
              },
            ),
          );

      final image = await completer.future;
      final w = image.width.toDouble();
      final h = image.height.toDouble();
      final ratio = w / h;

      double finalW, finalH;
      if (w > h) {
        finalW = 300.0;
        finalH = 300.0 / ratio;
      } else {
        finalH = 300.0;
        finalW = 300.0 * ratio;
      }

      // Cập nhật kích thước thực sau khi load xong
      runInAction(() => updateCustomImageSize(id, finalW, finalH));
    } catch (e) {
      debugPrint('[ImageOverlay] Failed to resolve image size for $id: $e');
    }
  }

  @action
  void removeCustomImage(String id) {
    customImages.removeWhere((i) => i.id == id);
    if (selectedCustomImageId == id) {
      selectedCustomImageId = null;
    }
  }

  @action
  void selectCustomImage(String? id) {
    if (id != null) {
      selectedCustomTextId = null; // deselect text if selecting image
      
      // Move selected item to the end of the list for visual z-ordering
      final index = customImages.indexWhere((i) => i.id == id);
      if (index != -1 && index != customImages.length - 1) {
        final item = customImages.removeAt(index);
        customImages.add(item);
      }
    }
    selectedCustomImageId = id;
  }

  @action
  void reorderCustomImage(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = customImages.removeAt(oldIndex);
    customImages.insert(newIndex, item);
  }

  @action
  void updateCustomImagePosition(String id, double x, double y) {
    final index = customImages.indexWhere((i) => i.id == id);
    if (index == -1) return;
    customImages[index] = customImages[index].copyWith(x: x, y: y);
  }

  @action
  void updateCustomImageSize(String id, double width, double height) {
    final index = customImages.indexWhere((i) => i.id == id);
    if (index == -1) return;
    customImages[index] = customImages[index].copyWith(
      width: width.clamp(20.0, 1000.0),
      height: height.clamp(20.0, 1000.0),
    );
  }

  @action
  void updateCustomImageRotation(String id, double rotation) {
    final index = customImages.indexWhere((i) => i.id == id);
    if (index == -1) return;
    customImages[index] = customImages[index].copyWith(rotation: rotation);
  }

  @action
  void updateCustomImageTiming(
    String id, {
    double? startTime,
    double? endTime,
    bool clearEndTime = false,
  }) {
    final index = customImages.indexWhere((i) => i.id == id);
    if (index == -1) return;
    customImages[index] = customImages[index].copyWith(
      startTime: startTime,
      endTime: endTime,
      clearEndTime: clearEndTime,
    );
  }

  @action
  void updateCustomImageLocalPath(String id, String path) {
    final index = customImages.indexWhere((i) => i.id == id);
    if (index == -1) return;
    customImages[index] = customImages[index].copyWith(localPath: path);
  }

  @action
  void updateCustomImageBorder(
    String id, {
    Color? color,
    bool clearBorderColor = false,
    double? width,
    double? borderRadius,
  }) {
    final index = customImages.indexWhere((i) => i.id == id);
    if (index == -1) return;
    customImages[index] = customImages[index].copyWith(
      borderColor: color,
      clearBorderColor: clearBorderColor,
      borderWidth: width,
      borderRadius: borderRadius,
    );

    if (color != null) {
      _pushRecentColor(recentBorderColors, color);
    }
  }

  // ─── Recently Used Colors ────────────────────────────────────────────────

  static const int _kMaxRecentColors = 8;

  @observable
  ObservableList<Color> recentTextColors = ObservableList<Color>();

  @observable
  ObservableList<Color> recentBgColors = ObservableList<Color>();

  @observable
  ObservableList<Color> recentStrokeColors = ObservableList<Color>();

  @observable
  ObservableList<Color> recentBorderColors = ObservableList<Color>();

  void _pushRecentColor(ObservableList<Color> list, Color color) {
    // Xóa nếu đã tồn tại để tránh duplicate, rồi đưa màu mới lên đầu
    list.removeWhere((c) => c.toARGB32() == color.toARGB32());
    list.insert(0, color);
    if (list.length > _kMaxRecentColors) {
      list.removeRange(_kMaxRecentColors, list.length);
    }
    // Persist ngay sau khi update
    _saveRecentColors();
  }

  Future<void> _loadRecentColors() async {
    final textColors = await _recentColorRepo.getRecentTextColors();
    final bgColors = await _recentColorRepo.getRecentBgColors();
    final strokeColors = await _recentColorRepo.getRecentStrokeColors();
    final borderColors = await _recentColorRepo.getRecentBorderColors();

    runInAction(() {
      recentTextColors.addAll(textColors);
      recentBgColors.addAll(bgColors);
      recentStrokeColors.addAll(strokeColors);
      recentBorderColors.addAll(borderColors);
    });
  }

  void _saveRecentColors() {
    _recentColorRepo.saveRecentTextColors(recentTextColors.toList());
    _recentColorRepo.saveRecentBgColors(recentBgColors.toList());
    _recentColorRepo.saveRecentStrokeColors(recentStrokeColors.toList());
    _recentColorRepo.saveRecentBorderColors(recentBorderColors.toList());
  }

  @observable
  bool isHidingImagesForCapture = false;

  @observable
  bool isHidingAnimatedTextsForCapture = false;

  final Map<String, GlobalKey> _textCaptureKeys = {};

  GlobalKey getTextCaptureKey(String id) {
    return _textCaptureKeys.putIfAbsent(id, () => GlobalKey());
  }

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
    selectedCustomImageId = null;
  }

  @action
  void removeCustomText(String id) {
    customTexts.removeWhere((t) => t.id == id);
    if (selectedCustomTextId == id) {
      selectedCustomTextId = null;
    }
  }

  @observable
  ObservableMap<String, int> animationPreviewCounters = ObservableMap<String, int>();

  @observable
  ObservableMap<String, int> animationOutPreviewCounters = ObservableMap<String, int>();

  @action
  void triggerPreviewAnimation(String id) {
    final current = animationPreviewCounters[id] ?? 0;
    animationPreviewCounters[id] = current + 1;
  }

  @action
  void triggerPreviewAnimationOut(String id) {
    final current = animationOutPreviewCounters[id] ?? 0;
    animationOutPreviewCounters[id] = current + 1;
  }

  @action
  void selectCustomText(String? id) {
    if (id != null) {
      selectedCustomImageId = null; // deselect image if selecting text
      
      // Move selected item to the end of the list for visual z-ordering
      final index = customTexts.indexWhere((t) => t.id == id);
      if (index != -1 && index != customTexts.length - 1) {
        final item = customTexts.removeAt(index);
        customTexts.add(item);
      }
    }
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
    TextBackgroundStyle? backgroundStyle,
    double? backgroundOpacity,
    double? backgroundRadius,
    double? textHeight,
    bool clearTextHeight = false,
    String? fontFamily,
    double? rotation,
    double? letterSpacing,
    Color? backgroundBorderColor,
    double? backgroundBorderWidth,
    bool clearBackgroundBorderColor = false,
    Color? strokeColor,
    bool clearStrokeColor = false,
    double? strokeWidth,
    double? brushIntensity,
    double? brushThickness,
    double? brushComplexity,
    double? backgroundPadding,
    Map<String, dynamic>? styleParams,
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
      backgroundStyle: backgroundStyle,
      backgroundOpacity: backgroundOpacity,
      backgroundRadius: backgroundRadius,
      textHeight: textHeight,
      clearTextHeight: clearTextHeight,
      fontFamily: fontFamily,
      rotation: rotation,
      letterSpacing: letterSpacing,
      backgroundBorderColor: backgroundBorderColor,
      backgroundBorderWidth: backgroundBorderWidth,
      clearBackgroundBorderColor: clearBackgroundBorderColor,
      strokeColor: strokeColor,
      clearStrokeColor: clearStrokeColor,
      strokeWidth: strokeWidth,
      brushIntensity: brushIntensity,
      brushThickness: brushThickness,
      brushComplexity: brushComplexity,
      backgroundPadding: backgroundPadding,
      styleParams: styleParams,
    );

    // Ghi lại màu vừa dùng vào danh sách gần đây
    if (color != null) {
      _pushRecentColor(recentTextColors, color);
    }
    if (backgroundColor != null) {
      _pushRecentColor(recentBgColors, backgroundColor);
    }
    if (strokeColor != null) {
      _pushRecentColor(recentStrokeColors, strokeColor);
    }
  }

  @action
  void updateCustomTextTiming(
    String id, {
    double? startTime,
    double? endTime,
    bool clearEndTime = false,
  }) {
    final index = customTexts.indexWhere((t) => t.id == id);
    if (index == -1) return;
    customTexts[index] = customTexts[index].copyWith(
      startTime: startTime,
      endTime: endTime,
      clearEndTime: clearEndTime,
    );
  }

  @action
  void updateCustomTextAnimationIn(String id, TextAnimationType type, double duration) {
    final index = customTexts.indexWhere((t) => t.id == id);
    if (index == -1) return;
    customTexts[index] = customTexts[index].copyWith(
      animationInType: type,
      animationInDuration: duration,
    );
  }

  @action
  void updateCustomTextAnimationOut(String id, TextAnimationType type, double duration) {
    final index = customTexts.indexWhere((t) => t.id == id);
    if (index == -1) return;
    customTexts[index] = customTexts[index].copyWith(
      animationOutType: type,
      animationOutDuration: duration,
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

  // ─── Custom Audio ──────────────────────────────────────────────────

  /// Đường dẫn file nhạc nền tùy chỉnh được chọn bởi người dùng.
  /// null = không dùng nhạc tùy chỉnh.
  @observable
  String? customAudioPath;

  /// Âm lượng nhạc tùy chỉnh (0.0 – 1.0). Mặc định 80%.
  @observable
  double customAudioVolume = 0.8;

  /// Bật/tắt tự động tạo âm thanh môi trường (chim, suối, mưa...)
  @observable
  bool generateAmbientAudio = true;

  @action
  void setCustomAudioPath(String? path) {
    customAudioPath = path;
    _syncMusicTrack();
  }

  @action
  void setCustomAudioVolume(double volume) {
    customAudioVolume = volume.clamp(0.0, 1.0);
    if (isPreviewMode && !isMuted) {
      musicPlayer.setVolume(customAudioVolume * 100);
    }
  }

  @action
  void setGenerateAmbientAudio(bool value) {
    generateAmbientAudio = value;
  }

  /// Đồng bộ file nhạc nền vào musicPlayer nếu đang trong project.
  void _syncMusicTrack() {
    if (customAudioPath != null) {
      musicPlayer.open(Media(customAudioPath!), play: isPlaying);
    } else {
      musicPlayer.stop();
    }
  }

  BatchVideoService? _batchService;
  StreamSubscription<String>? _batchSub;

  @action
  void setBatchOutputCount(int count) {
    batchOutputCount = count.clamp(1, 999);
  }

  @action
  Future<void> createBatchVideos() async {
    if (sourceVideoPaths.isEmpty || isBatchCreating) return;

    _batchService = inject<BatchVideoService>();

    // Fix: Tạm thời tắt isPreviewMode và dừng video để khi chụp PNG UI
    // không bị dính logic render text theo thời gian thực (giúp hiển thị tất cả text).
    isPreviewMode = false;
    player.pause();

    // 1. Process text overlays: group static texts, isolate animated ones
    final timedOverlays = <TimedOverlay>[];
    if (customTexts.isNotEmpty) {
      try {
        final originalTexts = List<CustomTextOverlay>.from(customTexts);
        
        // Static texts can be grouped by timing
        final staticGroupedDocs = <String, List<CustomTextOverlay>>{};
        // Animated texts are handled individually
        final animatedTexts = <CustomTextOverlay>[];

        for (final text in originalTexts) {
          if (text.isAnimated) {
            animatedTexts.add(text);
          } else {
            final key = '${text.startTime}_${text.endTime}';
            staticGroupedDocs.putIfAbsent(key, () => []).add(text);
          }
        }

        // Helper to capture a specific set of texts
        Future<void> captureGroup(List<CustomTextOverlay> group, {CustomTextOverlay? animInfo}) async {
          runInAction(() {
            customTexts.clear();
            customTexts.addAll(group);
          });
          
          // Wait for UI to update (RepaintBoundary)
          await Future<void>.delayed(const Duration(milliseconds: 200));
          
          final bytes = await capturePreviewAsPng();
          timedOverlays.add(
            TimedOverlay(
              bytes: bytes,
              startTime: group.first.startTime,
              endTime: group.first.endTime,
              isAnimated: animInfo != null,
              animationInType: animInfo?.animationInType.name ?? 'none',
              animationInDuration: animInfo?.animationInDuration ?? 0.1,
              animationOutType: animInfo?.animationOutType.name ?? 'none',
              animationOutDuration: animInfo?.animationOutDuration ?? 0.1,
              // We capture full screen PNGs (1080x1920 at 1.5x),
              // Logical size is 720x1280.
              x: 0.5, 
              y: 0.5,
              width: 720,
              height: 1280,
            ),
          );
        }

        // Capture static groups
        for (final group in staticGroupedDocs.values) {
          await captureGroup(group);
        }

        // Capture individual animated texts
        for (final text in animatedTexts) {
          await captureGroup([text], animInfo: text);
        }

        // Restore original texts for UI
        runInAction(() {
          customTexts.clear();
          customTexts.addAll(originalTexts);
        });
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

    // Download network images if needed
    for (int i = 0; i < customImages.length; i++) {
      var img = customImages[i];
      if (img.imageUrl.startsWith('http')) {
        batchLogs.add('⬇️ Đang tải ảnh ${i + 1}/${customImages.length}...');
        try {
          String ext = img.isGif ? '.gif' : '.png';
          String path = await _downloadNetworkImage(img.imageUrl, ext);
          customImages[i] = img.copyWith(localPath: path);
        } catch (e) {
          batchLogs.add('❌ Lỗi tải ảnh: $e');
        }
      }
    }

    final config = BatchVideoConfig(
      outputCount: batchOutputCount,
      textOverlays: timedOverlays,
      imageOverlays: customImages.toList(),
      customAudioPath: customAudioPath,
      customAudioVolume: customAudioVolume,
      generateAmbientAudio: generateAmbientAudio,
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
    _imagePosterService?.cancel();
    _batchSub?.cancel();
    _batchSub = null;
    _batchService = null;
    _imagePosterService = null;
    isBatchCreating = false;
    batchLogs.add('🛑 Đã dừng.');
  }

  // ─── Image Poster Export ─────────────────────────────────────────────────────

  @observable
  bool isExportingImages = false;

  ImagePosterService? _imagePosterService;

  @action
  Future<void> exportImagePosters() async {
    if (sourceVideoPaths.isEmpty || isExportingImages) return;

    // Save current slide state before exporting
    selectSlide(currentSlideIndex);

    isExportingImages = true;
    isBatchCreating = true; // Use common flags for UI
    batchLogs.clear();
    batchOutputDir = null;
    _imagePosterService = ImagePosterService();

    try {
      batchLogs.add('📸 Đang chuẩn bị dữ liệu slides...');
      
      final overlayBytesMap = <String, Uint8List>{};
      
      // Save current selection to restore later
      final originalSlideIndex = currentSlideIndex;
      final originalTexts = customTexts.toList();
      final originalImages = customImages.toList();

      // Temporarily hide UI elements for clean capture if needed
      // (Similar logic to createBatchVideos)
      isPreviewMode = false;
      player.pause();

      for (int i = 0; i < slides.length; i++) {
        final slide = slides[i];
        batchLogs.add('🖼️ Đang chụp Slide: ${slide.name}...');
        
        // Load slide overlays into UI for capture
        runInAction(() {
          customTexts.clear();
          customTexts.addAll(slide.texts);
          customImages.clear();
          customImages.addAll(slide.images);
          selectedCustomTextId = null;
          selectedCustomImageId = null;
        });

        // Wait for UI update
        // ignore: inference_failure_on_instance_creation
        await Future.delayed(const Duration(milliseconds: 250));
        
        final bytes = await capturePreviewAsPng(hideImages: false);
        overlayBytesMap[slide.id] = bytes;
      }

      // Restore original state
      runInAction(() {
        currentSlideIndex = originalSlideIndex;
        customTexts.clear();
        customTexts.addAll(originalTexts);
        customImages.clear();
        customImages.addAll(originalImages);
      });

      final config = ImagePosterConfig(
        outputCount: batchOutputCount,
        slides: slides.toList(),
        outputFormat: 'jpg',
        width: 1080,
        height: 1350,
      );

      final stream = _imagePosterService!.generateImagePosters(
        sourceVideoPaths: sourceVideoPaths.toList(),
        config: config,
        slideOverlayBytes: overlayBytesMap,
        onOutputDir: (dir) => runInAction(() => batchOutputDir = dir),
      );

      await for (final log in stream) {
        runInAction(() => _handleLogUpdate(log));
      }

    } catch (e) {
      runInAction(() => batchLogs.add('❌ Lỗi: $e'));
    } finally {
      runInAction(() {
        isExportingImages = false;
        isBatchCreating = false;
      });
    }
  }

  @observable
  bool isImagePosterMode = false;

  @action
  void toggleImagePosterMode() {
    isImagePosterMode = !isImagePosterMode;
    if (isImagePosterMode) {
      player.pause();
    }
  }

  @action
  void randomizePreviewFrame() {
    if (player.state.duration == Duration.zero) return;
    final random = Random();
    final ms = random.nextInt(player.state.duration.inMilliseconds);
    seekProject(Duration(milliseconds: ms));
  }

  // ─── Effects State ─────────────────────────────────────────────────────────────

  @observable
  double playbackSpeed = 1.0;

  // ─── Player & Playback State ──────────────────────────────────────────────

  late final Player player;
  late final VideoController videoController;
  late final Player musicPlayer;

  @observable
  Duration duration = const Duration(seconds: 40);

  @observable
  Duration position = Duration.zero;

  @observable
  Duration realDuration = Duration.zero;

  @observable
  Duration musicDuration = Duration.zero;

  @observable
  bool isPlaying = false;

  @observable
  bool isPreviewMode = false;

  /// True khi player đang bị tắt tiếng (mute).
  /// Edit mode luôn mute; Preview mode check theo giá trị này.
  @observable
  bool isMuted = true;

  @action
  void toggleMute() {
    isMuted = !isMuted;
    _updateAllVolumes();
  }

  @action
  void togglePreviewMode() {
    isPreviewMode = !isPreviewMode;
    if (isPreviewMode) {
      // Vào Preview: bật âm thanh, tự động play
      isMuted = false;
      if (sourceVideoPaths.isNotEmpty) player.play();
    } else {
      // Ra khỏi Preview: mute lại
      isMuted = true;
    }
    _updateAllVolumes();
  }

  /// Cập nhật âm lượng cho cả 2 player dựa trên chế độ hiện tại.
  void _updateAllVolumes() {
    if (isMuted) {
      player.setVolume(0);
      musicPlayer.setVolume(0);
    } else {
      if (isPreviewMode) {
        // Preview: Video 5%, Nhạc x%
        player.setVolume(5);
        musicPlayer.setVolume(customAudioVolume * 100);
      } else {
        // Edit mode: Mute tất cả (hoặc tùy bác muốn Video 100% khi edit?)
        // Theo yêu cầu, edit mode vẫn nên để im lặng để tập trung.
        player.setVolume(0);
        musicPlayer.setVolume(0);
      }
    }
  }

  // Stream subscriptions (private)
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<double>? _rateSub;
  Timer? _playbackTimer;

  // Đồng hồ hệ thống để đo thời gian thực tế trôi qua — chính xác hơn cộng 100ms thủ công
  final Stopwatch _stopwatch = Stopwatch();
  Duration _positionAtLastSeek = Duration.zero;

  // ─── Navigation State ─────────────────────────────────────────────────────

  @observable
  int activeNavIndex = 0;

  // Preview capture key
  final previewKey = GlobalKey();

  /// True khi người dùng đang ở tab Video Editor.
  /// Dùng để chặn drop events khi widget vẫn alive nhưng bị ẩn (KeepAlivePage).
  bool get isOnVideoEditorTab =>
      _dashboardStore.selectedIndex == _kVideoEditorTabIndex;

  // ─── Actions ──────────────────────────────────────────────────────────────

  @action
  void addSourceVideos(List<String> paths) {
    if (paths.isEmpty ||
        _dashboardStore.selectedIndex != _kVideoEditorTabIndex) {
      return;
    }
    final wasEmpty = sourceVideoPaths.isEmpty;
    sourceVideoPaths.addAll(paths);

    if (wasEmpty && sourceVideoPaths.isNotEmpty) {
      currentVideoIndex = 0;
      _playCurrentVideo();
    }
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
    musicPlayer = Player();

    // Mặc định mute khi chạy để không gây phiền khi edit.
    player.setVolume(0);
    musicPlayer.setVolume(0);

    videoController = VideoController(
      player,
      configuration: const VideoControllerConfiguration(
        enableHardwareAcceleration: true,
      ),
    );

    player.setPlaylistMode(PlaylistMode.loop);
    // musicPlayer KHÔNG loop — nhạc dừng tự nhiên khi hết file
    musicPlayer.setPlaylistMode(PlaylistMode.none);

    _durationSub = player.stream.duration.listen((Duration d) {
      runInAction(() => realDuration = d);
    });

    musicPlayer.stream.duration.listen((Duration d) {
      runInAction(() => musicDuration = d);
    });

    _playingSub = player.stream.playing.listen((bool p) {
      runInAction(() {
        isPlaying = p;
        if (p) {
          // Resume: play nhạc nền trước, sau đó start timer (timer sẽ start stopwatch)
          musicPlayer.play();
          _startPlaybackTimer();
        } else {
          // Pause: dừng đồng hồ trước, rồi dừng timer và nhạc
          _stopwatch.stop();
          musicPlayer.pause();
          _stopPlaybackTimer();
        }
      });
    });

    _rateSub = player.stream.rate.listen((double r) {
      runInAction(() => playbackSpeed = r);
    });
  }

  void _startPlaybackTimer() {
    // Hủy timer cũ (KHÔNG stop stopwatch)
    _playbackTimer?.cancel();
    _playbackTimer = null;

    // Bật stopwatch từ vị trí hiện tại
    _stopwatch.start();

    _playbackTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      runInAction(() {
        // Tính position chính xác dựa trên thời gian thực tế đã trôi qua
        final newPos = _positionAtLastSeek + _stopwatch.elapsed;

        if (newPos >= duration) {
          // Hết Project: quay về đầu
          _positionAtLastSeek = Duration.zero;
          _stopwatch.reset();
          _stopwatch.start();
          position = Duration.zero;
          player.seek(Duration.zero);
          musicPlayer.seek(Duration.zero);
        } else {
          position = newPos;
        }
      });
    });
  }

  void _stopPlaybackTimer() {
    // Chỉ hủy Timer, KHÔNG stop Stopwatch ở đây
    // Stopwatch chỉ được dừng khi Pause (trong _playingSub)
    _playbackTimer?.cancel();
    _playbackTimer = null;
  }

  @action
  void seekProject(Duration p) {
    // 1. Cập nhật vị trí Project
    position = p;
    _positionAtLastSeek = p;

    // 2. Reset Stopwatch để tính lại chính xác từ điểm mới
    _stopwatch.reset();
    if (isPlaying) _stopwatch.start();

    // 3. Seek video (lặp lại theo realDuration)
    if (realDuration > Duration.zero) {
      final videoMs = p.inMilliseconds % realDuration.inMilliseconds;
      player.seek(Duration(milliseconds: videoMs));
    }

    // 4. Seek nhạc nền tuyến tính — quá thời lượng thì tự im lặng
    musicPlayer.seek(p);
  }

  /// Dispose player, controller, subscriptions, and any running batch job.
  @action
  void disposePlayer() {
    _stopPlaybackTimer();
    cancelBatchVideos();
    _favoritesSubscription?.cancel();
    _durationSub?.cancel();
    _playingSub?.cancel();
    _rateSub?.cancel();
    player.dispose();
    musicPlayer.dispose();
  }

  /// Start a new project by clearing all inputs and outputs
  @action
  void resetProject() {
    sourceVideoPaths.clear();
    customTexts.clear();
    customImages.clear();
    customAudioPath = null;
    currentVideoIndex = 0;
    player.stop();
    musicPlayer.stop();
    position = Duration.zero;

    // Clear batch output data
    batchLogs.clear();
    batchOutputDir = null;
  }

  @action
  void setActiveNavIndex(int index) {
    activeNavIndex = index;
  }

  @action
  void playVideoAtIndex(int index) {
    if (index < 0 || index >= sourceVideoPaths.length) return;
    currentVideoIndex = index;
    _playCurrentVideo();
  }

  void _playCurrentVideo() {
    if (sourceVideoPaths.isEmpty) return;
    // Không tự động phát video nếu đang ở chế độ Image Poster
    player.open(
      Media(sourceVideoPaths[currentVideoIndex]),
      play: !isImagePosterMode,
    );

    if (customAudioPath != null) {
      musicPlayer.open(
        Media(customAudioPath!),
        play: !isImagePosterMode,
      );
    }
  }

  @action
  Future<Uint8List> capturePreviewAsPng({bool hideImages = true}) async {
    try {
      if (previewKey.currentContext == null) {
        throw 'Please add at least one text or video element before exporting.';
      }

      final previousTextSelection = selectedCustomTextId;
      final previousImageSelection = selectedCustomImageId;
      selectCustomText(null);
      selectCustomImage(null);
      isHidingImagesForCapture = hideImages;

      await GoogleFonts.pendingFonts();
      await Future<void>.delayed(const Duration(milliseconds: 300));

      final renderObject = previewKey.currentContext?.findRenderObject();
      if (renderObject == null || renderObject is! RenderRepaintBoundary) {
        throw 'Preview render object not found.';
      }

      final logicalWidth = renderObject.size.width;
      final pixelRatio = 1080.0 / logicalWidth;
      final image = await renderObject.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      isHidingImagesForCapture = false;
      if (previousTextSelection != null) selectCustomText(previousTextSelection);
      if (previousImageSelection != null) selectCustomImage(previousImageSelection);

      if (byteData == null) throw 'Failed to encode overlay image.';
      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing preview: $e');
      rethrow;
    }
  }

  Future<String> _downloadNetworkImage(String url, String ext) async {
    final dio = Dio();
    final tempDir = await getTemporaryDirectory();
    final tempPath = '${tempDir.path}/temp_img_${DateTime.now().millisecondsSinceEpoch}$ext';
    
    await dio.download(url, tempPath);
    return tempPath;
  }
}
