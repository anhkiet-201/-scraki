// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i361;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../../features/auth/data/datasources/auth_remote_data_source.dart'
    as _i107;
import '../../features/auth/data/repositories/auth_repository_impl.dart'
    as _i153;
import '../../features/auth/domain/repositories/i_auth_repository.dart'
    as _i589;
import '../../features/auth/presentation/stores/auth_store.dart' as _i603;
import '../../features/dashboard/presentation/stores/dashboard_store.dart'
    as _i891;
import '../../features/device/data/datasources/adb_remote_data_source.dart'
    as _i165;
import '../../features/device/data/datasources/aki_remote_service.dart'
    as _i109;
import '../../features/device/data/datasources/device_group_remote_data_source.dart'
    as _i521;
import '../../features/device/data/datasources/scrcpy_client.dart' as _i212;
import '../../features/device/data/datasources/scrcpy_service.dart' as _i972;
import '../../features/device/data/datasources/scrcpy_socket_client.dart'
    as _i607;
import '../../features/device/data/datasources/tiktok_post_service.dart'
    as _i727;
import '../../features/device/data/datasources/video_worker_manager.dart'
    as _i3;
import '../../features/device/data/repositories/device_group_repository_firebase_impl.dart'
    as _i936;
import '../../features/device/data/repositories/device_repository_impl.dart'
    as _i740;
import '../../features/device/data/services/native_video_decoder_service_impl.dart'
    as _i892;
import '../../features/device/domain/repositories/device_group_repository.dart'
    as _i510;
import '../../features/device/domain/repositories/device_repository.dart'
    as _i985;
import '../../features/device/domain/services/i_aki_remote_service.dart'
    as _i260;
import '../../features/device/domain/services/i_tiktok_post_service.dart'
    as _i229;
import '../../features/device/domain/services/i_video_decoder_service.dart'
    as _i768;
import '../../features/device/presentation/stores/device_group_store.dart'
    as _i246;
import '../../features/device/presentation/stores/device_nickname_store.dart'
    as _i391;
import '../../features/email/data/datasources/credential_remote_data_source.dart'
    as _i296;
import '../../features/email/data/datasources/imap_remote_data_source.dart'
    as _i583;
import '../../features/email/data/repositories/email_repository_impl.dart'
    as _i352;
import '../../features/email/domain/repositories/i_email_repository.dart'
    as _i482;
import '../../features/email/presentation/stores/email_store.dart' as _i498;
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
import '../../features/script/data/datasources/local_script_data_source.dart'
    as _i992;
import '../../features/script/data/datasources/remote_script_data_source.dart'
    as _i53;
import '../../features/script/data/repositories/script_repository_impl.dart'
    as _i556;
import '../../features/script/domain/interpolation/command_interpolator.dart'
    as _i101;
import '../../features/script/domain/repositories/script_repository.dart'
    as _i55;
import '../../features/script/domain/usecases/delete_script_use_case.dart'
    as _i205;
import '../../features/script/domain/usecases/execute_command_use_case.dart'
    as _i275;
import '../../features/script/domain/usecases/run_script_use_case.dart' as _i69;
import '../../features/script/domain/usecases/save_script_use_case.dart'
    as _i240;
import '../../features/script/presentation/stores/script_management_store.dart'
    as _i405;
import '../../features/script/presentation/stores/terminal_store.dart' as _i137;
import '../../features/settings/data/repositories/settings_repository_impl.dart'
    as _i955;
import '../../features/settings/di/settings_module.dart' as _i273;
import '../../features/settings/domain/repositories/i_settings_repository.dart'
    as _i657;
import '../../features/settings/domain/usecases/get_settings_usecase.dart'
    as _i1029;
import '../../features/settings/presentation/stores/settings_email_store.dart'
    as _i1056;
import '../../features/settings/presentation/stores/settings_store.dart'
    as _i151;
