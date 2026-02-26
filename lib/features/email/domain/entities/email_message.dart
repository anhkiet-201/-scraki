import 'package:equatable/equatable.dart';

class EmailMessage extends Equatable {
  final String subject;
  final String? otp;
  final DateTime receivedAt;

  const EmailMessage({
    required this.subject,
    this.otp,
    required this.receivedAt,
  });

  @override
  List<Object?> get props => [subject, otp, receivedAt];
}
