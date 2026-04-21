import 'package:scraki/features/email/domain/entities/email_account.dart';

class PaginatedEmailResult {
  final List<EmailAccount> accounts;
  final String? lastUpdate;

  PaginatedEmailResult({
    required this.accounts,
    required this.lastUpdate,
  });
}
