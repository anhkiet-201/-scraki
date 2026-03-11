import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:http/http.dart' as http;
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
  void updateCustomImageLocalPath(String id, String path) {
    final index = customImages.indexWhere((i) => i.id == id);
    if (index == -1) return;
    customImages[index] = customImages[index].copyWith(localPath: path);
  }

  // ─── Recently Used Colors ────────────────────────────────────────────────

  static const int _kMaxRecentColors = 8;

  @observable
  ObservableList<Color> recentTextColors = ObservableList<Color>();

  @observable
  ObservableList<Color> recentBgColors = ObservableList<Color>();

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
    runInAction(() {
      recentTextColors.addAll(textColors);
      recentBgColors.addAll(bgColors);
    });
  }

  void _saveRecentColors() {
    // Fire-and-forget: lưu bất đồng bộ, không block UI
    _recentColorRepo.saveRecentTextColors(recentTextColors.toList());
    _recentColorRepo.saveRecentBgColors(recentBgColors.toList());
  }

  @observable
  bool isHidingImagesForCapture = false;

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

  @action
  void selectCustomText(String? id) {
    if (id != null) {
      selectedCustomImageId = null; // deselect image if selecting text
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
    double? backgroundOpacity,
    double? backgroundRadius,
    double? textHeight,
    bool clearTextHeight = false,
    String? fontFamily,
    double? rotation,
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
      rotation: rotation,
    );

    // Ghi lại màu vừa dùng vào danh sách gần đây
    if (color != null) _pushRecentColor(recentTextColors, color);
    if (backgroundColor != null) {
      _pushRecentColor(recentBgColors, backgroundColor);
    }
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
      overlayBytes: overlayBytes,
      imageOverlays: customImages.toList(),
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

  /// True khi người dùng đang ở tab Video Editor.
  /// Dùng để chặn drop events khi widget vẫn alive nhưng bị ẩn (KeepAlivePage).
  bool get isOnVideoEditorTab =>
      _dashboardStore.selectedIndex == _kVideoEditorTabIndex;

  // ─── Actions ──────────────────────────────────────────────────────────────

  @action
  void addSourceVideos(List<String> paths) {
    // Only add videos when on Video Editor tab to prevent conflicts with PhoneView
    if (paths.isEmpty ||
        _dashboardStore.selectedIndex != _kVideoEditorTabIndex) {
      return;
    }
    final wasEmpty = sourceVideoPaths.isEmpty;
    sourceVideoPaths.addAll(paths);

    // Auto-load and play the first video when media is added for the first time
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
    _favoritesSubscription?.cancel();
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
    customImages.clear();
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

      final previousTextSelection = selectedCustomTextId;
      final previousImageSelection = selectedCustomImageId;
      selectCustomText(null);
      selectCustomImage(null);
      isHidingImagesForCapture = true;

      // Wait until all Google Fonts have finished loading
      await GoogleFonts.pendingFonts();

      await Future<void>.delayed(const Duration(milliseconds: 300));

      final renderObject = previewKey.currentContext?.findRenderObject();
      if (renderObject == null || renderObject is! RenderRepaintBoundary) {
        throw 'Preview render object not found.';
      }

      // Standardize export to 1080p — pixel ratio 1.5 on 720px = 1080px
      const pixelRatio = 1.5;

      final image = await renderObject.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      isHidingImagesForCapture = false;
      // Restore selection
      if (previousTextSelection != null)
        selectCustomText(previousTextSelection);
      if (previousImageSelection != null)
        selectCustomImage(previousImageSelection);

      if (byteData == null) throw 'Failed to encode overlay image.';

      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing preview: $e');
      rethrow;
    }
  }

  Future<String> _downloadNetworkImage(String url, String ext) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/temp_img_${DateTime.now().millisecondsSinceEpoch}$ext',
      );
      await tempFile.writeAsBytes(response.bodyBytes);
      return tempFile.path;
    }
    throw 'HTTP ${response.statusCode}';
  }
}
