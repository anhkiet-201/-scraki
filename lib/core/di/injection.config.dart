// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../../data/datasources/adb_remote_data_source.dart' as _i387;
import '../../data/datasources/scrcpy_client.dart' as _i553;
import '../../data/datasources/scrcpy_socket_client.dart' as _i481;
import '../../data/repositories/device_repository_impl.dart' as _i34;
import '../../data/services/device_control_service.dart' as _i315;
import '../../data/services/scrcpy_service.dart' as _i922;
import '../../data/services/video_proxy_service.dart' as _i416;
import '../../domain/repositories/i_device_repository.dart' as _i664;
import '../../presentation/stores/device_store.dart' as _i642;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.lazySingleton<_i553.ScrcpyClient>(() => _i553.ScrcpyClient());
    gh.lazySingleton<_i481.ScrcpySocketClient>(
      () => _i481.ScrcpySocketClient(),
    );
    gh.lazySingleton<_i416.VideoProxyService>(() => _i416.VideoProxyService());
    gh.lazySingleton<_i922.ScrcpyService>(() => _i922.ScrcpyService());
    gh.lazySingleton<_i387.IAdbRemoteDataSource>(
      () => _i387.AdbRemoteDataSourceImpl(),
    );
    gh.lazySingleton<_i664.IDeviceRepository>(
      () => _i34.DeviceRepositoryImpl(gh<_i387.IAdbRemoteDataSource>()),
    );
    gh.lazySingleton<_i315.DeviceControlService>(
      () => _i315.DeviceControlService(gh<_i922.ScrcpyService>()),
    );
    gh.lazySingleton<_i642.DeviceStore>(
      () => _i642.DeviceStore(
        gh<_i664.IDeviceRepository>(),
        gh<_i922.ScrcpyService>(),
        gh<_i315.DeviceControlService>(),
        gh<_i416.VideoProxyService>(),
      ),
    );
    return this;
  }
}
