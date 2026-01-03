// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'phone_view_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$PhoneViewStore on _PhoneViewStore, Store {
  Computed<MirrorSession?>? _$sessionComputed;

  @override
  MirrorSession? get session => (_$sessionComputed ??= Computed<MirrorSession?>(
    () => super.session,
    name: '_PhoneViewStore.session',
  )).value;
  Computed<bool>? _$isFloatingComputed;

  @override
  bool get isFloating => (_$isFloatingComputed ??= Computed<bool>(
    () => super.isFloating,
    name: '_PhoneViewStore.isFloating',
  )).value;
  Computed<String?>? _$floatingSerialComputed;

  @override
  String? get floatingSerial => (_$floatingSerialComputed ??= Computed<String?>(
    () => super.floatingSerial,
    name: '_PhoneViewStore.floatingSerial',
  )).value;
  Computed<bool>? _$isFloatingVisibleComputed;

  @override
  bool get isFloatingVisible => (_$isFloatingVisibleComputed ??= Computed<bool>(
    () => super.isFloatingVisible,
    name: '_PhoneViewStore.isFloatingVisible',
  )).value;

  late final _$isLoadingAtom = Atom(
    name: '_PhoneViewStore.isLoading',
    context: context,
  );

  @override
  bool get isLoading {
    _$isLoadingAtom.reportRead();
    return super.isLoading;
  }

  @override
  set isLoading(bool value) {
    _$isLoadingAtom.reportWrite(value, super.isLoading, () {
      super.isLoading = value;
    });
  }

  late final _$isConnectingAtom = Atom(
    name: '_PhoneViewStore.isConnecting',
    context: context,
  );

  @override
  bool get isConnecting {
    _$isConnectingAtom.reportRead();
    return super.isConnecting;
  }

  @override
  set isConnecting(bool value) {
    _$isConnectingAtom.reportWrite(value, super.isConnecting, () {
      super.isConnecting = value;
    });
  }

  late final _$isPushingFileAtom = Atom(
    name: '_PhoneViewStore.isPushingFile',
    context: context,
  );

  @override
  bool get isPushingFile {
    _$isPushingFileAtom.reportRead();
    return super.isPushingFile;
  }

  @override
  set isPushingFile(bool value) {
    _$isPushingFileAtom.reportWrite(value, super.isPushingFile, () {
      super.isPushingFile = value;
    });
  }

  late final _$isDraggingFileAtom = Atom(
    name: '_PhoneViewStore.isDraggingFile',
    context: context,
  );

  @override
  bool get isDraggingFile {
    _$isDraggingFileAtom.reportRead();
    return super.isDraggingFile;
  }

  @override
  set isDraggingFile(bool value) {
    _$isDraggingFileAtom.reportWrite(value, super.isDraggingFile, () {
      super.isDraggingFile = value;
    });
  }

  late final _$errorAtom = Atom(
    name: '_PhoneViewStore.error',
    context: context,
  );

  @override
  String? get error {
    _$errorAtom.reportRead();
    return super.error;
  }

  @override
  set error(String? value) {
    _$errorAtom.reportWrite(value, super.error, () {
      super.error = value;
    });
  }

  late final _$hasLostConnectionAtom = Atom(
    name: '_PhoneViewStore.hasLostConnection',
    context: context,
  );

  @override
  bool get hasLostConnection {
    _$hasLostConnectionAtom.reportRead();
    return super.hasLostConnection;
  }

  @override
  set hasLostConnection(bool value) {
    _$hasLostConnectionAtom.reportWrite(value, super.hasLostConnection, () {
      super.hasLostConnection = value;
    });
  }

  late final _$lastTapTimesAtom = Atom(
    name: '_PhoneViewStore.lastTapTimes',
    context: context,
  );

  @override
  DateTime? get lastTapTimes {
    _$lastTapTimesAtom.reportRead();
    return super.lastTapTimes;
  }

  @override
  set lastTapTimes(DateTime? value) {
    _$lastTapTimesAtom.reportWrite(value, super.lastTapTimes, () {
      super.lastTapTimes = value;
    });
  }

  late final _$_isVisibleAtom = Atom(
    name: '_PhoneViewStore._isVisible',
    context: context,
  );

  bool get isVisible {
    _$_isVisibleAtom.reportRead();
    return super._isVisible;
  }

  @override
  bool get _isVisible => isVisible;

  @override
  set _isVisible(bool value) {
    _$_isVisibleAtom.reportWrite(value, super._isVisible, () {
      super._isVisible = value;
    });
  }

  late final _$startMirroringAsyncAction = AsyncAction(
    '_PhoneViewStore.startMirroring',
    context: context,
  );

  @override
  Future<MirrorSession> startMirroring([ScrcpyOptions? options]) {
    return _$startMirroringAsyncAction.run(() => super.startMirroring(options));
  }

  late final _$stopMirroringAsyncAction = AsyncAction(
    '_PhoneViewStore.stopMirroring',
    context: context,
  );

  @override
  Future<void> stopMirroring() {
    return _$stopMirroringAsyncAction.run(() => super.stopMirroring());
  }

  late final _$handlePasteAsyncAction = AsyncAction(
    '_PhoneViewStore.handlePaste',
    context: context,
  );

  @override
  Future<void> handlePaste(String serial) {
    return _$handlePasteAsyncAction.run(() => super.handlePaste(serial));
  }

  late final _$uploadFilesAsyncAction = AsyncAction(
    '_PhoneViewStore.uploadFiles',
    context: context,
  );

  @override
  Future<void> uploadFiles(String serial, List<String> paths) {
    return _$uploadFilesAsyncAction.run(() => super.uploadFiles(serial, paths));
  }

  late final _$_PhoneViewStoreActionController = ActionController(
    name: '_PhoneViewStore',
    context: context,
  );

  @override
  void toggleFloating(String? serial) {
    final _$actionInfo = _$_PhoneViewStoreActionController.startAction(
      name: '_PhoneViewStore.toggleFloating',
    );
    try {
      return super.toggleFloating(serial);
    } finally {
      _$_PhoneViewStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setVisibility(String serial, bool isVisible, {bool isFloating = false}) {
    final _$actionInfo = _$_PhoneViewStoreActionController.startAction(
      name: '_PhoneViewStore.setVisibility',
    );
    try {
      return super.setVisibility(serial, isVisible, isFloating: isFloating);
    } finally {
      _$_PhoneViewStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setDecoderError(String serial, String error) {
    final _$actionInfo = _$_PhoneViewStoreActionController.startAction(
      name: '_PhoneViewStore.setDecoderError',
    );
    try {
      return super.setDecoderError(serial, error);
    } finally {
      _$_PhoneViewStoreActionController.endAction(_$actionInfo);
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
    final _$actionInfo = _$_PhoneViewStoreActionController.startAction(
      name: '_PhoneViewStore.handlePointerEvent',
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
      _$_PhoneViewStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void handleScrollEvent(
    String serial,
    PointerScrollEvent event,
    int nativeWidth,
    int nativeHeight,
  ) {
    final _$actionInfo = _$_PhoneViewStoreActionController.startAction(
      name: '_PhoneViewStore.handleScrollEvent',
    );
    try {
      return super.handleScrollEvent(serial, event, nativeWidth, nativeHeight);
    } finally {
      _$_PhoneViewStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void handleKeyboardEvent(String serial, KeyEvent event) {
    final _$actionInfo = _$_PhoneViewStoreActionController.startAction(
      name: '_PhoneViewStore.handleKeyboardEvent',
    );
    try {
      return super.handleKeyboardEvent(serial, event);
    } finally {
      _$_PhoneViewStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setDragging(String serial, bool isDragging) {
    final _$actionInfo = _$_PhoneViewStoreActionController.startAction(
      name: '_PhoneViewStore.setDragging',
    );
    try {
      return super.setDragging(serial, isDragging);
    } finally {
      _$_PhoneViewStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  bool checkDoubleTap(String serial) {
    final _$actionInfo = _$_PhoneViewStoreActionController.startAction(
      name: '_PhoneViewStore.checkDoubleTap',
    );
    try {
      return super.checkDoubleTap(serial);
    } finally {
      _$_PhoneViewStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
isLoading: ${isLoading},
isConnecting: ${isConnecting},
isPushingFile: ${isPushingFile},
isDraggingFile: ${isDraggingFile},
error: ${error},
hasLostConnection: ${hasLostConnection},
lastTapTimes: ${lastTapTimes},
session: ${session},
isFloating: ${isFloating},
floatingSerial: ${floatingSerial},
isFloatingVisible: ${isFloatingVisible}
    ''';
  }
}
