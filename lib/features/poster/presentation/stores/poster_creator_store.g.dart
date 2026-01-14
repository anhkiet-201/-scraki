// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'poster_creator_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$PosterCreatorStore on _PosterCreatorStore, Store {
  late final _$selectedTemplateAtom = Atom(
    name: '_PosterCreatorStore.selectedTemplate',
    context: context,
  );

  @override
  PosterTemplateType get selectedTemplate {
    _$selectedTemplateAtom.reportRead();
    return super.selectedTemplate;
  }

  @override
  set selectedTemplate(PosterTemplateType value) {
    _$selectedTemplateAtom.reportWrite(value, super.selectedTemplate, () {
      super.selectedTemplate = value;
    });
  }

  late final _$isSavingAtom = Atom(
    name: '_PosterCreatorStore.isSaving',
    context: context,
  );

  @override
  bool get isSaving {
    _$isSavingAtom.reportRead();
    return super.isSaving;
  }

  @override
  set isSaving(bool value) {
    _$isSavingAtom.reportWrite(value, super.isSaving, () {
      super.isSaving = value;
    });
  }

  late final _$searchQueryAtom = Atom(
    name: '_PosterCreatorStore.searchQuery',
    context: context,
  );

  @override
  String get searchQuery {
    _$searchQueryAtom.reportRead();
    return super.searchQuery;
  }

  @override
  set searchQuery(String value) {
    _$searchQueryAtom.reportWrite(value, super.searchQuery, () {
      super.searchQuery = value;
    });
  }

  late final _$_PosterCreatorStoreActionController = ActionController(
    name: '_PosterCreatorStore',
    context: context,
  );

  @override
  void selectTemplate(PosterTemplateType template) {
    final _$actionInfo = _$_PosterCreatorStoreActionController.startAction(
      name: '_PosterCreatorStore.selectTemplate',
    );
    try {
      return super.selectTemplate(template);
    } finally {
      _$_PosterCreatorStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setSaving(bool value) {
    final _$actionInfo = _$_PosterCreatorStoreActionController.startAction(
      name: '_PosterCreatorStore.setSaving',
    );
    try {
      return super.setSaving(value);
    } finally {
      _$_PosterCreatorStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateSearchQuery(String query) {
    final _$actionInfo = _$_PosterCreatorStoreActionController.startAction(
      name: '_PosterCreatorStore.updateSearchQuery',
    );
    try {
      return super.updateSearchQuery(query);
    } finally {
      _$_PosterCreatorStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
selectedTemplate: ${selectedTemplate},
isSaving: ${isSaving},
searchQuery: ${searchQuery}
    ''';
  }
}
