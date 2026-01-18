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

  late final _$selectedPosterDataAtom = Atom(
    name: '_VideoPosterStore.selectedPosterData',
    context: context,
  );

  @override
  PosterData? get selectedPosterData {
    _$selectedPosterDataAtom.reportRead();
    return super.selectedPosterData;
  }

  @override
  set selectedPosterData(PosterData? value) {
    _$selectedPosterDataAtom.reportWrite(value, super.selectedPosterData, () {
      super.selectedPosterData = value;
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

  late final _$generateVideoAsyncAction = AsyncAction(
    '_VideoPosterStore.generateVideo',
    context: context,
  );

  @override
  Future<void> generateVideo() {
    return _$generateVideoAsyncAction.run(() => super.generateVideo());
  }

  late final _$_VideoPosterStoreActionController = ActionController(
    name: '_VideoPosterStore',
    context: context,
  );

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
  void duplicateSourceVideo(String path) {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.duplicateSourceVideo',
    );
    try {
      return super.duplicateSourceVideo(path);
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
  void selectPosterData(PosterData data) {
    final _$actionInfo = _$_VideoPosterStoreActionController.startAction(
      name: '_VideoPosterStore.selectPosterData',
    );
    try {
      return super.selectPosterData(data);
    } finally {
      _$_VideoPosterStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
sourceVideoPaths: ${sourceVideoPaths},
selectedPosterData: ${selectedPosterData},
isProcessing: ${isProcessing},
generatedVideoPath: ${generatedVideoPath},
errorMessage: ${errorMessage}
    ''';
  }
}
