import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:scraki/core/error/failures.dart';
import 'package:scraki/core/auth/domain/repositories/i_app_auth_repository.dart';
import 'package:scraki/core/utils/logger.dart';

@LazySingleton(as: IAppAuthRepository)
class AppAuthRepositoryImpl implements IAppAuthRepository {
  final FirebaseAuth _firebaseAuth;

  AppAuthRepositoryImpl() : _firebaseAuth = FirebaseAuth.instance;

  @override
  Future<Either<Failure, Unit>> signInAnonymously() async {
    try {
      // Đăng xuất session cũ (nếu có) để xóa cache, đảm bảo Firebase luôn tạo account mới 
      // (hoặc đăng nhập lại bằng thông tin mới) thay vì sử dụng token đã bị xóa trên Console.
      await _firebaseAuth.signOut();
      await _firebaseAuth.signInAnonymously();
      return const Right(unit);
    } catch (e, stackTrace) {
      logger.e('Failed to sign in anonymously', error: e, stackTrace: stackTrace);
      return Left(ApiFailure('Lỗi đăng nhập ẩn danh: $e'));
    }
  }

  @override
  bool get isAuthenticated => _firebaseAuth.currentUser != null;
}
