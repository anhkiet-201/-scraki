// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'native_video_decoder_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$NativeVideoDecoderStore on _NativeVideoDecoderStore, Store {
  late final _$_textureIdAtom = Atom(
    name: '_NativeVideoDecoderStore._textureId',
    context: context,
  );

  int? get textureId {
    _$_textureIdAtom.reportRead();
    return super._textureId;
  }

  @override
  int? get _textureId => textureId;

  @override
  set _textureId(int? value) {
    _$_textureIdAtom.reportWrite(value, super._textureId, () {
      super._textureId = value;
    });
  }

  late final _$_isInitializingAtom = Atom(
    name: '_NativeVideoDecoderStore._isInitializing',
    context: context,
  );

  bool get isInitializing {
    _$_isInitializingAtom.reportRead();
    return super._isInitializing;
  }

  @override
  bool get _isInitializing => isInitializing;

  @override
  set _isInitializing(bool value) {
    _$_isInitializingAtom.reportWrite(value, super._isInitializing, () {
      super._isInitializing = value;
    });
  }

  late final _$acquireTextureAsyncAction = AsyncAction(
    '_NativeVideoDecoderStore.acquireTexture',
    context: context,
  );

  @override
  Future<void> acquireTexture() {
    return _$acquireTextureAsyncAction.run(() => super.acquireTexture());
  }

  late final _$_NativeVideoDecoderStoreActionController = ActionController(
    name: '_NativeVideoDecoderStore',
    context: context,
  );

  @override
  void releaseTexture() {
    final _$actionInfo = _$_NativeVideoDecoderStoreActionController.startAction(
      name: '_NativeVideoDecoderStore.releaseTexture',
    );
    try {
      return super.releaseTexture();
    } finally {
      _$_NativeVideoDecoderStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''

    ''';
  }
}
