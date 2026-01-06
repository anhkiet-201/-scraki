import 'package:scraki/core/mixins/di_mixin.dart';
import 'package:scraki/core/stores/device_manager_store.dart';

mixin DeviceManagerStoreMixin {
  DeviceManagerStore get deviceManagerStore => inject<DeviceManagerStore>();
}