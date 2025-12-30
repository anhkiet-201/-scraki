import 'package:injectable/injectable.dart';
import 'package:process_run/shell.dart';
import '../../core/error/exceptions.dart';

abstract class IAdbRemoteDataSource {
  Future<String> getConnectedDevicesOutput();
  Future<void> connectTcp(String ip, int port);
  Future<void> disconnect(String serial);
}

@LazySingleton(as: IAdbRemoteDataSource)
class AdbRemoteDataSourceImpl implements IAdbRemoteDataSource {
  final Shell _shell;
  static const _cmdListDevices = 'adb devices -l';

  AdbRemoteDataSourceImpl() : _shell = Shell();

  @override
  Future<String> getConnectedDevicesOutput() async {
    try {
      final result = await _shell.run(_cmdListDevices);
      return result.outText;
    } catch (e) {
      throw ServerException('Failed to execute $_cmdListDevices: $e');
    }
  }

  @override
  Future<void> connectTcp(String ip, int port) async {
    final cmd = 'adb connect $ip:$port';
    try {
      final result = await _shell.run(cmd);
      final output = result.outText;
      if (output.runes.contains("unable") || output.contains("failed")) {
        throw ServerException(output);
      }
    } catch (e) {
      if (e is ServerException) rethrow; // rethrow formatted exception
      throw ServerException('Failed to execute $cmd: $e');
    }
  }

  @override
  Future<void> disconnect(String serial) async {
    final cmd = 'adb disconnect $serial';
    try {
      await _shell.run(cmd);
    } catch (e) {
      throw ServerException('Failed to execute $cmd: $e');
    }
  }
}
