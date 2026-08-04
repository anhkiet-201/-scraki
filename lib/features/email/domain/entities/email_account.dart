import 'package:equatable/equatable.dart';

class EmailAccount extends Equatable {
  final String username;
  final String email;
  final String password;
  final String refreshToken;
  final String clientId;
  final String? accessToken;

  const EmailAccount({
    required this.username,
    required this.email,
    required this.password,
    required this.refreshToken,
    required this.clientId,
    this.accessToken,
  });

  /// Chuyển đổi email thành ID an toàn cho Firestore (thay . bằng _)
  String get docId => email.trim().toLowerCase().replaceAll('.', '_');

  Map<String, dynamic> toFirestore() {
    return {
      'username': username.trim(),
      'email': email.trim(),
      'password': password.trim(),
      'refreshToken': refreshToken.trim(),
      'clientId': clientId.trim(),
      if (accessToken != null) 'accessToken': accessToken!.trim(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  factory EmailAccount.fromFirestore(Map<String, dynamic> map) {
    return EmailAccount(
      username: map['username'] as String? ?? '',
      email: map['email'] as String? ?? '',
      password: map['password'] as String? ?? '',
      refreshToken: map['refreshToken'] as String? ?? '',
      clientId: map['clientId'] as String? ?? '',
      accessToken: map['accessToken'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        username,
        email,
        password,
        refreshToken,
        clientId,
        accessToken,
      ];

  EmailAccount copyWith({
    String? username,
    String? email,
    String? password,
    String? refreshToken,
    String? clientId,
    String? accessToken,
  }) {
    return EmailAccount(
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      refreshToken: refreshToken ?? this.refreshToken,
      clientId: clientId ?? this.clientId,
      accessToken: accessToken ?? this.accessToken,
    );
  }
}