import '../../features/tiktok_seeding/data/repositories/tiktok_seeding_repository_impl.dart'
    as _i1016;
import '../../features/tiktok_seeding/data/services/tiktok_seeding_service.dart'
    as _i1032;
import '../../features/tiktok_seeding/domain/repositories/i_tiktok_seeding_repository.dart'
    as _i1022;
import '../../features/tiktok_seeding/domain/services/i_tiktok_seeding_service.dart'
    as _i801;
import '../../features/tiktok_seeding/presentation/stores/tiktok_seeding_store.dart'
    as _i478;
import '../../features/video_poster/data/datasources/favorite_image_remote_data_source.dart'
    as _i963;
import '../../features/video_poster/data/repositories/favorite_image_repository_impl.dart'
    as _i650;
import '../../features/video_poster/data/repositories/ffmpeg_video_processing_repository_impl.dart'
    as _i1007;
import '../../features/video_poster/data/repositories/recent_color_repository.dart'
    as _i763;
import '../../features/video_poster/data/services/batch_video/core/pipeline/video_batch_pipeline.dart'
    as _i514;
import '../../features/video_poster/data/services/batch_video/core/pipeline/video_batch_pipeline_impl.dart'
    as _i454;
import '../../features/video_poster/data/services/batch_video/engines/audio/ambient_audio_provider.dart'
    as _i761;
import '../../features/video_poster/data/services/batch_video/engines/hardware/macos_video_hardware_capability_resolver.dart'
    as _i815;
import '../../features/video_poster/data/services/batch_video/engines/hardware/video_hardware_capability_resolver.dart'
    as _i9;
import '../../features/video_poster/data/services/batch_video/engines/hardware/windows_video_hardware_capability_resolver.dart'
    as _i746;
import '../../features/video_poster/data/services/batch_video/engines/metadata/video_metadata_analyzer.dart'
    as _i606;
import '../../features/video_poster/data/services/batch_video/engines/metadata/video_metadata_analyzer_impl.dart'
    as _i1051;
import '../../features/video_poster/data/services/giphy_service.dart' as _i298;
import '../../features/video_poster/data/services/image_drop_service.dart'
    as _i113;
import '../../features/video_poster/domain/repositories/favorite_image_repository.dart'
    as _i147;
import '../../features/video_poster/domain/repositories/video_processing_repository.dart'
    as _i427;
import '../../features/video_poster/domain/services/anti_reup_service.dart'
    as _i154;
import '../../features/video_poster/presentation/stores/image_drop_store.dart'
    as _i348;
import '../../features/video_poster/presentation/stores/video_poster_store.dart'
    as _i618;
import '../auth/data/repositories/app_auth_repository_impl.dart' as _i133;
import '../auth/domain/repositories/i_app_auth_repository.dart' as _i239;
import '../auth/domain/usecases/sign_in_anonymously_usecase.dart' as _i222;
import '../auth/presentation/stores/app_auth_store.dart' as _i27;
import '../config/settings_config_provider.dart' as _i730;
import '../network/dio_client.dart' as _i667;
import '../stores/device_manager_store.dart' as _i563;
import '../stores/session_manager_store.dart' as _i773;
import 'interpolation_module.dart' as _i1073;
import 'register_module.dart' as _i291;

