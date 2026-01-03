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
import '../../data/services/scrcpy_service.dart' as _i922;
import '../../data/services/video_worker_manager.dart' as _i832;
import '../../domain/repositories/device_repository.dart' as _i454;
import '../../presentation/global_stores/device_store.dart' as _i1031;
import '../../presentation/global_stores/mirroring_store.dart' as _i644;

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
    gh.lazySingleton<_i922.ScrcpyService>(() => _i922.ScrcpyService());
    gh.lazySingleton<_i832.VideoWorkerManager>(
      () => _i832.VideoWorkerManager(),
    );
    gh.lazySingleton<_i644.MirroringStore>(() => _i644.MirroringStore());
    gh.lazySingleton<_i387.IAdbRemoteDataSource>(
      () => _i387.AdbRemoteDataSourceImpl(),
    );
    gh.lazySingleton<_i454.DeviceRepository>(
      () => _i34.DeviceRepositoryImpl(gh<_i387.IAdbRemoteDataSource>()),
    );
    gh.lazySingleton<_i1031.DeviceStore>(
      () => _i1031.DeviceStore(gh<_i454.DeviceRepository>()),
    );
    return this;
  }
}
