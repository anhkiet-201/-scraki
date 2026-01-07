import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';

part 'dashboard_store.g.dart';

@lazySingleton
// ignore: library_private_types_in_public_api
class DashboardStore = _DashboardStore with _$DashboardStore;

/// Store chịu trách nhiệm quản lý trạng thái UI của Dashboard.
///
/// Chức năng chính:
/// - Quản lý trạng thái tab được chọn (Navigation)
abstract class _DashboardStore with Store {
  _DashboardStore();

  // ═══════════════════════════════════════════════════════════════
  // NAVIGATION STATE
  // ═══════════════════════════════════════════════════════════════

  @observable
  int selectedIndex = 0;

  @action
  void setSelectedIndex(int index) {
    selectedIndex = index;
  }

  // ═══════════════════════════════════════════════════════════════
  // SEARCH STATE
  // ═══════════════════════════════════════════════════════════════

  @observable
  String searchQuery = '';

  Timer? _searchDebounceTimer;

  @action
  void setSearchQuery(String query) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      runInAction(() => searchQuery = query);
    });
  }
}
