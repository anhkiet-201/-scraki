import 'package:scraki/core/mixins/di_mixin.dart';
import 'package:scraki/core/stores/session_manager_store.dart';

mixin SessionManagerStoreMixin {
  SessionManagerStore get sessionManagerStore => inject<SessionManagerStore>();
}