import 'dart:async';
import 'dart:convert';
import 'dart:io';

class DeviceShell {
  Process? _process;
  int? get pid => _process?.pid;

  final _resultController = StreamController<DeviceShellResult>.broadcast();
  Stream<DeviceShellResult> get results => _resultController.stream;

  Future<void> start(String executable, {List<String> arguments = const []}) async {
    if (_process != null) {
      stop();
    }

    _process = await Process.start(executable, arguments);
    _process!.stdout.transform(utf8.decoder).listen((data) {
      _resultController.add(DeviceShellResult(
        logs: data,
        state: ShellState.running,
      ));
    });

    _process!.stderr.transform(utf8.decoder).listen((data) {
      _resultController.add(DeviceShellResult(
        logs: data,
        state: ShellState.error,
      ));
    });

    return _process!.exitCode.then((exitCode) {
      _resultController.add(DeviceShellResult(
        logs: 'Process exited with code: $exitCode - ${ShellState.fromCode(exitCode).message}',
        state: ShellState.fromCode(exitCode),
        exitCode: exitCode,
      ));
    });
  }

  void stop() {
    if(_process?.kill() ?? false) {
      _process = null;
    }
  }

  void dispose() {
    stop();
    _resultController.close();
  }
}

class DeviceShellResult {
  final String logs;
  final ShellState state;
  final int? exitCode;

  DeviceShellResult({
    required this.logs,
    this.exitCode,
    required this.state,
  });
}

enum ShellState {
  running,
  success,
  canceled,
  error,
  stopped;

  factory ShellState.fromCode(int code) => switch(code){
    < 0 || 1 => ShellState.canceled,
    0 => ShellState.success,
    99 => ShellState.stopped,
    _ => ShellState.error,
  };

  String get message => switch(this){
    ShellState.running => 'Running...',
    ShellState.success => 'Success!',
    ShellState.canceled => 'Canceled',
    ShellState.error => 'Error!',
    ShellState.stopped => 'Stopped by user',
  };
}