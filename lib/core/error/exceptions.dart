class ServerException implements Exception {
  final String message;
  ServerException(this.message);
}

class DeviceNotFoundException implements Exception {
  final String message;
  DeviceNotFoundException(this.message);
}

class AkiRemoteException implements Exception {
  final String message;
  AkiRemoteException(this.message);

  @override
  String toString() => 'AkiRemoteException: $message';
}
