// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i361;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../../features/dashboard/presentation/stores/dashboard_store.dart'
    as _i891;
import '../../features/device/data/datasources/adb_remote_data_source.dart'
    as _i165;
import '../../features/device/data/datasources/scrcpy_client.dart' as _i212;
import '../../features/device/data/datasources/scrcpy_service.dart' as _i972;
import '../../features/device/data/datasources/scrcpy_socket_client.dart'
    as _i607;
import '../../features/device/data/datasources/video_worker_manager.dart'
    as _i3;
import '../../features/device/data/repositories/device_group_repository_impl.dart'
    as _i454;
import '../../features/device/data/repositories/device_repository_impl.dart'
    as _i740;
import '../../features/device/domain/repositories/device_group_repository.dart'
    as _i510;
import '../../features/device/domain/repositories/device_repository.dart'
    as _i985;
import '../../features/device/presentation/stores/device_group_store.dart'
    as _i246;
import '../../features/poster/data/repositories/poster_repository_impl.dart'
    as _i424;
import '../../features/poster/domain/repositories/i_poster_repository.dart'
    as _i391;
import '../../features/poster/domain/usecases/save_poster_usecase.dart'
    as _i706;
import '../../features/poster/presentation/stores/poster_creation_store.dart'
    as _i876;
import '../../features/poster/presentation/stores/poster_creator_store.dart'
    as _i429;
import '../../features/poster/presentation/stores/poster_customization_store.dart'
    as _i90;
import '../../features/recruitment/data/datasources/recruitment_remote_data_source.dart'
    as _i284;
import '../../features/recruitment/data/repositories/recruitment_repository_impl.dart'
    as _i240;
import '../../features/recruitment/domain/repositories/recruitment_repository.dart'
    as _i481;
import '../../features/recruitment/domain/usecases/fetch_job_detail_usecase.dart'
    as _i833;
import '../../features/recruitment/domain/usecases/fetch_jobs_usecase.dart'
    as _i420;
import '../../features/recruitment/domain/usecases/parse_job_text_usecase.dart'
    as _i405;
import '../../features/recruitment/domain/usecases/search_jobs_with_ai_usecase.dart'
    as _i545;
import '../network/dio_client.dart' as _i667;
import '../stores/device_manager_store.dart' as _i563;
import '../stores/session_manager_store.dart' as _i773;
import 'register_module.dart' as _i291;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    gh.factory<_i429.PosterCreatorStore>(() => _i429.PosterCreatorStore());
    gh.factory<_i90.PosterCustomizationStore>(
      () => _i90.PosterCustomizationStore(),
    );
    gh.lazySingleton<_i361.Dio>(() => registerModule.dio);
    gh.lazySingleton<_i773.SessionManagerStore>(
      () => _i773.SessionManagerStore(),
    );
    gh.lazySingleton<_i891.DashboardStore>(() => _i891.DashboardStore());
    gh.lazySingleton<_i212.ScrcpyClient>(() => _i212.ScrcpyClient());
    gh.lazySingleton<_i972.ScrcpyService>(() => _i972.ScrcpyService());
    gh.lazySingleton<_i3.VideoWorkerManager>(() => _i3.VideoWorkerManager());
    gh.lazySingleton<_i607.ScrcpySocketClient>(
      () => _i607.ScrcpySocketClient(),
    );
    gh.lazySingleton<_i165.IAdbRemoteDataSource>(
      () => _i165.AdbRemoteDataSourceImpl(),
    );
    gh.lazySingleton<_i391.IPosterRepository>(
      () => _i424.PosterRepositoryImpl(),
    );
    gh.lazySingleton<_i510.DeviceGroupRepository>(
      () => _i454.DeviceGroupRepositoryImpl(),
    );
    gh.lazySingleton<_i667.DioClient>(() => _i667.DioClient(gh<_i361.Dio>()));
    gh.lazySingleton<_i985.DeviceRepository>(
      () => _i740.DeviceRepositoryImpl(gh<_i165.IAdbRemoteDataSource>()),
    );
    gh.factory<_i706.SavePosterUseCase>(
      () => _i706.SavePosterUseCase(gh<_i391.IPosterRepository>()),
    );
    gh.lazySingleton<_i284.RecruitmentRemoteDataSource>(
      () => _i284.RecruitmentRemoteDataSourceImpl(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i563.DeviceManagerStore>(
      () => _i563.DeviceManagerStore(gh<_i985.DeviceRepository>()),
    );
    gh.lazySingleton<_i481.RecruitmentRepository>(
      () => _i240.RecruitmentRepositoryImpl(
        gh<_i284.RecruitmentRemoteDataSource>(),
      ),
    );
    gh.lazySingleton<_i246.DeviceGroupStore>(
      () => _i246.DeviceGroupStore(
        gh<_i510.DeviceGroupRepository>(),
        gh<_i563.DeviceManagerStore>(),
        gh<_i891.DashboardStore>(),
      ),
    );
    gh.lazySingleton<_i833.FetchJobDetailUseCase>(
      () => _i833.FetchJobDetailUseCase(gh<_i481.RecruitmentRepository>()),
    );
    gh.lazySingleton<_i405.ParseJobTextUseCase>(
      () => _i405.ParseJobTextUseCase(gh<_i481.RecruitmentRepository>()),
    );
    gh.lazySingleton<_i420.FetchJobsUseCase>(
      () => _i420.FetchJobsUseCase(gh<_i481.RecruitmentRepository>()),
    );
    gh.lazySingleton<_i545.SearchJobsWithAiUseCase>(
      () => _i545.SearchJobsWithAiUseCase(gh<_i481.RecruitmentRepository>()),
    );
    gh.factory<_i876.PosterCreationStore>(
      () => _i876.PosterCreationStore(
        gh<_i405.ParseJobTextUseCase>(),
        gh<_i420.FetchJobsUseCase>(),
        gh<_i545.SearchJobsWithAiUseCase>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}
