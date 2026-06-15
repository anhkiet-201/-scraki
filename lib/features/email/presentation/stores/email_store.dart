import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
import 'package:scraki/core/error/failures.dart';
import 'package:scraki/core/utils/logger.dart';
import 'package:scraki/features/device/domain/repositories/device_repository.dart';
import 'package:scraki/features/device/domain/services/i_aki_remote_service.dart';
import 'package:scraki/features/email/domain/entities/email_account.dart';
import 'package:scraki/features/email/domain/entities/email_message.dart';
import 'package:scraki/features/email/domain/repositories/i_email_repository.dart';

part 'email_store.g.dart';

@injectable
class EmailStore = _EmailStore with _$EmailStore;

abstract class _EmailStore with Store {
  final IEmailRepository _emailRepository;
  final DeviceRepository _deviceRepository;
  final IAkiRemoteService _akiRemote;

  _EmailStore(this._emailRepository, this._deviceRepository, this._akiRemote);

  static final _emailRegex = RegExp(
    r'[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}',
  );

  @observable
  bool isLoading = false;

  @observable
  bool isListening = false;

  @observable
  String? errorMessage;

  @observable
  String targetEmail = '';

  @observable
  ObservableList<EmailMessage> messages = ObservableList<EmailMessage>();

  StreamSubscription<Either<Failure, EmailMessage>>? _emailSubscription;

  @action
  void setTargetEmail(String email) {
    targetEmail = email;
  }

  @action
  Future<String?> assignEmailToDevice({
    required String deviceSerial,
    required bool requireDump,
  }) async {
    isLoading = true;
    errorMessage = null;

    try {
      String resolvedEmail = targetEmail.trim();

      // Lấy email từ màn hình qua aki_remote nếu chưa nhập
      if (requireDump || targetEmail.isEmpty) {
        try {
          await _akiRemote.ensureServerPushed(deviceSerial);

          // Bước 1: get text-contains:@ — nhanh, chính xác, nhắm thẳng element
          final candidate = await _akiRemote.get(
            deviceSerial,
            AkiSelector.textContains('@'),
          );

          if (candidate != null && _emailRegex.hasMatch(candidate)) {
            // Trích email từ text (có thể có ký tự thừa xung quanh)
            resolvedEmail = _emailRegex.firstMatch(candidate)!.group(0)!;
            targetEmail = resolvedEmail;
          } else {
            // Bước 2: fallback dump toàn bộ XML → parse regex
            final xmlDump = await _akiRemote.dump(deviceSerial);
            final match = _emailRegex.firstMatch(xmlDump);
            if (match != null) {
              resolvedEmail = match.group(0)!;
              targetEmail = resolvedEmail;
            } else {
              errorMessage = 'Không tìm thấy email trên màn hình.';
            }
          }
        } catch (e) {
          errorMessage = 'Lỗi lấy email: $e';
        }

        if (errorMessage != null) {
          isLoading = false;
          return null;
        }
      }

      return resolvedEmail.trim();
    } catch (e) {
      errorMessage = 'Lỗi hệ thống: $e';
      return null;
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> startImapStream(String email) async {
    final searchEmail = email.trim().toLowerCase();
    logger.i('[EmailStore] Bắt đầu Stream tìm kiếm: $searchEmail');

    isLoading = true;
    isListening = false;
    errorMessage = null;

    // Fetch accounts from firebase
    final accountsEither = await _emailRepository.getEmailAccounts();
    EmailAccount? matchedAccount;
    
    accountsEither.fold(
      (failure) {
        errorMessage = 'Không lấy được Firebase config: ${failure.message}';
      },
      (accounts) {
        if (accounts.isEmpty) {
          logger.w('[EmailStore] Danh sách config Firebase trống.');
          errorMessage = 'Chưa thiết lập config trên Firebase.';
          return;
        }

        logger.i('[EmailStore] Đã tải ${accounts.length} tài khoản từ Firebase.');
        
        try {
          matchedAccount = accounts.firstWhere(
            (acc) {
              final accEmail = acc.email.trim().toLowerCase();
              return accEmail == searchEmail;
            },
          );
          logger.i('[EmailStore] Tìm thấy tài khoản phù hợp: ${matchedAccount!.username}');
        } catch (_) {
          errorMessage =
              'Không tìm thấy tài khoản $searchEmail trong danh sách config Firebase (${accounts.length} items).';
          logger.e('[EmailStore] $errorMessage');
          // Log vài cái tiêu biểu để kiểm tra format
          for (var i = 0; i < (accounts.length > 3 ? 3 : accounts.length); i++) {
            logger.d('   - Item $i: ${accounts[i].email}');
          }
        }
      },
    );

    if (errorMessage != null || matchedAccount == null) {
      isLoading = false;
      return;
    }

    _emailSubscription?.cancel();
    _emailSubscription = _emailRepository
        .streamLatestEmails(
          account: matchedAccount!,
        )
        .listen(
          (eitherMsg) {
            eitherMsg.fold(
              (failure) {
                runInAction(() {
                  errorMessage = 'Lỗi Stream: ${failure.message}';
                });
              },
              (msg) {
                runInAction(() {
                  messages.insert(0, msg);
                  if (messages.length > 20) {
                    messages.removeLast();
                  }
                });
              },
            );
          },
          onError: (dynamic e) {
            runInAction(() {
              errorMessage = 'Lỗi ngắt Stream: $e';
              isListening = false;
            });
          },
          onDone: () {
            runInAction(() {
              isListening = false;
            });
          },
        );

    isListening = true;
    isLoading = false;
  }

  void dispose() {
    _emailSubscription?.cancel();
    isListening = false;
  }

  @action
  Future<void> sendOtpToDevice(String deviceSerial, String otp) async {
    try {
      final either = await _deviceRepository.inputText(deviceSerial, otp);
      either.fold(
        (failure) {
          runInAction(() {
            errorMessage = 'Lỗi gửi OTP qua ADB: ${failure.message}';
          });
        },
        (_) {
          // Success, do nothing
        },
      );
    } catch (e) {
      runInAction(() {
        errorMessage = 'Lỗi hệ thống khi gửi OTP qua ADB: $e';
      });
    }
  }
}
