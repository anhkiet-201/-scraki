import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:scraki/data/repositories/device_repository_impl.dart';
import 'package:scraki/data/datasources/adb_remote_data_source.dart';
import 'package:scraki/core/error/exceptions.dart';
import 'package:scraki/core/error/failures.dart';
import 'package:scraki/domain/entities/device_entity.dart';

class MockAdbRemoteDataSource extends Mock implements IAdbRemoteDataSource {}

void main() {
  late DeviceRepositoryImpl repository;
  late MockAdbRemoteDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockAdbRemoteDataSource();
    repository = DeviceRepositoryImpl(mockDataSource);
  });

  group('getConnectedDevices', () {
    test(
      'should return list of devices when remote data source is successful',
      () async {
        // Arrange
        const adbOutput = '''
List of devices attached
RFCT409L2LB            device product:SM_G998B model:SM_G998B device:p3s transport_id:1
''';
        // CORRECTED: call getConnectedDevicesOutput on mock
        when(
          () => mockDataSource.getConnectedDevicesOutput(),
        ).thenAnswer((_) async => adbOutput);

        // Act
        final result = await repository.getConnectedDevices();

        // Assert
        expect(result.isRight(), true);
        result.fold((failure) => fail('Should not return failure'), (devices) {
          expect(devices.length, 1);
          expect(devices.first.serial, 'RFCT409L2LB');
          expect(devices.first.modelName, 'SM_G998B');
        });
        verify(() => mockDataSource.getConnectedDevicesOutput()).called(1);
      },
    );

    test(
      'should return AdbFailure when remote data source throws ServerException',
      () async {
        // Arrange
        // CORRECTED: call getConnectedDevicesOutput on mock
        when(
          () => mockDataSource.getConnectedDevicesOutput(),
        ).thenThrow(ServerException('ADB Error'));

        // Act
        final result = await repository.getConnectedDevices();

        // Assert
        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<AdbFailure>());
          expect(failure.message, 'ADB Error');
        }, (_) => fail('Should not return success'));
        verify(() => mockDataSource.getConnectedDevicesOutput()).called(1);
      },
    );
  });
}
