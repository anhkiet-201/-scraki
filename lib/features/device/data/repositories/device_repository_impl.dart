import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/adb_output_parser.dart';
import '../../domain/entities/device_entity.dart';
import '../../domain/repositories/device_repository.dart';
import '../datasources/adb_remote_data_source.dart';

@LazySingleton(as: DeviceRepository)
class DeviceRepositoryImpl implements DeviceRepository {
  final IAdbRemoteDataSource _remoteDataSource;

  DeviceRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<DeviceEntity>>> getConnectedDevices() async {
    try {
      final output = await _remoteDataSource.getConnectedDevicesOutput();
      
      // Chạy Parsing ở Isolate để tránh block UI khi lượng device lớn [Rule #10]
      final List<DeviceEntity> devices = await compute<String, List<DeviceEntity>>(AdbOutputParser.parseDevices, output);

      // Chạy việc lấy tên đồng loạt ở Isolate để tránh hàng trăm process manager callbacks làm treo Main UI [Rule #10]
      final List<DeviceEntity> namedDevices = await compute<_NameFetchInput, List<DeviceEntity>>(
        _fetchDeviceNames,
        _NameFetchInput(devices),
      );

      return Right(namedDevices);
    } on ServerException catch (e) {
      return Left(AdbFailure(e.message));
    } catch (e) {
      return Left(const AdbFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, Unit>> connectTcp(String ip, int port) async {
    try {
      await _remoteDataSource.connectTcp(ip, port);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ConnectionFailure(e.message));
    } catch (e) {
      return Left(const ConnectionFailure('Unexpected connection error'));
    }
  }

  @override
  Future<Either<Failure, Unit>> disconnectDevice(String serial) async {
    try {
      await _remoteDataSource.disconnect(serial);
      return const Right(unit);
    } catch (e) {
      return Left(AdbFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> restartAdb() async {
    try {
      await _remoteDataSource.restartServer();
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(AdbFailure(e.message));
    } catch (e) {
      return Left(const AdbFailure('Unexpected error during ADB restart'));
    }
  }

  @override
  Future<Either<Failure, String?>> dumpUiAndExtractEmail(String serial) async {
    try {
      final email = await _remoteDataSource.dumpUiAndExtractEmail(serial);
      return Right(email);
    } on ServerException catch (e) {
      return Left(AdbFailure(e.message));
    } catch (e) {
      return Left(const AdbFailure('Unexpected error extracting email'));
    }
  }

  @override
  Future<Either<Failure, Unit>> inputText(String serial, String text) async {
    try {
      await _remoteDataSource.inputText(serial, text);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(AdbFailure(e.message));
    } catch (e) {
      return Left(const AdbFailure('Unexpected error inputting text'));
    }
  }
}

class _NameFetchInput {
  final List<DeviceEntity> devices;
  _NameFetchInput(this.devices);
}

/// Hàm tĩnh chạy ở Isolate để lấy tên hàng loạt thiết bị [Rule #10, #31]
Future<List<DeviceEntity>> _fetchDeviceNames(_NameFetchInput input) async {
  final results = <DeviceEntity>[];
  final devices = input.devices;
  
  // Chia nhỏ danh sách để xử lý theo đợt (batch), tránh overload ADB server [Rule #10, #21]
  const batchSize = 10;
  for (var i = 0; i < devices.length; i += batchSize) {
    final end = (i + batchSize < devices.length) ? i + batchSize : devices.length;
    final batch = devices.sublist(i, end);
    
    final batchResults = await Future.wait(
      batch.map((device) async {
        // Chỉ lấy tên cho thiết bị đã kết nối và chưa có tên cụ thể
        if (device.status != DeviceStatus.connected) return device;

        try {
          final result = await Process.run('adb', [
            '-s',
            device.serial,
            'shell',
            'settings',
            'get',
            'global',
            'device_name',
          ]).timeout(const Duration(seconds: 2));

          final name = (result.stdout as String).trim();
          if (name.isEmpty || name == 'null') return device;
          return device.copyWith(modelName: name);
        } catch (_) {
          return device;
        }
      }),
    );
    results.addAll(batchResults);
    
    // Nghỉ một chút giữa các batch để ADB server "thở"
    if (end < devices.length) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }
  
  return results;
}
