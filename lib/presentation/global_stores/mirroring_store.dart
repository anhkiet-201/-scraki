import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
import '../../../domain/entities/mirror_session.dart';

part 'mirroring_store.g.dart';

@lazySingleton
// ignore: library_private_types_in_public_api
class MirroringStore = _MirroringStore with _$MirroringStore;

/// Store responsible for managing screen mirroring sessions and input handling.
///
/// Handles:
/// - Mirroring lifecycle (start/stop)
/// - Active sessions management
/// - Input events (touch, keyboard, scroll)
/// - File operations (drag & drop)
/// - Clipboard operations
/// - Double-tap floating detection
abstract class _MirroringStore with Store {
  _MirroringStore();

  // ═══════════════════════════════════════════════════════════════
  // SESSION MANAGEMENT
  // ═══════════════════════════════════════════════════════════════

  @observable
  ObservableMap<String, MirrorSession> activeSessions =
      ObservableMap<String, MirrorSession>();

  @computed
  double get deviceAspectRatio {
    if (activeSessions.isEmpty) return 0.5625; // Default 9:16

    // Use the aspect ratio of the first active session for the whole grid
    final firstSession = activeSessions.values.first;
    if (firstSession.width > 0 && firstSession.height > 0) {
      return firstSession.width / firstSession.height;
    }
    return 0.5625;
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
