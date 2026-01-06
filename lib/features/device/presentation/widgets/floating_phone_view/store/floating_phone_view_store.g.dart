// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'floating_phone_view_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$FloatingPhoneViewStore on _FloatingPhoneViewStore, Store {
  late final _$positionAtom = Atom(
    name: '_FloatingPhoneViewStore.position',
    context: context,
  );

  @override
  Offset get position {
    _$positionAtom.reportRead();
    return super.position;
  }

  @override
  set position(Offset value) {
    _$positionAtom.reportWrite(value, super.position, () {
      super.position = value;
    });
  }

  late final _$widthAtom = Atom(
    name: '_FloatingPhoneViewStore.width',
    context: context,
  );

  @override
  double get width {
    _$widthAtom.reportRead();
    return super.width;
  }

  @override
  set width(double value) {
    _$widthAtom.reportWrite(value, super.width, () {
      super.width = value;
    });
  }

  late final _$heightAtom = Atom(
    name: '_FloatingPhoneViewStore.height',
    context: context,
  );

  @override
  double get height {
    _$heightAtom.reportRead();
    return super.height;
  }

  @override
  set height(double value) {
    _$heightAtom.reportWrite(value, super.height, () {
      super.height = value;
    });
  }

  late final _$isGeneratingPosterAtom = Atom(
    name: '_FloatingPhoneViewStore.isGeneratingPoster',
    context: context,
  );

  @override
  bool get isGeneratingPoster {
    _$isGeneratingPosterAtom.reportRead();
    return super.isGeneratingPoster;
  }

  @override
  set isGeneratingPoster(bool value) {
    _$isGeneratingPosterAtom.reportWrite(value, super.isGeneratingPoster, () {
      super.isGeneratingPoster = value;
    });
  }

  late final _$selectedPosterDataAtom = Atom(
    name: '_FloatingPhoneViewStore.selectedPosterData',
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

  late final _$_FloatingPhoneViewStoreActionController = ActionController(
    name: '_FloatingPhoneViewStore',
    context: context,
  );

  @override
  void updatePosition(Offset newPosition) {
    final _$actionInfo = _$_FloatingPhoneViewStoreActionController.startAction(
      name: '_FloatingPhoneViewStore.updatePosition',
    );
    try {
      return super.updatePosition(newPosition);
    } finally {
      _$_FloatingPhoneViewStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateDimensions(double newWidth, double newHeight) {
    final _$actionInfo = _$_FloatingPhoneViewStoreActionController.startAction(
      name: '_FloatingPhoneViewStore.updateDimensions',
    );
    try {
      return super.updateDimensions(newWidth, newHeight);
    } finally {
      _$_FloatingPhoneViewStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void initializePositionAndSize(
    Offset initialPosition,
    double initialWidth,
    double initialHeight,
  ) {
    final _$actionInfo = _$_FloatingPhoneViewStoreActionController.startAction(
      name: '_FloatingPhoneViewStore.initializePositionAndSize',
    );
    try {
      return super.initializePositionAndSize(
        initialPosition,
        initialWidth,
        initialHeight,
      );
    } finally {
      _$_FloatingPhoneViewStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setGeneratingPoster(bool generating) {
    final _$actionInfo = _$_FloatingPhoneViewStoreActionController.startAction(
      name: '_FloatingPhoneViewStore.setGeneratingPoster',
    );
    try {
      return super.setGeneratingPoster(generating);
    } finally {
      _$_FloatingPhoneViewStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setSelectedPosterData(PosterData? data) {
    final _$actionInfo = _$_FloatingPhoneViewStoreActionController.startAction(
      name: '_FloatingPhoneViewStore.setSelectedPosterData',
    );
    try {
      return super.setSelectedPosterData(data);
    } finally {
      _$_FloatingPhoneViewStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
position: ${position},
width: ${width},
height: ${height},
isGeneratingPoster: ${isGeneratingPoster},
selectedPosterData: ${selectedPosterData}
    ''';
  }
}
