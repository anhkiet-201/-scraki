import 'package:fpdart/fpdart.dart';
import 'package:scraki/core/error/failures.dart';
import 'package:scraki/features/settings/domain/entities/settings_entity.dart';

/// Repository interface cho Settings
/// Tuân thủ Repository Pattern và Dependency Inversion Principle
abstract class ISettingsRepository {
  /// Lấy settings hiện tại từ storage
  /// Trả về Either<Failure, SettingsEntity>
  /// Nếu chưa có settings, trả về SettingsEntity.empty()
  Future<Either<Failure, SettingsEntity>> getSettings();

  /// Lưu settings mới vào storage
  /// Trả về Either<Failure, Unit> để báo thành công/thất bại
  Future<Either<Failure, Unit>> saveSettings(SettingsEntity settings);
}
