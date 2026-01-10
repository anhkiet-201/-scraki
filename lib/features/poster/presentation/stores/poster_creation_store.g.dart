// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'poster_creation_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$PosterCreationStore on _PosterCreationStore, Store {
  late final _$currentStepAtom = Atom(
    name: '_PosterCreationStore.currentStep',
    context: context,
  );

  @override
  int get currentStep {
    _$currentStepAtom.reportRead();
    return super.currentStep;
  }

  @override
  set currentStep(int value) {
    _$currentStepAtom.reportWrite(value, super.currentStep, () {
      super.currentStep = value;
    });
  }

  late final _$isLoadingAtom = Atom(
    name: '_PosterCreationStore.isLoading',
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

  late final _$errorMessageAtom = Atom(
    name: '_PosterCreationStore.errorMessage',
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

  late final _$currentPosterDataAtom = Atom(
    name: '_PosterCreationStore.currentPosterData',
    context: context,
  );

  @override
  PosterData? get currentPosterData {
    _$currentPosterDataAtom.reportRead();
    return super.currentPosterData;
  }

  @override
  set currentPosterData(PosterData? value) {
    _$currentPosterDataAtom.reportWrite(value, super.currentPosterData, () {
      super.currentPosterData = value;
    });
  }

  late final _$availableJobsAtom = Atom(
    name: '_PosterCreationStore.availableJobs',
    context: context,
  );

  @override
  ObservableList<PosterData> get availableJobs {
    _$availableJobsAtom.reportRead();
    return super.availableJobs;
  }

  @override
  set availableJobs(ObservableList<PosterData> value) {
    _$availableJobsAtom.reportWrite(value, super.availableJobs, () {
      super.availableJobs = value;
    });
  }

  late final _$pageAtom = Atom(
    name: '_PosterCreationStore.page',
    context: context,
  );

  @override
  int get page {
    _$pageAtom.reportRead();
    return super.page;
  }

  @override
  set page(int value) {
    _$pageAtom.reportWrite(value, super.page, () {
      super.page = value;
    });
  }

  late final _$hasMoreAtom = Atom(
    name: '_PosterCreationStore.hasMore',
    context: context,
  );

  @override
  bool get hasMore {
    _$hasMoreAtom.reportRead();
    return super.hasMore;
  }

  @override
  set hasMore(bool value) {
    _$hasMoreAtom.reportWrite(value, super.hasMore, () {
      super.hasMore = value;
    });
  }

  late final _$isLoadMoreAtom = Atom(
    name: '_PosterCreationStore.isLoadMore',
    context: context,
  );

  @override
  bool get isLoadMore {
    _$isLoadMoreAtom.reportRead();
    return super.isLoadMore;
  }

  @override
  set isLoadMore(bool value) {
    _$isLoadMoreAtom.reportWrite(value, super.isLoadMore, () {
      super.isLoadMore = value;
    });
  }

  late final _$loadAvailableJobsAsyncAction = AsyncAction(
    '_PosterCreationStore.loadAvailableJobs',
    context: context,
  );

  @override
  Future<void> loadAvailableJobs({bool loadMore = false}) {
    return _$loadAvailableJobsAsyncAction.run(
      () => super.loadAvailableJobs(loadMore: loadMore),
    );
  }

  late final _$parseJobDescriptionAsyncAction = AsyncAction(
    '_PosterCreationStore.parseJobDescription',
    context: context,
  );

  @override
  Future<void> parseJobDescription(String text) {
    return _$parseJobDescriptionAsyncAction.run(
      () => super.parseJobDescription(text),
    );
  }

  late final _$selectJobAsyncAction = AsyncAction(
    '_PosterCreationStore.selectJob',
    context: context,
  );

  @override
  Future<void> selectJob(PosterData job) {
    return _$selectJobAsyncAction.run(() => super.selectJob(job));
  }

  late final _$regenerateAsyncAction = AsyncAction(
    '_PosterCreationStore.regenerate',
    context: context,
  );

  @override
  Future<void> regenerate() {
    return _$regenerateAsyncAction.run(() => super.regenerate());
  }

  late final _$_PosterCreationStoreActionController = ActionController(
    name: '_PosterCreationStore',
    context: context,
  );

  @override
  void updatePosterData(PosterData newData) {
    final _$actionInfo = _$_PosterCreationStoreActionController.startAction(
      name: '_PosterCreationStore.updatePosterData',
    );
    try {
      return super.updatePosterData(newData);
    } finally {
      _$_PosterCreationStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void reset() {
    final _$actionInfo = _$_PosterCreationStoreActionController.startAction(
      name: '_PosterCreationStore.reset',
    );
    try {
      return super.reset();
    } finally {
      _$_PosterCreationStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
currentStep: ${currentStep},
isLoading: ${isLoading},
errorMessage: ${errorMessage},
currentPosterData: ${currentPosterData},
availableJobs: ${availableJobs},
page: ${page},
hasMore: ${hasMore},
isLoadMore: ${isLoadMore}
    ''';
  }
}
