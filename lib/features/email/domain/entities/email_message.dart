import 'package:equatable/equatable.dart';

class EmailMessage extends Equatable {
  final String subject;
  final String body;
  final String? otp;
  final DateTime receivedAt;

  const EmailMessage({
    required this.subject,
    required this.body,
    this.otp,
    required this.receivedAt,
  });

  @override
  List<Object?> get props => [subject, body, otp, receivedAt];
}
