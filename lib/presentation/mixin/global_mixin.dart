import 'package:scraki/core/di/injection.dart';
import 'package:scraki/presentation/global_stores/mirroring_store.dart';

mixin MirroringStoreMixin {
  MirroringStore get mirroringStore => getIt<MirroringStore>();
}