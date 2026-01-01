// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mirroring_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$MirroringStore on _MirroringStore, Store {
  Computed<bool>? _$isFloatingVisibleComputed;

  @override
  bool get isFloatingVisible => (_$isFloatingVisibleComputed ??= Computed<bool>(
    () => super.isFloatingVisible,
    name: '_MirroringStore.isFloatingVisible',
  )).value;

  late final _$activeSessionsAtom = Atom(
    name: '_MirroringStore.activeSessions',
    context: context,
  );

  @override
  ObservableMap<String, MirrorSession> get activeSessions {
    _$activeSessionsAtom.reportRead();
    return super.activeSessions;
  }

  @override
  set activeSessions(ObservableMap<String, MirrorSession> value) {
    _$activeSessionsAtom.reportWrite(value, super.activeSessions, () {
      super.activeSessions = value;
    });
  }

  late final _$visibleGridSerialsAtom = Atom(
    name: '_MirroringStore.visibleGridSerials',
    context: context,
  );

  @override
  ObservableSet<String> get visibleGridSerials {
    _$visibleGridSerialsAtom.reportRead();
    return super.visibleGridSerials;
  }

  @override
  set visibleGridSerials(ObservableSet<String> value) {
    _$visibleGridSerialsAtom.reportWrite(value, super.visibleGridSerials, () {
      super.visibleGridSerials = value;
    });
  }

  late final _$visibleFloatingSerialsAtom = Atom(
    name: '_MirroringStore.visibleFloatingSerials',
    context: context,
  );

  @override
  ObservableSet<String> get visibleFloatingSerials {
    _$visibleFloatingSerialsAtom.reportRead();
    return super.visibleFloatingSerials;
  }

  @override
  set visibleFloatingSerials(ObservableSet<String> value) {
    _$visibleFloatingSerialsAtom.reportWrite(
      value,
      super.visibleFloatingSerials,
      () {
        super.visibleFloatingSerials = value;
      },
    );
  }

  late final _$isLoadingMirroringAtom = Atom(
    name: '_MirroringStore.isLoadingMirroring',
    context: context,
  );

  @override
  ObservableMap<String, bool> get isLoadingMirroring {
    _$isLoadingMirroringAtom.reportRead();
    return super.isLoadingMirroring;
  }

  @override
  set isLoadingMirroring(ObservableMap<String, bool> value) {
    _$isLoadingMirroringAtom.reportWrite(value, super.isLoadingMirroring, () {
      super.isLoadingMirroring = value;
    });
  }

  late final _$errorMessagesAtom = Atom(
    name: '_MirroringStore.errorMessages',
    context: context,
  );

  @override
  ObservableMap<String, String?> get errorMessages {
    _$errorMessagesAtom.reportRead();
    return super.errorMessages;
  }

  @override
  set errorMessages(ObservableMap<String, String?> value) {
    _$errorMessagesAtom.reportWrite(value, super.errorMessages, () {
      super.errorMessages = value;
    });
  }

  late final _$lostConnectionSerialsAtom = Atom(
    name: '_MirroringStore.lostConnectionSerials',
    context: context,
  );

  @override
  ObservableMap<String, bool> get lostConnectionSerials {
    _$lostConnectionSerialsAtom.reportRead();
    return super.lostConnectionSerials;
  }

  @override
  set lostConnectionSerials(ObservableMap<String, bool> value) {
    _$lostConnectionSerialsAtom.reportWrite(
      value,
      super.lostConnectionSerials,
      () {
        super.lostConnectionSerials = value;
      },
    );
  }

  late final _$isConnectingAtom = Atom(
    name: '_MirroringStore.isConnecting',
    context: context,
  );

  @override
  ObservableMap<String, bool> get isConnecting {
    _$isConnectingAtom.reportRead();
    return super.isConnecting;
  }

  @override
  set isConnecting(ObservableMap<String, bool> value) {
    _$isConnectingAtom.reportWrite(value, super.isConnecting, () {
      super.isConnecting = value;
    });
  }

  late final _$isPushingFileAtom = Atom(
    name: '_MirroringStore.isPushingFile',
    context: context,
  );

  @override
  ObservableMap<String, bool> get isPushingFile {
    _$isPushingFileAtom.reportRead();
    return super.isPushingFile;
  }

  @override
  set isPushingFile(ObservableMap<String, bool> value) {
    _$isPushingFileAtom.reportWrite(value, super.isPushingFile, () {
      super.isPushingFile = value;
    });
  }

  late final _$isDraggingFileAtom = Atom(
    name: '_MirroringStore.isDraggingFile',
    context: context,
  );

  @override
  ObservableMap<String, bool> get isDraggingFile {
    _$isDraggingFileAtom.reportRead();
    return super.isDraggingFile;
  }

  @override
  set isDraggingFile(ObservableMap<String, bool> value) {
    _$isDraggingFileAtom.reportWrite(value, super.isDraggingFile, () {
      super.isDraggingFile = value;
    });
  }

  late final _$lastTapTimesAtom = Atom(
    name: '_MirroringStore.lastTapTimes',
    context: context,
  );

  @override
  ObservableMap<String, DateTime> get lastTapTimes {
    _$lastTapTimesAtom.reportRead();
    return super.lastTapTimes;
  }

  @override
  set lastTapTimes(ObservableMap<String, DateTime> value) {
    _$lastTapTimesAtom.reportWrite(value, super.lastTapTimes, () {
      super.lastTapTimes = value;
    });
  }

  late final _$floatingSerialAtom = Atom(
    name: '_MirroringStore.floatingSerial',
    context: context,
  );

  @override
  String? get floatingSerial {
    _$floatingSerialAtom.reportRead();
    return super.floatingSerial;
  }

  @override
  set floatingSerial(String? value) {
    _$floatingSerialAtom.reportWrite(value, super.floatingSerial, () {
      super.floatingSerial = value;
    });
  }

  late final _$startMirroringAsyncAction = AsyncAction(
    '_MirroringStore.startMirroring',
    context: context,
  );

  @override
  Future<MirrorSession> startMirroring(
    String serial, [
    ScrcpyOptions? options,
  ]) {
    return _$startMirroringAsyncAction.run(
      () => super.startMirroring(serial, options),
    );
  }

  late final _$stopMirroringAsyncAction = AsyncAction(
    '_MirroringStore.stopMirroring',
    context: context,
  );

  @override
  Future<void> stopMirroring(String serial) {
    return _$stopMirroringAsyncAction.run(() => super.stopMirroring(serial));
  }

  late final _$handlePasteAsyncAction = AsyncAction(
    '_MirroringStore.handlePaste',
    context: context,
  );

  @override
  Future<void> handlePaste(String serial) {
    return _$handlePasteAsyncAction.run(() => super.handlePaste(serial));
  }

  late final _$uploadFilesAsyncAction = AsyncAction(
    '_MirroringStore.uploadFiles',
    context: context,
  );

  @override
  Future<void> uploadFiles(String serial, List<String> paths) {
    return _$uploadFilesAsyncAction.run(() => super.uploadFiles(serial, paths));
  }

  late final _$_MirroringStoreActionController = ActionController(
    name: '_MirroringStore',
    context: context,
  );

  @override
  void toggleFloating(String? serial) {
    final _$actionInfo = _$_MirroringStoreActionController.startAction(
      name: '_MirroringStore.toggleFloating',
    );
    try {
      return super.toggleFloating(serial);
    } finally {
      _$_MirroringStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setVisibility(String serial, bool isVisible, {bool isFloating = false}) {
    final _$actionInfo = _$_MirroringStoreActionController.startAction(
      name: '_MirroringStore.setVisibility',
    );
    try {
      return super.setVisibility(serial, isVisible, isFloating: isFloating);
    } finally {
      _$_MirroringStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setDecoderError(String serial, String error) {
    final _$actionInfo = _$_MirroringStoreActionController.startAction(
      name: '_MirroringStore.setDecoderError',
    );
    try {
      return super.setDecoderError(serial, error);
    } finally {
      _$_MirroringStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void handlePointerEvent(
    String serial,
    PointerEvent event,
    int action,
    int nativeWidth,
    int nativeHeight,
  ) {
    final _$actionInfo = _$_MirroringStoreActionController.startAction(
      name: '_MirroringStore.handlePointerEvent',
    );
    try {
      return super.handlePointerEvent(
        serial,
        event,
        action,
        nativeWidth,
        nativeHeight,
      );
    } finally {
      _$_MirroringStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void handleScrollEvent(
    String serial,
    PointerScrollEvent event,
    int nativeWidth,
    int nativeHeight,
  ) {
    final _$actionInfo = _$_MirroringStoreActionController.startAction(
      name: '_MirroringStore.handleScrollEvent',
    );
    try {
      return super.handleScrollEvent(serial, event, nativeWidth, nativeHeight);
    } finally {
      _$_MirroringStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void handleKeyboardEvent(String serial, KeyEvent event) {
    final _$actionInfo = _$_MirroringStoreActionController.startAction(
      name: '_MirroringStore.handleKeyboardEvent',
    );
    try {
      return super.handleKeyboardEvent(serial, event);
    } finally {
      _$_MirroringStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setDragging(String serial, bool isDragging) {
    final _$actionInfo = _$_MirroringStoreActionController.startAction(
      name: '_MirroringStore.setDragging',
    );
    try {
      return super.setDragging(serial, isDragging);
    } finally {
      _$_MirroringStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  bool checkDoubleTap(String serial) {
    final _$actionInfo = _$_MirroringStoreActionController.startAction(
      name: '_MirroringStore.checkDoubleTap',
    );
    try {
      return super.checkDoubleTap(serial);
    } finally {
      _$_MirroringStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
activeSessions: ${activeSessions},
visibleGridSerials: ${visibleGridSerials},
visibleFloatingSerials: ${visibleFloatingSerials},
isLoadingMirroring: ${isLoadingMirroring},
errorMessages: ${errorMessages},
lostConnectionSerials: ${lostConnectionSerials},
isConnecting: ${isConnecting},
isPushingFile: ${isPushingFile},
isDraggingFile: ${isDraggingFile},
lastTapTimes: ${lastTapTimes},
floatingSerial: ${floatingSerial},
isFloatingVisible: ${isFloatingVisible}
    ''';
  }
}
