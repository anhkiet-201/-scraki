import 'package:fpdart/fpdart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:scraki/core/error/failures.dart';
import 'package:scraki/features/tiktok_seeding/domain/repositories/i_tiktok_seeding_repository.dart';

@LazySingleton(as: ITikTokSeedingRepository)
class TikTokSeedingRepositoryImpl implements ITikTokSeedingRepository {
  static const String boxName = 'tiktok_seeding';
  static const String inputKey = 'bulk_input';

  Future<Box<String>> _getBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox<String>(boxName);
    }
    return Hive.box<String>(boxName);
  }

  @override
  Future<Either<Failure, String>> getBulkInput() async {
    try {
      final box = await _getBox();
      final input = box.get(inputKey, defaultValue: '') as String;
      return Right(input);
    } catch (e) {
      return Left(CacheFailure('Failed to load seeding input: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveBulkInput(String input) async {
    try {
      final box = await _getBox();
      await box.put(inputKey, input);
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Failed to save seeding input: $e'));
    }
  }
}
