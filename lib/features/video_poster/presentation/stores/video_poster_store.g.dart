// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_poster_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$VideoPosterStore on _VideoPosterStore, Store {
  late final _$favoriteImagesAtom = Atom(
    name: '_VideoPosterStore.favoriteImages',
    context: context,
  );

  @override
  ObservableList<FavoriteImage> get favoriteImages {
    _$favoriteImagesAtom.reportRead();
    return super.favoriteImages;
  }

  @override
  set favoriteImages(ObservableList<FavoriteImage> value) {
    _$favoriteImagesAtom.reportWrite(value, super.favoriteImages, () {
      super.favoriteImages = value;
    });
  }

  late final _$isLoadingFavoritesAtom = Atom(
    name: '_VideoPosterStore.isLoadingFavorites',
    context: context,
  );

  @override
  bool get isLoadingFavorites {
    _$isLoadingFavoritesAtom.reportRead();
    return super.isLoadingFavorites;
  }

  @override
  set isLoadingFavorites(bool value) {
    _$isLoadingFavoritesAtom.reportWrite(value, super.isLoadingFavorites, () {
      super.isLoadingFavorites = value;
    });
  }

  late final _$sourceVideoPathsAtom = Atom(
    name: '_VideoPosterStore.sourceVideoPaths',
    context: context,
  );

  @override
  ObservableList<String> get sourceVideoPaths {
    _$sourceVideoPathsAtom.reportRead();
    return super.sourceVideoPaths;
  }

  @override
  set sourceVideoPaths(ObservableList<String> value) {
    _$sourceVideoPathsAtom.reportWrite(value, super.sourceVideoPaths, () {
      super.sourceVideoPaths = value;
    });
  }

  late final _$currentVideoIndexAtom = Atom(
    name: '_VideoPosterStore.currentVideoIndex',
    context: context,
  );

  @override
  int get currentVideoIndex {
    _$currentVideoIndexAtom.reportRead();
    return super.currentVideoIndex;
  }

  @override
  set currentVideoIndex(int value) {
    _$currentVideoIndexAtom.reportWrite(value, super.currentVideoIndex, () {
      super.currentVideoIndex = value;
    });
  }

  late final _$customTextsAtom = Atom(
    name: '_VideoPosterStore.customTexts',
    context: context,
  );

  @override
  ObservableList<CustomTextOverlay> get customTexts {
    _$customTextsAtom.reportRead();
    return super.customTexts;
  }

  @override
  set customTexts(ObservableList<CustomTextOverlay> value) {
    _$customTextsAtom.reportWrite(value, super.customTexts, () {
      super.customTexts = value;
    });
  }

  late final _$customImagesAtom = Atom(
    name: '_VideoPosterStore.customImages',
    context: context,
  );

  @override
  ObservableList<CustomImageOverlay> get customImages {
    _$customImagesAtom.reportRead();
    return super.customImages;
  }

  @override
  set customImages(ObservableList<CustomImageOverlay> value) {
    _$customImagesAtom.reportWrite(value, super.customImages, () {
      super.customImages = value;
    });
  }

  late final _$selectedCustomImageIdAtom = Atom(
    name: '_VideoPosterStore.selectedCustomImageId',
    context: context,
  );

  @override
  String? get selectedCustomImageId {
    _$selectedCustomImageIdAtom.reportRead();
    return super.selectedCustomImageId;
  }

  @override
  set selectedCustomImageId(String? value) {
    _$selectedCustomImageIdAtom.reportWrite(
      value,
      super.selectedCustomImageId,
      () {
        super.selectedCustomImageId = value;
      },
    );
  }

  late final _$slidesAtom = Atom(
    name: '_VideoPosterStore.slides',
    context: context,
  );

  @override
  ObservableList<SlideModel> get slides {
    _$slidesAtom.reportRead();
    return super.slides;
  }

  @override
  set slides(ObservableList<SlideModel> value) {
    _$slidesAtom.reportWrite(value, super.slides, () {
      super.slides = value;
    });
  }

  late final _$currentSlideIndexAtom = Atom(
    name: '_VideoPosterStore.currentSlideIndex',
    context: context,
  );

  @override
  int get currentSlideIndex {
    _$currentSlideIndexAtom.reportRead();
    return super.currentSlideIndex;
  }

  @override
  set currentSlideIndex(int value) {
    _$currentSlideIndexAtom.reportWrite(value, super.currentSlideIndex, () {
      super.currentSlideIndex = value;
    });
  }

  late final _$recentTextColorsAtom = Atom(
    name: '_VideoPosterStore.recentTextColors',
    context: context,
  );

  @override
  ObservableList<ui.Color> get recentTextColors {
    _$recentTextColorsAtom.reportRead();
    return super.recentTextColors;
  }

  @override
  set recentTextColors(ObservableList<ui.Color> value) {
    _$recentTextColorsAtom.reportWrite(value, super.recentTextColors, () {
      super.recentTextColors = value;
    });
  }

  late final _$recentBgColorsAtom = Atom(
    name: '_VideoPosterStore.recentBgColors',
    context: context,
  );

  @override
  ObservableList<ui.Color> get recentBgColors {
    _$recentBgColorsAtom.reportRead();
    return super.recentBgColors;
  }

  @override
  set recentBgColors(ObservableList<ui.Color> value) {
    _$recentBgColorsAtom.reportWrite(value, super.recentBgColors, () {
      super.recentBgColors = value;
    });
  }

  late final _$recentStrokeColorsAtom = Atom(
    name: '_VideoPosterStore.recentStrokeColors',
    context: context,
  );

  @override
  ObservableList<ui.Color> get recentStrokeColors {
    _$recentStrokeColorsAtom.reportRead();
    return super.recentStrokeColors;
  }

  @override
  set recentStrokeColors(ObservableList<ui.Color> value) {
    _$recentStrokeColorsAtom.reportWrite(value, super.recentStrokeColors, () {
      super.recentStrokeColors = value;
    });
  }

  late final _$recentBorderColorsAtom = Atom(
    name: '_VideoPosterStore.recentBorderColors',
    context: context,
  );

  @override
  ObservableList<ui.Color> get recentBorderColors {
    _$recentBorderColorsAtom.reportRead();
    return super.recentBorderColors;
  }

  @override
  set recentBorderColors(ObservableList<ui.Color> value) {
    _$recentBorderColorsAtom.reportWrite(value, super.recentBorderColors, () {
      super.recentBorderColors = value;
    });
  }

  late final _$isHidingImagesForCaptureAtom = Atom(
    name: '_VideoPosterStore.isHidingImagesForCapture',
    context: context,
  );

  @override
  bool get isHidingImagesForCapture {
    _$isHidingImagesForCaptureAtom.reportRead();
    return super.isHidingImagesForCapture;
  }

  @override
  set isHidingImagesForCapture(bool value) {
    _$isHidingImagesForCaptureAtom.reportWrite(
      value,
      super.isHidingImagesForCapture,
      () {
        super.isHidingImagesForCapture = value;
      },
    );
  }

  late final _$isHidingAnimatedTextsForCaptureAtom = Atom(
    name: '_VideoPosterStore.isHidingAnimatedTextsForCapture',
    context: context,
  );

  @override
  bool get isHidingAnimatedTextsForCapture {
    _$isHidingAnimatedTextsForCaptureAtom.reportRead();
    return super.isHidingAnimatedTextsForCapture;
  }

  @override
  set isHidingAnimatedTextsForCapture(bool value) {
    _$isHidingAnimatedTextsForCaptureAtom.reportWrite(
      value,
      super.isHidingAnimatedTextsForCapture,
      () {
        super.isHidingAnimatedTextsForCapture = value;
      },
    );
  }

  late final _$selectedCustomTextIdAtom = Atom(
    name: '_VideoPosterStore.selectedCustomTextId',
    context: context,
  );

  @override
  String? get selectedCustomTextId {
    _$selectedCustomTextIdAtom.reportRead();
    return super.selectedCustomTextId;
  }

  @override
  set selectedCustomTextId(String? value) {
    _$selectedCustomTextIdAtom.reportWrite(
      value,
      super.selectedCustomTextId,
      () {
        super.selectedCustomTextId = value;
      },
    );
  }

  late final _$animationPreviewCountersAtom = Atom(
    name: '_VideoPosterStore.animationPreviewCounters',
    context: context,
  );

  @override
  ObservableMap<String, int> get animationPreviewCounters {
    _$animationPreviewCountersAtom.reportRead();
    return super.animationPreviewCounters;
  }

  @override
  set animationPreviewCounters(ObservableMap<String, int> value) {
    _$animationPreviewCountersAtom.reportWrite(
      value,
      super.animationPreviewCounters,
      () {
        super.animationPreviewCounters = value;
      },
    );
  }

  late final _$animationOutPreviewCountersAtom = Atom(
    name: '_VideoPosterStore.animationOutPreviewCounters',
    context: context,
  );

  @override
  ObservableMap<String, int> get animationOutPreviewCounters {
    _$animationOutPreviewCountersAtom.reportRead();
    return super.animationOutPreviewCounters;
  }

  @override
  set animationOutPreviewCounters(ObservableMap<String, int> value) {
    _$animationOutPreviewCountersAtom.reportWrite(
      value,
      super.animationOutPreviewCounters,
      () {
        super.animationOutPreviewCounters = value;
      },
    );
  }

  late final _$batchOutputCountAtom = Atom(
    name: '_VideoPosterStore.batchOutputCount',
    context: context,
  );

  @override
  int get batchOutputCount {
    _$batchOutputCountAtom.reportRead();
    return super.batchOutputCount;
  }

  @override
  set batchOutputCount(int value) {
    _$batchOutputCountAtom.reportWrite(value, super.batchOutputCount, () {
      super.batchOutputCount = value;
    });
  }

  late final _$isBatchCreatingAtom = Atom(
    name: '_VideoPosterStore.isBatchCreating',
    context: context,
  );

  @override
  bool get isBatchCreating {
    _$isBatchCreatingAtom.reportRead();
    return super.isBatchCreating;
  }

  @override
  set isBatchCreating(bool value) {
    _$isBatchCreatingAtom.reportWrite(value, super.isBatchCreating, () {
      super.isBatchCreating = value;
    });
  }

  late final _$batchLogsAtom = Atom(
    name: '_VideoPosterStore.batchLogs',
    context: context,
  );

  @override
  ObservableList<String> get batchLogs {
    _$batchLogsAtom.reportRead();
    return super.batchLogs;
  }

  @override
  set batchLogs(ObservableList<String> value) {
    _$batchLogsAtom.reportWrite(value, super.batchLogs, () {
      super.batchLogs = value;
    });
  }

  late final _$batchOutputDirAtom = Atom(
    name: '_VideoPosterStore.batchOutputDir',
    context: context,
  );

  @override
  String? get batchOutputDir {
    _$batchOutputDirAtom.reportRead();
    return super.batchOutputDir;
  }

  @override
  set batchOutputDir(String? value) {
    _$batchOutputDirAtom.reportWrite(value, super.batchOutputDir, () {
      super.batchOutputDir = value;
    });
  }

  late final _$customAudioPathAtom = Atom(
    name: '_VideoPosterStore.customAudioPath',
    context: context,
  );

  @override
  String? get customAudioPath {
    _$customAudioPathAtom.reportRead();
    return super.customAudioPath;
  }

  @override
  set customAudioPath(String? value) {
    _$customAudioPathAtom.reportWrite(value, super.customAudioPath, () {
      super.customAudioPath = value;
    });
  }

  late final _$customAudioVolumeAtom = Atom(
    name: '_VideoPosterStore.customAudioVolume',
    context: context,
  );

  @override
  double get customAudioVolume {
    _$customAudioVolumeAtom.reportRead();
    return super.customAudioVolume;
  }

  @override
  set customAudioVolume(double value) {
    _$customAudioVolumeAtom.reportWrite(value, super.customAudioVolume, () {
      super.customAudioVolume = value;
    });
  }

  late final _$generateAmbientAudioAtom = Atom(
    name: '_VideoPosterStore.generateAmbientAudio',
    context: context,
  );

  @override
  bool get generateAmbientAudio {
    _$generateAmbientAudioAtom.reportRead();
    return super.generateAmbientAudio;
  }

  @override
  set generateAmbientAudio(bool value) {
    _$generateAmbientAudioAtom.reportWrite(
      value,
      super.generateAmbientAudio,
      () {
        super.generateAmbientAudio = value;
      },
    );
  }

  late final _$isExportingImagesAtom = Atom(
    name: '_VideoPosterStore.isExportingImages',
    context: context,
  );

  @override
  bool get isExportingImages {
    _$isExportingImagesAtom.reportRead();
    return super.isExportingImages;
  }

  @override
  set isExportingImages(bool value) {
    _$isExportingImagesAtom.reportWrite(value, super.isExportingImages, () {
      super.isExportingImages = value;
    });
  }

  late final _$isImagePosterModeAtom = Atom(
    name: '_VideoPosterStore.isImagePosterMode',
    context: context,
  );

  @override
  bool get isImagePosterMode {
    _$isImagePosterModeAtom.reportRead();
    return super.isImagePosterMode;
  }

  @override
  set isImagePosterMode(bool value) {
    _$isImagePosterModeAtom.reportWrite(value, super.isImagePosterMode, () {
      super.isImagePosterMode = value;
    });
  }

  late final _$playbackSpeedAtom = Atom(
    name: '_VideoPosterStore.playbackSpeed',
    context: context,
  );

  @override
  double get playbackSpeed {
    _$playbackSpeedAtom.reportRead();
    return super.playbackSpeed;
  }

  @override
  set playbackSpeed(double value) {
    _$playbackSpeedAtom.reportWrite(value, super.playbackSpeed, () {
      super.playbackSpeed = value;
    });
  }

  late final _$durationAtom = Atom(
    name: '_VideoPosterStore.duration',
    context: context,
  );

  @override
  Duration get duration {
    _$durationAtom.reportRead();
    return super.duration;
  }

  @override
  set duration(Duration value) {
    _$durationAtom.reportWrite(value, super.duration, () {
      super.duration = value;
    });
  }

  late final _$positionAtom = Atom(
    name: '_VideoPosterStore.position',
    context: context,
  );

  @override
  Duration get position {
    _$positionAtom.reportRead();
    return super.position;
  }

  @override
  set position(Duration value) {
    _$positionAtom.reportWrite(value, super.position, () {
      super.position = value;
    });
  }

  late final _$realDurationAtom = Atom(
    name: '_VideoPosterStore.realDuration',
    context: context,
  );

  @override
  Duration get realDuration {
    _$realDurationAtom.reportRead();
    return super.realDuration;
  }

  @override
  set realDuration(Duration value) {
    _$realDurationAtom.reportWrite(value, super.realDuration, () {
      super.realDuration = value;
    });
  }

  late final _$musicDurationAtom = Atom(
    name: '_VideoPosterStore.musicDuration',
    context: context,
  );

  @override
  Duration get musicDuration {
    _$musicDurationAtom.reportRead();
    return super.musicDuration;
  }

  @override
  set musicDuration(Duration value) {
    _$musicDurationAtom.reportWrite(value, super.musicDuration, () {
      super.musicDuration = value;
    });
  }

  late final _$isPlayingAtom = Atom(
    name: '_VideoPosterStore.isPlaying',
    context: context,
  );

  @override
  bool get isPlaying {
    _$isPlayingAtom.reportRead();
    return super.isPlaying;
  }

  @override
  set isPlaying(bool value) {
    _$isPlayingAtom.reportWrite(value, super.isPlaying, () {
      super.isPlaying = value;
    });
  }

  late final _$isPreviewModeAtom = Atom(
    name: '_VideoPosterStore.isPreviewMode',
    context: context,
  );

  @override
  bool get isPreviewMode {
    _$isPreviewModeAtom.reportRead();
    return super.isPreviewMode;
  }

  @override
  set isPreviewMode(bool value) {
    _$isPreviewModeAtom.reportWrite(value, super.isPreviewMode, () {
      super.isPreviewMode = value;
    });
  }

  late final _$isMutedAtom = Atom(
    name: '_VideoPosterStore.isMuted',
    context: context,
  );

  @override
  bool get isMuted {
    _$isMutedAtom.reportRead();
    return super.isMuted;
  }

  @override
  set isMuted(bool value) {
    _$isMutedAtom.reportWrite(value, super.isMuted, () {
      super.isMuted = value;
    });
  }

  late final _$activeNavIndexAtom = Atom(
    name: '_VideoPosterStore.activeNavIndex',
    context: context,
  );

  @override
  int get activeNavIndex {
    _$activeNavIndexAtom.reportRead();
    return super.activeNavIndex;
  }

  @override
  set activeNavIndex(int value) {
    _$activeNavIndexAtom.reportWrite(value, super.activeNavIndex, () {
      super.activeNavIndex = value;
    });
  }

  late final _$toggleFavoriteAsyncAction = AsyncAction(
    '_VideoPosterStore.toggleFavorite',
    context: context,
  );

  @override
  Future<void> toggleFavorite(String url, {bool isGif = false}) {
    return _$toggleFavoriteAsyncAction.run(
      () => super.toggleFavorite(url, isGif: isGif),
    );
  }

  late final _$createBatchVideosAsyncAction = AsyncAction(
    '_VideoPosterStore.createBatchVideos',
    context: context,
  );

  @override
  Future<void> createBatchVideos() {
    return _$createBatchVideosAsyncAction.run(() => super.createBatchVideos());
  }

  late final _$exportImagePostersAsyncAction = AsyncAction(
    '_VideoPosterStore.exportImagePosters',
    context: context,
  );

  @override
  Future<void> exportImagePosters() {
    return _$exportImagePostersAsyncAction.run(
      () => super.exportImagePosters(),
    );
  }

  late final _$capturePreviewAsPngAsyncAction = AsyncAction(
    '_VideoPosterStore.capturePreviewAsPng',
    context: context,
  );

  @override
  Future<Uint8List> capturePreviewAsPng({bool hideImages = true}) {
    return _$capturePreviewAsPngAsyncAction.run(
      () => super.capturePreviewAsPng(hideImages: hideImages),
    );
  }

  late final _$_VideoPosterStoreActionController = ActionController(
    name: '_VideoPosterStore',
    context: context,
  );

  @override
  void _watchFavorites() {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore._watchFavorites',
    );
    try {
      return super._watchFavorites();
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void addSlide() {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.addSlide',
    );
    try {
      return super.addSlide();
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void selectSlide(int index) {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.selectSlide',
    );
    try {
      return super.selectSlide(index);
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void removeSlide(int index) {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.removeSlide',
    );
    try {
      return super.removeSlide(index);
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateSlideName(int index, String name) {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.updateSlideName',
    );
    try {
      return super.updateSlideName(index, name);
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void reorderSlides(int oldIndex, int newIndex) {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.reorderSlides',
    );
    try {
      return super.reorderSlides(oldIndex, newIndex);
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void addCustomImage(
    String imageUrl,
    double x,
    double y, {
    bool isGif = false,
  }) {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.addCustomImage',
    );
    try {
      return super.addCustomImage(imageUrl, x, y, isGif: isGif);
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void removeCustomImage(String id) {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.removeCustomImage',
    );
    try {
      return super.removeCustomImage(id);
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void selectCustomImage(String? id) {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.selectCustomImage',
    );
    try {
      return super.selectCustomImage(id);
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void reorderCustomImage(int oldIndex, int newIndex) {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.reorderCustomImage',
    );
    try {
      return super.reorderCustomImage(oldIndex, newIndex);
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateCustomImagePosition(String id, double x, double y) {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.updateCustomImagePosition',
    );
    try {
      return super.updateCustomImagePosition(id, x, y);
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateCustomImageSize(String id, double width, double height) {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.updateCustomImageSize',
    );
    try {
      return super.updateCustomImageSize(id, width, height);
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateCustomImageRotation(String id, double rotation) {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.updateCustomImageRotation',
    );
    try {
      return super.updateCustomImageRotation(id, rotation);
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateCustomImageTiming(
    String id, {
    double? startTime,
    double? endTime,
    bool clearEndTime = false,
  }) {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.updateCustomImageTiming',
    );
    try {
      return super.updateCustomImageTiming(
        id,
        startTime: startTime,
        endTime: endTime,
        clearEndTime: clearEndTime,
      );
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateCustomImageLocalPath(String id, String path) {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.updateCustomImageLocalPath',
    );
    try {
      return super.updateCustomImageLocalPath(id, path);
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateCustomImageBorder(
    String id, {
    ui.Color? color,
    bool clearBorderColor = false,
    double? width,
    double? borderRadius,
  }) {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.updateCustomImageBorder',
    );
    try {
      return super.updateCustomImageBorder(
        id,
        color: color,
        clearBorderColor: clearBorderColor,
        width: width,
        borderRadius: borderRadius,
      );
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void addCustomText() {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.addCustomText',
    );
    try {
      return super.addCustomText();
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void removeCustomText(String id) {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.removeCustomText',
    );
    try {
      return super.removeCustomText(id);
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void triggerPreviewAnimation(String id) {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.triggerPreviewAnimation',
    );
    try {
      return super.triggerPreviewAnimation(id);
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void triggerPreviewAnimationOut(String id) {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.triggerPreviewAnimationOut',
    );
    try {
      return super.triggerPreviewAnimationOut(id);
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void selectCustomText(String? id) {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.selectCustomText',
    );
    try {
      return super.selectCustomText(id);
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateCustomTextPosition(String id, double x, double y) {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.updateCustomTextPosition',
    );
    try {
      return super.updateCustomTextPosition(id, x, y);
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateCustomTextFontSize(String id, double size) {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.updateCustomTextFontSize',
    );
    try {
      return super.updateCustomTextFontSize(id, size);
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateCustomTextLabel(String id, String value) {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.updateCustomTextLabel',
    );
    try {
      return super.updateCustomTextLabel(id, value);
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateCustomTextStyle(
    String id, {
    ui.Color? color,
    ui.FontWeight? fontWeight,
    ui.FontStyle? fontStyle,
    ui.TextAlign? textAlign,
    ui.Color? backgroundColor,
    bool clearBackgroundColor = false,
    TextBackgroundStyle? backgroundStyle,
    double? backgroundOpacity,
    double? backgroundRadius,
    double? textHeight,
    bool clearTextHeight = false,
    String? fontFamily,
    double? rotation,
    double? letterSpacing,
    ui.Color? backgroundBorderColor,
    double? backgroundBorderWidth,
    bool clearBackgroundBorderColor = false,
    ui.Color? strokeColor,
    bool clearStrokeColor = false,
    double? strokeWidth,
    double? brushIntensity,
    double? brushThickness,
    double? brushComplexity,
  }) {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.updateCustomTextStyle',
    );
    try {
      return super.updateCustomTextStyle(
        id,
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
      );
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateCustomTextTiming(
    String id, {
    double? startTime,
    double? endTime,
    bool clearEndTime = false,
  }) {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.updateCustomTextTiming',
    );
    try {
      return super.updateCustomTextTiming(
        id,
        startTime: startTime,
        endTime: endTime,
        clearEndTime: clearEndTime,
      );
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateCustomTextAnimationIn(
    String id,
    TextAnimationType type,
    double duration,
  ) {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.updateCustomTextAnimationIn',
    );
    try {
      return super.updateCustomTextAnimationIn(id, type, duration);
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateCustomTextAnimationOut(
    String id,
    TextAnimationType type,
    double duration,
  ) {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.updateCustomTextAnimationOut',
    );
    try {
      return super.updateCustomTextAnimationOut(id, type, duration);
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setCustomAudioPath(String? path) {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.setCustomAudioPath',
    );
    try {
      return super.setCustomAudioPath(path);
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setCustomAudioVolume(double volume) {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.setCustomAudioVolume',
    );
    try {
      return super.setCustomAudioVolume(volume);
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setGenerateAmbientAudio(bool value) {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.setGenerateAmbientAudio',
    );
    try {
      return super.setGenerateAmbientAudio(value);
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setBatchOutputCount(int count) {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.setBatchOutputCount',
    );
    try {
      return super.setBatchOutputCount(count);
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void cancelBatchVideos() {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.cancelBatchVideos',
    );
    try {
      return super.cancelBatchVideos();
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleImagePosterMode() {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.toggleImagePosterMode',
    );
    try {
      return super.toggleImagePosterMode();
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void randomizePreviewFrame() {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.randomizePreviewFrame',
    );
    try {
      return super.randomizePreviewFrame();
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleMute() {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.toggleMute',
    );
    try {
      return super.toggleMute();
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void togglePreviewMode() {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.togglePreviewMode',
    );
    try {
      return super.togglePreviewMode();
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void addSourceVideos(List<String> paths) {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.addSourceVideos',
    );
    try {
      return super.addSourceVideos(paths);
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void removeSourceVideo(int index) {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.removeSourceVideo',
    );
    try {
      return super.removeSourceVideo(index);
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void initializePlayer() {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.initializePlayer',
    );
    try {
      return super.initializePlayer();
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void seekProject(Duration p) {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.seekProject',
    );
    try {
      return super.seekProject(p);
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void disposePlayer() {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.disposePlayer',
    );
    try {
      return super.disposePlayer();
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void resetProject() {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.resetProject',
    );
    try {
      return super.resetProject();
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setActiveNavIndex(int index) {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.setActiveNavIndex',
    );
    try {
      return super.setActiveNavIndex(index);
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void playVideoAtIndex(int index) {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.playVideoAtIndex',
    );
    try {
      return super.playVideoAtIndex(index);
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
favoriteImages: ${favoriteImages},
isLoadingFavorites: ${isLoadingFavorites},
sourceVideoPaths: ${sourceVideoPaths},
currentVideoIndex: ${currentVideoIndex},
customTexts: ${customTexts},
customImages: ${customImages},
selectedCustomImageId: ${selectedCustomImageId},
slides: ${slides},
currentSlideIndex: ${currentSlideIndex},
recentTextColors: ${recentTextColors},
recentBgColors: ${recentBgColors},
recentStrokeColors: ${recentStrokeColors},
recentBorderColors: ${recentBorderColors},
isHidingImagesForCapture: ${isHidingImagesForCapture},
isHidingAnimatedTextsForCapture: ${isHidingAnimatedTextsForCapture},
selectedCustomTextId: ${selectedCustomTextId},
animationPreviewCounters: ${animationPreviewCounters},
animationOutPreviewCounters: ${animationOutPreviewCounters},
batchOutputCount: ${batchOutputCount},
isBatchCreating: ${isBatchCreating},
batchLogs: ${batchLogs},
batchOutputDir: ${batchOutputDir},
customAudioPath: ${customAudioPath},
customAudioVolume: ${customAudioVolume},
generateAmbientAudio: ${generateAmbientAudio},
isExportingImages: ${isExportingImages},
isImagePosterMode: ${isImagePosterMode},
playbackSpeed: ${playbackSpeed},
duration: ${duration},
position: ${position},
realDuration: ${realDuration},
musicDuration: ${musicDuration},
isPlaying: ${isPlaying},
isPreviewMode: ${isPreviewMode},
isMuted: ${isMuted},
activeNavIndex: ${activeNavIndex}
    ''';
  }
}
