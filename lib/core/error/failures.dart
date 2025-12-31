abstract class Failure {
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;

  const Failure(this.message, [this.error, this.stackTrace]);

  List<Object?> get props => [message, error, stackTrace];
}

class AdbFailure extends Failure {
  const AdbFailure(super.message, [super.error, super.stackTrace]);
}

class DeviceNotFoundFailure extends Failure {
  const DeviceNotFoundFailure(super.message, [super.error, super.stackTrace]);
}

class ConnectionFailure extends Failure {
  const ConnectionFailure(super.message, [super.error, super.stackTrace]);
}
