import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
import 'package:scraki/core/constants/ui_constants.dart';
import 'package:scraki/features/device/domain/entities/mirror_session.dart';

part 'session_manager_store.g.dart';

@lazySingleton
// ignore: library_private_types_in_public_api
class SessionManagerStore = _SessionManagerStore with _$SessionManagerStore;

/// Store responsible for managing screen mirroring sessions and input handling.
///
/// Handles:
/// - Mirroring lifecycle (start/stop)
/// - Active sessions management
/// - Input events (touch, keyboard, scroll)
/// - File operations (drag & drop)
/// - Clipboard operations
/// - Double-tap floating detection
abstract class _SessionManagerStore with Store {
  _SessionManagerStore();

  // ═══════════════════════════════════════════════════════════════
  // SESSION MANAGEMENT
  // ═══════════════════════════════════════════════════════════════

  @observable
  ObservableMap<String, MirrorSession> activeSessions =
      ObservableMap<String, MirrorSession>();

  @computed
  double get deviceAspectRatio {
    const double defaultVideoRatio = 9 / 19; // Modern phone ratio
    final double fallbackRatio = defaultVideoRatio;

    if (activeSessions.isEmpty) return fallbackRatio;

    // Use the aspect ratio of the first active session for the whole grid
    // Logic: Ratio = Width / (Height + NavBarHeight)
    final firstSession = activeSessions.values.first;
    if (firstSession.width > 0 && firstSession.height > 0) {
      return firstSession.width /
          (firstSession.height + UIConstants.gridNavigationBarHeight);
    }
    return fallbackRatio;
  }

  // ═══════════════════════════════════════════════════════════════
  // FLOATING WINDOW
  // ═══════════════════════════════════════════════════════════════

  @observable
  String? floatingSerial;

  @computed
  bool get isFloatingVisible => floatingSerial != null;

  @action
  void toggleFloating(String? serial) {
    if (floatingSerial == serial) {
      floatingSerial = null;
    } else {
      floatingSerial = serial;
    }
  }
}
