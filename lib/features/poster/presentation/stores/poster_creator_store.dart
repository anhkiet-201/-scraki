import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
import 'package:scraki/features/poster/domain/enums/poster_template_type.dart';

part 'poster_creator_store.g.dart';

/// Store quản lý UI state cho PosterCreatorScreen
@injectable
class PosterCreatorStore = _PosterCreatorStore with _$PosterCreatorStore;

abstract class _PosterCreatorStore with Store {
  // region Observable States

  /// Template đang được chọn
  @observable
  PosterTemplateType selectedTemplate = PosterTemplateType.modern;

  /// Trạng thái đang lưu poster
  @observable
  bool isSaving = false;

  /// Search query hiện tại
  @observable
  String searchQuery = '';

  // endregion

  // region Private State
  Timer? _debounceTimer;
  // endregion

  // region Actions

  /// Chọn template mới
  @action
  void selectTemplate(PosterTemplateType template) {
    selectedTemplate = template;
  }

  /// Set trạng thái saving
  @action
  void setSaving(bool value) {
    isSaving = value;
  }

  /// Cập nhật search query
  @action
  void updateSearchQuery(String query) {
    searchQuery = query;
  }

  // endregion

  // region Business Logic

  /// Debounced search - chỉ trigger callback sau 500ms kể từ lần gõ cuối
  void debouncedSearch(String query, VoidCallback onSearch) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      updateSearchQuery(query);
      onSearch();
    });
  }

  /// Cleanup resources
  void dispose() {
    _debounceTimer?.cancel();
  }

  // endregion
}
