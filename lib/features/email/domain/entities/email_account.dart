import 'package:equatable/equatable.dart';

class EmailAccount extends Equatable {
  final String username;
  final String email;
  final String password;
  final String refreshToken;
  final String clientId;

  const EmailAccount({
    required this.username,
    required this.email,
    required this.password,
    required this.refreshToken,
    required this.clientId,
  });

  @override
  List<Object?> get props => [
    username,
    email,
    password,
    refreshToken,
    clientId,
  ];
}
