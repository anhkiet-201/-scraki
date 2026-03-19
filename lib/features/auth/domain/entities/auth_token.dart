import 'package:equatable/equatable.dart';

class AuthToken extends Equatable {
  final String id;
  final String name;
  final String issuer;
  final String secret;
  final int digits;
  final int period;

  const AuthToken({
    required this.id,
    required this.name,
    required this.issuer,
    required this.secret,
    this.digits = 6,
    this.period = 30,
  });

  @override
  List<Object?> get props => [id, name, issuer, secret, digits, period];

  AuthToken copyWith({
    String? id,
    String? name,
    String? issuer,
    String? secret,
    int? digits,
    int? period,
  }) {
    return AuthToken(
      id: id ?? this.id,
      name: name ?? this.name,
      issuer: issuer ?? this.issuer,
      secret: secret ?? this.secret,
      digits: digits ?? this.digits,
      period: period ?? this.period,
    );
  }
}
