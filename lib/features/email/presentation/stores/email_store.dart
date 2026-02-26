import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
import 'package:scraki/core/error/failures.dart';
import 'package:scraki/features/device/domain/repositories/device_repository.dart';
import 'package:scraki/features/email/domain/entities/email_account.dart';
import 'package:scraki/features/email/domain/entities/email_message.dart';
import 'package:scraki/features/email/domain/repositories/i_email_repository.dart';

part 'email_store.g.dart';

@injectable
class EmailStore = _EmailStore with _$EmailStore;

abstract class _EmailStore with Store {
  final IEmailRepository _emailRepository;
  final DeviceRepository _deviceRepository;

  _EmailStore(this._emailRepository, this._deviceRepository);

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
      String resolvedEmail = targetEmail;

      // Dump UI if email is not provided
      if (requireDump || targetEmail.isEmpty) {
        final dumpEither = await _deviceRepository.dumpUiAndExtractEmail(
          deviceSerial,
        );
        dumpEither.fold(
          (failure) {
            errorMessage = 'Lỗi dump lấy email: ${failure.message}';
          },
          (extractedEmail) {
            if (extractedEmail != null && extractedEmail.isNotEmpty) {
              resolvedEmail = extractedEmail;
              targetEmail = resolvedEmail;
            } else {
              errorMessage = 'Không tìm thấy email trên màn hình.';
            }
          },
        );

        if (errorMessage != null) {
          isLoading = false;
          return null;
        }
      }

      return resolvedEmail;
    } catch (e) {
      errorMessage = 'Lỗi hệ thống: $e';
      return null;
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> startImapStream(String email) async {
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
          errorMessage = 'Chưa thiết lập config trên Firebase.';
          return;
        }

        try {
          matchedAccount = accounts.firstWhere(
            (acc) => acc.email.toLowerCase() == email.toLowerCase(),
          );
        } catch (_) {
          errorMessage =
              'Không tìm thấy tài khoản $email trong danh sách config Firebase.';
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
          email: matchedAccount!.email,
          clientId: matchedAccount!.clientId,
          refreshToken: matchedAccount!.refreshToken,
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
