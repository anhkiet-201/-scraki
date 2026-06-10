import 'package:injectable/injectable.dart';
import 'package:scraki/features/script/domain/interpolation/variables/index_variable.dart';
import 'package:scraki/features/script/domain/interpolation/variables/random_variable.dart';
import 'package:scraki/features/script/domain/interpolation/variables/spilit_string_variable.dart';
import '../../features/script/domain/interpolation/command_interpolator.dart';
import '../../features/script/domain/interpolation/variables/input_variable.dart';
import '../../features/script/domain/interpolation/variables/multi_input_variable.dart';
import '../../features/script/domain/interpolation/variables/octet_variable.dart';
import '../../features/script/domain/interpolation/variables/serial_variable.dart';

@module
abstract class InterpolationModule {
  @singleton
  CommandInterpolator provideCommandInterpolator() {
    return CommandInterpolator([
      SerialVariable(),
      OctetVariable(),
      IndexVariable(),
      InputVariable(),
      MultiInputVariable(),
      RandomVariable(),
      SplitStringVariable(),
    ]);
  }
}