const String _windows = 'windows';
const String _macos = 'macos';

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final interpolationModule = _$InterpolationModule();
    final registerModule = _$RegisterModule();
    final settingsUseCaseModule = _$SettingsUseCaseModule();
    gh.factory<_i429.PosterCreatorStore>(() => _i429.PosterCreatorStore());
    gh.factory<_i90.PosterCustomizationStore>(
      () => _i90.PosterCustomizationStore(),
    );
    gh.factory<_i113.ImageDropService>(() => _i113.ImageDropService());
    gh.factory<_i618.VideoPosterStore>(() => _i618.VideoPosterStore());
    gh.singleton<_i101.CommandInterpolator>(
      () => interpolationModule.provideCommandInterpolator(),
    );
    gh.lazySingleton<_i361.Dio>(() => registerModule.dio);
    gh.lazySingleton<_i773.SessionManagerStore>(
      () => _i773.SessionManagerStore(),
    );
    gh.lazySingleton<_i891.DashboardStore>(() => _i891.DashboardStore());
    gh.lazySingleton<_i212.ScrcpyClient>(() => _i212.ScrcpyClient());
    gh.lazySingleton<_i972.ScrcpyService>(() => _i972.ScrcpyService());
    gh.lazySingleton<_i607.ScrcpySocketClient>(
      () => _i607.ScrcpySocketClient(),
    );
    gh.lazySingleton<_i3.VideoWorkerManager>(() => _i3.VideoWorkerManager());
    gh.lazySingleton<_i763.RecentColorRepository>(
      () => _i763.RecentColorRepository(),
    );
    gh.lazySingleton<_i154.AntiReupService>(() => _i154.AntiReupService());
    gh.lazySingleton<_i107.IAuthRemoteDataSource>(
      () => _i107.AuthRemoteDataSourceFirebaseImpl(),
    );
    gh.lazySingleton<_i239.IAppAuthRepository>(
      () => _i133.AppAuthRepositoryImpl(),
    );
    gh.lazySingleton<_i589.IAuthRepository>(
      () => _i153.AuthRepositoryImpl(gh<_i107.IAuthRemoteDataSource>()),
    );
    gh.lazySingleton<_i1022.ITikTokSeedingRepository>(
      () => _i1016.TikTokSeedingRepositoryImpl(),
    );
    gh.lazySingleton<_i260.IAkiRemoteService>(() => _i109.AkiRemoteService());
    gh.lazySingleton<_i165.IAdbRemoteDataSource>(
      () => _i165.AdbRemoteDataSourceImpl(),
    );
    gh.lazySingleton<_i521.DeviceGroupRemoteDataSource>(
      () => _i521.DeviceGroupRemoteDataSourceImpl(),
    );
    gh.factory<_i427.VideoProcessingRepository>(
      () => _i1007.FfmpegVideoProcessingRepositoryImpl(),
    );
    gh.lazySingleton<_i391.IPosterRepository>(
      () => _i424.PosterRepositoryImpl(),
    );
    gh.lazySingleton<_i603.AuthStore>(
      () => _i603.AuthStore(
        gh<_i589.IAuthRepository>(),
        gh<_i260.IAkiRemoteService>(),
      ),
    );
    gh.lazySingleton<_i963.FavoriteImageRemoteDataSource>(
      () => _i963.FavoriteImageRemoteDataSourceImpl(),
    );
    gh.lazySingleton<_i348.ImageDropStore>(
      () => _i348.ImageDropStore(gh<_i113.ImageDropService>()),
    );
    gh.lazySingleton<_i9.VideoHardwareCapabilityResolver>(
      () => _i746.WindowsVideoHardwareCapabilityResolver(),
      registerFor: {_windows},
    );
    gh.lazySingleton<_i992.LocalScriptDataSource>(
      () => _i992.LocalScriptDataSourceImpl(),
      instanceName: 'local_script',
    );
    gh.lazySingleton<_i583.IImapRemoteDataSource>(
      () => _i583.ImapRemoteDataSourceImpl(),
    );
    gh.lazySingleton<_i657.ISettingsRepository>(
      () => _i955.SettingsRepositoryImpl(),
    );
    gh.lazySingleton<_i296.ICredentialRemoteDataSource>(
      () => _i296.CredentialRemoteDataSourceFirebaseImpl(),
    );
    gh.lazySingleton<_i667.DioClient>(() => _i667.DioClient(gh<_i361.Dio>()));
    gh.lazySingleton<_i53.RemoteScriptDataSource>(
      () => _i53.RemoteScriptDataSourceImpl(),
    );
    gh.lazySingleton<_i284.RecruitmentRemoteDataSource>(
      () => _i284.RecruitmentRemoteDataSourceImpl(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i768.IVideoDecoderService>(
      () => _i892.NativeVideoDecoderServiceImpl(),
    );
    gh.lazySingleton<_i482.IEmailRepository>(
      () => _i352.EmailRepositoryImpl(
        gh<_i296.ICredentialRemoteDataSource>(),
        gh<_i583.IImapRemoteDataSource>(),
      ),
    );
    gh.lazySingleton<_i510.DeviceGroupRepository>(
      () => _i936.DeviceGroupRepositoryFirebaseImpl(
        gh<_i521.DeviceGroupRemoteDataSource>(),
      ),
    );
    gh.lazySingleton<_i9.VideoHardwareCapabilityResolver>(
      () => _i815.MacOSVideoHardwareCapabilityResolver(),
      registerFor: {_macos},
    );
    gh.lazySingleton<_i229.ITikTokPostService>(
      () => _i727.TikTokPostService(gh<_i972.ScrcpyService>()),
    );
    gh.lazySingleton<_i606.VideoMetadataAnalyzer>(
      () => _i1051.VideoMetadataAnalyzerImpl(
        gh<_i9.VideoHardwareCapabilityResolver>(),
      ),
    );
    gh.lazySingleton<_i985.DeviceRepository>(
      () => _i740.DeviceRepositoryImpl(gh<_i165.IAdbRemoteDataSource>()),
    );
    gh.lazySingleton<_i147.FavoriteImageRepository>(
      () => _i650.FavoriteImageRepositoryImpl(
        gh<_i963.FavoriteImageRemoteDataSource>(),
      ),
    );
    gh.factory<_i1029.GetSettingsUseCase>(
      () => settingsUseCaseModule.getSettingsUseCase(
        gh<_i657.ISettingsRepository>(),
      ),
    );
    gh.lazySingleton<_i563.DeviceManagerStore>(
      () => _i563.DeviceManagerStore(gh<_i985.DeviceRepository>()),
    );
    gh.lazySingleton<_i481.RecruitmentRepository>(
      () => _i240.RecruitmentRepositoryImpl(
        gh<_i284.RecruitmentRemoteDataSource>(),
      ),
    );
    gh.lazySingleton<_i55.ScriptRepository>(
      () => _i556.ScriptRepositoryImpl(
        gh<_i165.IAdbRemoteDataSource>(),
        gh<_i992.LocalScriptDataSource>(instanceName: 'local_script'),
        gh<_i53.RemoteScriptDataSource>(),
      ),
    );
    gh.factory<_i706.SavePosterUseCase>(
      () => _i706.SavePosterUseCase(gh<_i391.IPosterRepository>()),
    );
    gh.lazySingleton<_i222.SignInAnonymouslyUseCase>(
      () => _i222.SignInAnonymouslyUseCase(gh<_i239.IAppAuthRepository>()),
    );
    gh.factory<_i1056.SettingsEmailStore>(
      () => _i1056.SettingsEmailStore(gh<_i482.IEmailRepository>()),
    );
    gh.factory<_i275.ExecuteCommandUseCase>(
      () => _i275.ExecuteCommandUseCase(gh<_i55.ScriptRepository>()),
    );
    gh.factory<_i498.EmailStore>(
      () => _i498.EmailStore(
        gh<_i482.IEmailRepository>(),
        gh<_i985.DeviceRepository>(),
        gh<_i260.IAkiRemoteService>(),
      ),
    );
    gh.factory<_i761.AmbientAudioProvider>(
      () => _i761.AmbientAudioProvider(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i298.GiphyService>(
      () => _i298.GiphyService(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i833.FetchJobDetailUseCase>(
      () => _i833.FetchJobDetailUseCase(gh<_i481.RecruitmentRepository>()),
    );
    gh.lazySingleton<_i420.FetchJobsUseCase>(
      () => _i420.FetchJobsUseCase(gh<_i481.RecruitmentRepository>()),
    );
    gh.lazySingleton<_i405.ParseJobTextUseCase>(
      () => _i405.ParseJobTextUseCase(gh<_i481.RecruitmentRepository>()),
    );
    gh.lazySingleton<_i545.SearchJobsWithAiUseCase>(
      () => _i545.SearchJobsWithAiUseCase(gh<_i481.RecruitmentRepository>()),
    );
    gh.lazySingleton<_i801.ITikTokSeedingService>(
      () => _i1032.TikTokSeedingService(gh<_i229.ITikTokPostService>()),
    );
    gh.lazySingleton<_i27.AppAuthStore>(
      () => _i27.AppAuthStore(gh<_i222.SignInAnonymouslyUseCase>()),
    );
    gh.singleton<_i151.SettingsStore>(
      () => _i151.SettingsStore(gh<_i657.ISettingsRepository>()),
    );
    gh.lazySingleton<_i478.TikTokSeedingStore>(
      () => _i478.TikTokSeedingStore(
        gh<_i801.ITikTokSeedingService>(),
        gh<_i1022.ITikTokSeedingRepository>(),
      ),
    );
    gh.factory<_i876.PosterCreationStore>(
      () => _i876.PosterCreationStore(
        gh<_i405.ParseJobTextUseCase>(),
        gh<_i420.FetchJobsUseCase>(),
        gh<_i545.SearchJobsWithAiUseCase>(),
      ),
    );
    gh.factory<_i69.RunScriptUseCase>(
      () => _i69.RunScriptUseCase(gh<_i55.ScriptRepository>()),
    );
    gh.lazySingleton<_i205.DeleteScriptUseCase>(
      () => _i205.DeleteScriptUseCase(gh<_i55.ScriptRepository>()),
    );
    gh.lazySingleton<_i240.SaveScriptUseCase>(
      () => _i240.SaveScriptUseCase(gh<_i55.ScriptRepository>()),
    );
    gh.lazySingleton<_i514.VideoBatchPipeline>(
      () => _i454.VideoBatchPipelineImpl(
        gh<_i9.VideoHardwareCapabilityResolver>(),
        gh<_i606.VideoMetadataAnalyzer>(),
        gh<_i761.AmbientAudioProvider>(),
      ),
    );
    gh.singleton<_i730.SettingsConfigProvider>(
      () => _i730.SettingsConfigProvider(gh<_i1029.GetSettingsUseCase>()),
    );
    gh.singleton<_i405.ScriptManagementStore>(
      () => _i405.ScriptManagementStore(
        gh<_i55.ScriptRepository>(),
        gh<_i240.SaveScriptUseCase>(),
        gh<_i205.DeleteScriptUseCase>(),
      ),
    );
    gh.lazySingleton<_i246.DeviceGroupStore>(
      () => _i246.DeviceGroupStore(
        gh<_i510.DeviceGroupRepository>(),
        gh<_i563.DeviceManagerStore>(),
        gh<_i891.DashboardStore>(),
        gh<_i151.SettingsStore>(),
      ),
    );
    gh.singleton<_i391.DeviceNicknameStore>(
      () => _i391.DeviceNicknameStore(gh<_i246.DeviceGroupStore>()),
    );
    gh.singleton<_i137.TerminalStore>(
      () => _i137.TerminalStore(
        gh<_i563.DeviceManagerStore>(),
        gh<_i246.DeviceGroupStore>(),
        gh<_i405.ScriptManagementStore>(),
        gh<_i101.CommandInterpolator>(),
      ),
    );
    return this;
  }
}

class _$InterpolationModule extends _i1073.InterpolationModule {}

class _$RegisterModule extends _i291.RegisterModule {}

class _$SettingsUseCaseModule extends _i273.SettingsUseCaseModule {}
