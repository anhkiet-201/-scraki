import 'package:get_it/get_it.dart';

/// Retrieving or creating an instance of a registered type [T]
T inject<T extends Object>({
  String? instanceName,
  dynamic param1,
  dynamic param2,
}) {
  return GetIt.I.get<T>(
    instanceName: instanceName,
    param1: param1,
    param2: param2,
  );
}
