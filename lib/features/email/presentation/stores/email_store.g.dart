// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'email_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$EmailStore on _EmailStore, Store {
  late final _$isLoadingAtom = Atom(
    name: '_EmailStore.isLoading',
    context: context,
  );

  @override
  bool get isLoading {
    _$isLoadingAtom.reportRead();
    return super.isLoading;
  }

  @override
  set isLoading(bool value) {
    _$isLoadingAtom.reportWrite(value, super.isLoading, () {
      super.isLoading = value;
    });
  }

  late final _$errorMessageAtom = Atom(
    name: '_EmailStore.errorMessage',
    context: context,
  );

  @override
  String? get errorMessage {
    _$errorMessageAtom.reportRead();
    return super.errorMessage;
  }

  @override
  set errorMessage(String? value) {
    _$errorMessageAtom.reportWrite(value, super.errorMessage, () {
      super.errorMessage = value;
    });
  }

  late final _$targetEmailAtom = Atom(
    name: '_EmailStore.targetEmail',
    context: context,
  );

  @override
  String get targetEmail {
    _$targetEmailAtom.reportRead();
    return super.targetEmail;
  }

  @override
  set targetEmail(String value) {
    _$targetEmailAtom.reportWrite(value, super.targetEmail, () {
      super.targetEmail = value;
    });
  }

  late final _$messagesAtom = Atom(
    name: '_EmailStore.messages',
    context: context,
  );

  @override
  ObservableList<EmailMessage> get messages {
    _$messagesAtom.reportRead();
    return super.messages;
  }

  @override
  set messages(ObservableList<EmailMessage> value) {
    _$messagesAtom.reportWrite(value, super.messages, () {
      super.messages = value;
    });
  }

  late final _$assignEmailToDeviceAndStartStreamAsyncAction = AsyncAction(
    '_EmailStore.assignEmailToDeviceAndStartStream',
    context: context,
  );

  @override
  Future<void> assignEmailToDeviceAndStartStream({
    required String deviceSerial,
    required bool requireDump,
  }) {
    return _$assignEmailToDeviceAndStartStreamAsyncAction.run(
      () => super.assignEmailToDeviceAndStartStream(
        deviceSerial: deviceSerial,
        requireDump: requireDump,
      ),
    );
  }

  late final _$startImapStreamAsyncAction = AsyncAction(
    '_EmailStore.startImapStream',
    context: context,
  );

  @override
  Future<void> startImapStream(String email) {
    return _$startImapStreamAsyncAction.run(() => super.startImapStream(email));
  }

  late final _$_EmailStoreActionController = ActionController(
    name: '_EmailStore',
    context: context,
  );

  @override
  void setTargetEmail(String email) {
    final _$actionInfo = _$_EmailStoreActionController.startAction(
      name: '_EmailStore.setTargetEmail',
    );
    try {
      return super.setTargetEmail(email);
    } finally {
      _$_EmailStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
isLoading: ${isLoading},
errorMessage: ${errorMessage},
targetEmail: ${targetEmail},
messages: ${messages}
    ''';
  }
}
