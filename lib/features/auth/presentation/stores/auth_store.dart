import 'dart:async';
import 'package:dart_dash_otp/dart_dash_otp.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/auth_token.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../../device/domain/services/i_aki_remote_service.dart';

part 'auth_store.g.dart';

@lazySingleton
class AuthStore = _AuthStoreBase with _$AuthStore;

abstract class _AuthStoreBase with Store {
  final IAuthRepository _repository;
  final IAkiRemoteService _akiRemoteService;

  _AuthStoreBase(this._repository, this._akiRemoteService);

  @action
  void init() {
    _startTimer();
    // loadTokens(); // Không nạp global nữa, AuthPanel sẽ gọi loadTokens với serial
  }

  @observable
  ObservableList<AuthToken> tokens = ObservableList<AuthToken>();

  @observable
  bool isLoading = false;

  @observable
  String? errorMessage;

  @observable
  int secondsRemaining = 30;

  @observable
  ObservableMap<String, String> currentCodes = ObservableMap<String, String>();

  Timer? _timer;

  @action
  Future<void> loadTokens(String groupCollection, String serial) async {
    isLoading = true;
    errorMessage = null;
    try {
      final result = await _repository.getAuthTokens(groupCollection, serial).timeout(
        const Duration(seconds: 10),
        onTimeout: () => Left(ApiFailure('Request timed out (10s)')),
      );
      result.fold(
        (failure) => errorMessage = failure.message,
        (loadedTokens) {
          tokens.clear();
          tokens.addAll(loadedTokens);
          _updateCodes();
        },
      );
    } catch (e) {
      errorMessage = 'Unexpected error: $e';
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> addToken(
    String groupCollection,
    String serial,
    String name,
    String issuer,
    String secret,
  ) async {
    isLoading = true;
    errorMessage = null;
    try {
      final token = AuthToken(
        id: const Uuid().v4(),
        name: name,
        issuer: issuer,
        secret: secret,
      );
      final result = await _repository
          .addAuthToken(groupCollection, serial, token)
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () => Left(ApiFailure('Request timed out (10s)')),
      );
      result.fold(
        (failure) => errorMessage = failure.message,
        (_) => loadTokens(groupCollection, serial),
      );
    } catch (e) {
      errorMessage = 'Unexpected error: $e';
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> deleteToken(
    String groupCollection,
    String serial,
    String id,
  ) async {
    isLoading = true;
    errorMessage = null;
    try {
      final result = await _repository
          .deleteAuthToken(groupCollection, serial, id)
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () => Left(ApiFailure('Request timed out (10s)')),
      );
      result.fold(
        (failure) => errorMessage = failure.message,
        (_) => loadTokens(groupCollection, serial),
      );
    } catch (e) {
      errorMessage = 'Unexpected error: $e';
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> captureFromScreen(String groupCollection, String serial) async {
    isLoading = true;
    errorMessage = null;
    try {
      await _akiRemoteService.ensureServerPushed(serial);

      // Theo yêu cầu mới: Tìm tất cả các text và lọc chuỗi 32 ký tự không khoảng trắng
      // Lệnh dump là cách duy nhất để lấy toàn bộ danh sách text
      final xmlDump = await _akiRemoteService.dump(serial);
      
      // Tìm tất cả các giá trị trong thuộc tính text="..." hoặc content-desc="..."
      final textRegex = RegExp(r'(?:text|content-desc)="([^"]*)"');
      final matches = textRegex.allMatches(xmlDump);

      for (final match in matches) {
        final text = match.group(1)?.trim() ?? '';
        // Loại bỏ khoảng trắng để kiểm tra độ dài và định dạng Base32
        final cleanText = text.replaceAll(' ', '');
        
        if (cleanText.length == 32 && RegExp(r'^[A-Z2-7]{32}$').hasMatch(cleanText)) {
          await addToken(
            groupCollection,
            serial,
            'Captured Account',
            'Captured Issuer',
            cleanText,
          );
          return;
        }
      }

      errorMessage = 'Không tìm thấy mã Secret Key (32 ký tự) trên màn hình.';
    } catch (e) {
      errorMessage = 'Lỗi khi quét màn hình: $e';
    } finally {
      isLoading = false;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final nowSeconds = now.millisecondsSinceEpoch ~/ 1000;
      
      // Tính toán giây còn lại trong chu kỳ 30s
      final newSecondsRemaining = 30 - (nowSeconds % 30);
      
      // Nếu nhảy sang chu kỳ mới (secondsRemaining tăng lên hoặc hiện tại là 30)
      // Hoặc nếu chưa có code nào, thì cập nhật
      if (newSecondsRemaining > secondsRemaining || currentCodes.isEmpty) {
        _updateCodes();
      }
      
      // Cập nhật observable để UI đếm ngược
      secondsRemaining = newSecondsRemaining;
    });
  }

  @action
  void _updateCodes() {
    final codes = <String, String>{};
    for (var token in tokens) {
      try {
        final totp = TOTP(
          secret: token.secret,
          digits: token.digits,
          interval: token.period,
        );
        codes[token.id] = totp.now();
      } catch (e) {
        logger.e('Error generating TOTP for ${token.name}: $e');
        codes[token.id] = 'ERROR';
      }
    }
    
    runInAction(() {
      currentCodes.addAll(codes);
      // Xóa các id cũ không còn trong tokens nếu cần
      final currentKeys = currentCodes.keys.toList();
      for (var key in currentKeys) {
        if (!codes.containsKey(key)) {
          currentCodes.remove(key);
        }
      }
    });
  }

  void dispose() {
    _timer?.cancel();
  }
}
