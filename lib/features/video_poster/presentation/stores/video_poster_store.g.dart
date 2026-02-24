// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_poster_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$VideoPosterStore on _VideoPosterStore, Store {
  Computed<Duration>? _$totalDurationComputed;

  @override
  Duration get totalDuration => (_$totalDurationComputed ??= Computed<Duration>(
    () => super.totalDuration,
    name: '_VideoPosterStore.totalDuration',
  )).value;
  Computed<Duration>? _$totalPositionComputed;

  @override
  Duration get totalPosition => (_$totalPositionComputed ??= Computed<Duration>(
    () => super.totalPosition,
    name: '_VideoPosterStore.totalPosition',
  )).value;

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

  late final _$isProcessingAtom = Atom(
    name: '_VideoPosterStore.isProcessing',
    context: context,
  );

  @override
  bool get isProcessing {
    _$isProcessingAtom.reportRead();
    return super.isProcessing;
  }

  @override
  set isProcessing(bool value) {
    _$isProcessingAtom.reportWrite(value, super.isProcessing, () {
      super.isProcessing = value;
    });
  }

  late final _$generatedVideoPathAtom = Atom(
    name: '_VideoPosterStore.generatedVideoPath',
    context: context,
  );

  @override
  String? get generatedVideoPath {
    _$generatedVideoPathAtom.reportRead();
    return super.generatedVideoPath;
  }

  @override
  set generatedVideoPath(String? value) {
    _$generatedVideoPathAtom.reportWrite(value, super.generatedVideoPath, () {
      super.generatedVideoPath = value;
    });
  }

  late final _$errorMessageAtom = Atom(
    name: '_VideoPosterStore.errorMessage',
    context: context,
  );

  @override
  String? get errorMessage {
    _$errorMessageAtom.reportRead();
    return super.errorMessage;
  }

  @override
  set errorMessage(String? value) {
    _$errorMessageAtom.reportWrite(value, super.errorMessage, () {
      super.errorMessage = value;
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

  late final _$saturationAtom = Atom(
    name: '_VideoPosterStore.saturation',
    context: context,
  );

  @override
  double get saturation {
    _$saturationAtom.reportRead();
    return super.saturation;
  }

  @override
  set saturation(double value) {
    _$saturationAtom.reportWrite(value, super.saturation, () {
      super.saturation = value;
    });
  }

  late final _$contrastAtom = Atom(
    name: '_VideoPosterStore.contrast',
    context: context,
  );

  @override
  double get contrast {
    _$contrastAtom.reportRead();
    return super.contrast;
  }

  @override
  set contrast(double value) {
    _$contrastAtom.reportWrite(value, super.contrast, () {
      super.contrast = value;
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

  late final _$zoomIntensityAtom = Atom(
    name: '_VideoPosterStore.zoomIntensity',
    context: context,
  );

  @override
  double get zoomIntensity {
    _$zoomIntensityAtom.reportRead();
    return super.zoomIntensity;
  }

  @override
  set zoomIntensity(double value) {
    _$zoomIntensityAtom.reportWrite(value, super.zoomIntensity, () {
      super.zoomIntensity = value;
    });
  }

  late final _$volumeAtom = Atom(
    name: '_VideoPosterStore.volume',
    context: context,
  );

  @override
  double get volume {
    _$volumeAtom.reportRead();
    return super.volume;
  }

  @override
  set volume(double value) {
    _$volumeAtom.reportWrite(value, super.volume, () {
      super.volume = value;
    });
  }

  late final _$applyBlurAtom = Atom(
    name: '_VideoPosterStore.applyBlur',
    context: context,
  );

  @override
  bool get applyBlur {
    _$applyBlurAtom.reportRead();
    return super.applyBlur;
  }

  @override
  set applyBlur(bool value) {
    _$applyBlurAtom.reportWrite(value, super.applyBlur, () {
      super.applyBlur = value;
    });
  }

  late final _$blurIntensityAtom = Atom(
    name: '_VideoPosterStore.blurIntensity',
    context: context,
  );

  @override
  double get blurIntensity {
    _$blurIntensityAtom.reportRead();
    return super.blurIntensity;
  }

  @override
  set blurIntensity(double value) {
    _$blurIntensityAtom.reportWrite(value, super.blurIntensity, () {
      super.blurIntensity = value;
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

  late final _$clipDurationsAtom = Atom(
    name: '_VideoPosterStore.clipDurations',
    context: context,
  );

  @override
  ObservableList<Duration> get clipDurations {
    _$clipDurationsAtom.reportRead();
    return super.clipDurations;
  }

  @override
  set clipDurations(ObservableList<Duration> value) {
    _$clipDurationsAtom.reportWrite(value, super.clipDurations, () {
      super.clipDurations = value;
    });
  }

  late final _$currentPlaylistIndexAtom = Atom(
    name: '_VideoPosterStore.currentPlaylistIndex',
    context: context,
  );

  @override
  int get currentPlaylistIndex {
    _$currentPlaylistIndexAtom.reportRead();
    return super.currentPlaylistIndex;
  }

  @override
  set currentPlaylistIndex(int value) {
    _$currentPlaylistIndexAtom.reportWrite(
      value,
      super.currentPlaylistIndex,
      () {
        super.currentPlaylistIndex = value;
      },
    );
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

  late final _$videoWidthAtom = Atom(
    name: '_VideoPosterStore.videoWidth',
    context: context,
  );

  @override
  int get videoWidth {
    _$videoWidthAtom.reportRead();
    return super.videoWidth;
  }

  @override
  set videoWidth(int value) {
    _$videoWidthAtom.reportWrite(value, super.videoWidth, () {
      super.videoWidth = value;
    });
  }

  late final _$videoHeightAtom = Atom(
    name: '_VideoPosterStore.videoHeight',
    context: context,
  );

  @override
  int get videoHeight {
    _$videoHeightAtom.reportRead();
    return super.videoHeight;
  }

  @override
  set videoHeight(int value) {
    _$videoHeightAtom.reportWrite(value, super.videoHeight, () {
      super.videoHeight = value;
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

  late final _$isFocusModeAtom = Atom(
    name: '_VideoPosterStore.isFocusMode',
    context: context,
  );

  @override
  bool get isFocusMode {
    _$isFocusModeAtom.reportRead();
    return super.isFocusMode;
  }

  @override
  set isFocusMode(bool value) {
    _$isFocusModeAtom.reportWrite(value, super.isFocusMode, () {
      super.isFocusMode = value;
    });
  }

  late final _$thumbnailsAtom = Atom(
    name: '_VideoPosterStore.thumbnails',
    context: context,
  );

  @override
  ObservableMap<String, String> get thumbnails {
    _$thumbnailsAtom.reportRead();
    return super.thumbnails;
  }

  @override
  set thumbnails(ObservableMap<String, String> value) {
    _$thumbnailsAtom.reportWrite(value, super.thumbnails, () {
      super.thumbnails = value;
    });
  }

  late final _$antiReupConfigAtom = Atom(
    name: '_VideoPosterStore.antiReupConfig',
    context: context,
  );

  @override
  AntiReupConfig get antiReupConfig {
    _$antiReupConfigAtom.reportRead();
    return super.antiReupConfig;
  }

  @override
  set antiReupConfig(AntiReupConfig value) {
    _$antiReupConfigAtom.reportWrite(value, super.antiReupConfig, () {
      super.antiReupConfig = value;
    });
  }

  late final _$capturePreviewAsPngAsyncAction = AsyncAction(
    '_VideoPosterStore.capturePreviewAsPng',
    context: context,
  );

  @override
  Future<Uint8List> capturePreviewAsPng() {
    return _$capturePreviewAsPngAsyncAction.run(
      () => super.capturePreviewAsPng(),
    );
  }

  late final _$seekTimelineAsyncAction = AsyncAction(
    '_VideoPosterStore.seekTimeline',
    context: context,
  );

  @override
  Future<void> seekTimeline(Duration target) {
    return _$seekTimelineAsyncAction.run(() => super.seekTimeline(target));
  }

  late final _$handleExportVideoAsyncAction = AsyncAction(
    '_VideoPosterStore.handleExportVideo',
    context: context,
  );

  @override
  Future<void> handleExportVideo() {
    return _$handleExportVideoAsyncAction.run(() => super.handleExportVideo());
  }

  late final _$generateVideoWithOverlayAsyncAction = AsyncAction(
    '_VideoPosterStore.generateVideoWithOverlay',
    context: context,
  );

  @override
  Future<void> generateVideoWithOverlay(Uint8List overlayPng) {
    return _$generateVideoWithOverlayAsyncAction.run(
      () => super.generateVideoWithOverlay(overlayPng),
    );
  }

  late final _$_VideoPosterStoreActionController = ActionController(
    name: '_VideoPosterStore',
    context: context,
  );

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
    double? backgroundOpacity,
    double? backgroundRadius,
    double? textHeight,
    bool clearTextHeight = false,
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
        backgroundOpacity: backgroundOpacity,
        backgroundRadius: backgroundRadius,
        textHeight: textHeight,
        clearTextHeight: clearTextHeight,
      );
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
  void toggleBlur(bool value) {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.toggleBlur',
    );
    try {
      return super.toggleBlur(value);
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setPlaybackSpeed(double value) {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.setPlaybackSpeed',
    );
    try {
      return super.setPlaybackSpeed(value);
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setVolume(double value) {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.setVolume',
    );
    try {
      return super.setVolume(value);
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setApplyBlur(bool value) {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.setApplyBlur',
    );
    try {
      return super.setApplyBlur(value);
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setBlurIntensity(double value) {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.setBlurIntensity',
    );
    try {
      return super.setBlurIntensity(value);
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
  void toggleFocusMode() {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.toggleFocusMode',
    );
    try {
      return super.toggleFocusMode();
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateEffect(String type, double value) {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.updateEffect',
    );
    try {
      return super.updateEffect(type, value);
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleRandomizeAntiReup(bool value) {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.toggleRandomizeAntiReup',
    );
    try {
      return super.toggleRandomizeAntiReup(value);
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateAntiReupConfig(AntiReupConfig config) {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.updateAntiReupConfig',
    );
    try {
      return super.updateAntiReupConfig(config);
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void syncPlaylist() {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.syncPlaylist',
    );
    try {
      return super.syncPlaylist();
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
  void playVideo(String path) {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.playVideo',
    );
    try {
      return super.playVideo(path);
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
sourceVideoPaths: ${sourceVideoPaths},
isProcessing: ${isProcessing},
generatedVideoPath: ${generatedVideoPath},
errorMessage: ${errorMessage},
customTexts: ${customTexts},
selectedCustomTextId: ${selectedCustomTextId},
saturation: ${saturation},
contrast: ${contrast},
playbackSpeed: ${playbackSpeed},
zoomIntensity: ${zoomIntensity},
volume: ${volume},
applyBlur: ${applyBlur},
blurIntensity: ${blurIntensity},
duration: ${duration},
position: ${position},
clipDurations: ${clipDurations},
currentPlaylistIndex: ${currentPlaylistIndex},
isPlaying: ${isPlaying},
videoWidth: ${videoWidth},
videoHeight: ${videoHeight},
activeNavIndex: ${activeNavIndex},
isFocusMode: ${isFocusMode},
thumbnails: ${thumbnails},
antiReupConfig: ${antiReupConfig},
totalDuration: ${totalDuration},
totalPosition: ${totalPosition}
    ''';
  }
}
