// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_poster_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$VideoPosterStore on _VideoPosterStore, Store {
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

  late final _$createBatchVideosAsyncAction = AsyncAction(
    '_VideoPosterStore.createBatchVideos',
    context: context,
  );

  @override
  Future<void> createBatchVideos() {
    return _$createBatchVideosAsyncAction.run(() => super.createBatchVideos());
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

  late final _$_VideoPosterStoreActionController = ActionController(
    name: '_VideoPosterStore',
    context: context,
  );

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
    String? fontFamily,
    double? rotation,
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
        fontFamily: fontFamily,
        rotation: rotation,
      );
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
sourceVideoPaths: ${sourceVideoPaths},
currentVideoIndex: ${currentVideoIndex},
customTexts: ${customTexts},
customImages: ${customImages},
selectedCustomImageId: ${selectedCustomImageId},
recentTextColors: ${recentTextColors},
recentBgColors: ${recentBgColors},
selectedCustomTextId: ${selectedCustomTextId},
batchOutputCount: ${batchOutputCount},
isBatchCreating: ${isBatchCreating},
batchLogs: ${batchLogs},
batchOutputDir: ${batchOutputDir},
playbackSpeed: ${playbackSpeed},
duration: ${duration},
position: ${position},
isPlaying: ${isPlaying},
activeNavIndex: ${activeNavIndex}
    ''';
  }
}
