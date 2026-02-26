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
  Future<void> assignEmailToDeviceAndStartStream({
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
          return;
        }
      }

      // Save the resolved email to device group via DeviceStore or similar?
      // -> Will be handled by the caller since EmailStore shouldn't know about Settings device group collection directly to avoid circular dependency.
      // We will just return successful here or initiate IMAP.

      await startImapStream(resolvedEmail);
    } catch (e) {
      errorMessage = 'Lỗi hệ thống: $e';
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> startImapStream(String email) async {
    isLoading = true;
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
            });
          },
        );

    isLoading = false;
  }

  void dispose() {
    _emailSubscription?.cancel();
  }
}
