import 'package:scraki/core/auth/presentation/stores/app_auth_store.dart';
import 'package:scraki/core/di/injection.dart';

mixin AppAuthStoreMixin {
  AppAuthStore get appAuthStore => getIt<AppAuthStore>();
}
