import 'package:scraki/core/mixins/di_mixin.dart';
import 'package:scraki/features/settings/presentation/stores/settings_store.dart';

/// Mixin để truy cập SettingsStore dễ dàng từ Widget
/// Usage: class MyWidget extends StatelessWidget with SettingsStoreMixin
mixin SettingsStoreMixin on Object {
  SettingsStore get settingsStore => inject<SettingsStore>();
}
