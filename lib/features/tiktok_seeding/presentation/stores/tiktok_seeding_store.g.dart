// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tiktok_seeding_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$TikTokSeedingStore on _TikTokSeedingStoreBase, Store {
  Computed<List<String>>? _$keywordsComputed;

  @override
  List<String> get keywords => (_$keywordsComputed ??= Computed<List<String>>(
    () => super.keywords,
    name: '_TikTokSeedingStoreBase.keywords',
  )).value;

  late final _$bulkInputAtom = Atom(
    name: '_TikTokSeedingStoreBase.bulkInput',
    context: context,
  );

  @override
  String get bulkInput {
    _$bulkInputAtom.reportRead();
    return super.bulkInput;
  }

  @override
  set bulkInput(String value) {
    _$bulkInputAtom.reportWrite(value, super.bulkInput, () {
      super.bulkInput = value;
    });
  }

  late final _$isProcessingAtom = Atom(
    name: '_TikTokSeedingStoreBase.isProcessing',
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

  late final _$errorMessageAtom = Atom(
    name: '_TikTokSeedingStoreBase.errorMessage',
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

  late final _$initAsyncAction = AsyncAction(
    '_TikTokSeedingStoreBase.init',
    context: context,
  );

  @override
  Future<void> init() {
    return _$initAsyncAction.run(() => super.init());
  }

  late final _$runBatchSeedingAsyncAction = AsyncAction(
    '_TikTokSeedingStoreBase.runBatchSeeding',
    context: context,
  );

  @override
  Future<void> runBatchSeeding(List<String> deviceSerials) {
    return _$runBatchSeedingAsyncAction.run(
      () => super.runBatchSeeding(deviceSerials),
    );
  }

  late final _$runSingleSeedingAsyncAction = AsyncAction(
    '_TikTokSeedingStoreBase.runSingleSeeding',
    context: context,
  );

  @override
  Future<void> runSingleSeeding(String serial, String query) {
    return _$runSingleSeedingAsyncAction.run(
      () => super.runSingleSeeding(serial, query),
    );
  }

  late final _$_TikTokSeedingStoreBaseActionController = ActionController(
    name: '_TikTokSeedingStoreBase',
    context: context,
  );

  @override
  void setBulkInput(String value) {
    final _$actionInfo = _$_TikTokSeedingStoreBaseActionController.startAction(
      name: '_TikTokSeedingStoreBase.setBulkInput',
    );
    try {
      return super.setBulkInput(value);
    } finally {
      _$_TikTokSeedingStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
bulkInput: ${bulkInput},
isProcessing: ${isProcessing},
errorMessage: ${errorMessage},
keywords: ${keywords}
    ''';
  }
}
