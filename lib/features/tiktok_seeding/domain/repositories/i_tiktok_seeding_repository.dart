import 'package:fpdart/fpdart.dart';
import 'package:scraki/core/error/failures.dart';

abstract class ITikTokSeedingRepository {
  /// Lấy danh sách từ khóa/link đã lưu.
  Future<Either<Failure, String>> getBulkInput();

  /// Lưu danh sách từ khóa/link.
  Future<Either<Failure, Unit>> saveBulkInput(String input);
}
