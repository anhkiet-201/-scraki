class ServerException implements Exception {
  final String message;
  ServerException(this.message);
}

class DeviceNotFoundException implements Exception {
  final String message;
  DeviceNotFoundException(this.message);
}
