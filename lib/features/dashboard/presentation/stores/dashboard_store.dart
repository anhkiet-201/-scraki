import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';

part 'dashboard_store.g.dart';

@injectable
// ignore: library_private_types_in_public_api
class DashboardStore = _DashboardStore with _$DashboardStore;

/// Store responsible for managing Dashboard UI state.
///
/// Handles:
/// - Navigation selection state
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
}
