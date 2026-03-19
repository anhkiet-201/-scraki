import 'package:scraki/features/auth/domain/entities/auth_token.dart';

class AuthTokenModel extends AuthToken {
  const AuthTokenModel({
    required super.id,
    required super.name,
    required super.issuer,
    required super.secret,
    super.digits = 6,
    super.period = 30,
  });

  factory AuthTokenModel.fromRawLine(String line) {
    final parts = line.split('|');
    return AuthTokenModel(
      id: parts[0].trim(),
      name: parts.length > 1 ? parts[1].trim() : '',
      issuer: parts.length > 2 ? parts[2].trim() : '',
      secret: parts.length > 3 ? parts[3].trim() : '',
      digits: parts.length > 4 ? int.tryParse(parts[4].trim()) ?? 6 : 6,
      period: parts.length > 5 ? int.tryParse(parts[5].trim()) ?? 30 : 30,
    );
  }

  String toRawLine() {
    return '$id|$name|$issuer|$secret|$digits|$period';
  }

  factory AuthTokenModel.fromEntity(AuthToken entity) {
    return AuthTokenModel(
      id: entity.id,
      name: entity.name,
      issuer: entity.issuer,
      secret: entity.secret,
      digits: entity.digits,
      period: entity.period,
    );
  }
}
