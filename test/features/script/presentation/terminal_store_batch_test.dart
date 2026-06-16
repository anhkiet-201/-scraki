import 'package:flutter_test/flutter_test.dart';
import 'package:scraki/features/script/presentation/utils/script_execution_parser.dart';
import 'package:scraki/features/script/domain/entities/script_entity.dart';


void main() {
  group('ScriptExecutionParser Tests', () {
    test('Parse script containing only single adb commands', () {
      final commands = [
        'input tap 100 200',
        'input keyevent 3',
        'sleep 1',
      ];

      final blocks = ScriptExecutionParser.parse(commands);

      expect(blocks.length, equals(3));
      expect(blocks[0], isA<SingleCommandBlock>());
      expect((blocks[0] as SingleCommandBlock).command, equals('input tap 100 200'));
      expect(blocks[1], isA<SingleCommandBlock>());
      expect(blocks[2], isA<SingleCommandBlock>());
    });

    test('Parse script containing bash block starting with #Bash', () {
      final commands = [
        'input tap 100 200',
        '#Bash',
        'DELAY=10',
        r'echo "Delay is $DELAY"',
        '#EndBash',
        'input keyevent 4',
      ];

      final blocks = ScriptExecutionParser.parse(commands);

      expect(blocks.length, equals(3));
      expect(blocks[0], isA<SingleCommandBlock>());
      expect((blocks[0] as SingleCommandBlock).command, equals('input tap 100 200'));

      expect(blocks[1], isA<BashScriptBlock>());
      final bashBlock = blocks[1] as BashScriptBlock;
      expect(bashBlock.commands.length, equals(2));
      expect(bashBlock.commands[0], equals('DELAY=10'));
      expect(bashBlock.commands[1], equals(r'echo "Delay is $DELAY"'));

      expect(blocks[2], isA<SingleCommandBlock>());
      expect((blocks[2] as SingleCommandBlock).command, equals('input keyevent 4'));
    });

    test('Parse script with implicit bash block closure at the end', () {
      final commands = [
        '#bash',
        'MY_VAR="hello"',
        r'echo $MY_VAR',
      ];

      final blocks = ScriptExecutionParser.parse(commands);

      expect(blocks.length, equals(1));
      expect(blocks[0], isA<BashScriptBlock>());
      final bashBlock = blocks[0] as BashScriptBlock;
      expect(bashBlock.commands.length, equals(2));
      expect(bashBlock.commands[0], equals('MY_VAR="hello"'));
      expect(bashBlock.commands[1], equals(r'echo $MY_VAR'));
    });

    test('Parse script skipping empty lines and comments outside bash block but keeping them inside', () {
      final commands = [
        '  ',
        '# comment outside',
        'input tap 100 200',
        '#bash',
        '# comment inside bash',
        'echo "inside"',
        '  ',
        '#EndBash',
        '# comment outside 2',
      ];

      final blocks = ScriptExecutionParser.parse(commands);

      expect(blocks.length, equals(2));
      expect(blocks[0], isA<SingleCommandBlock>());
      expect((blocks[0] as SingleCommandBlock).command, equals('input tap 100 200'));

      expect(blocks[1], isA<BashScriptBlock>());
      final bashBlock = blocks[1] as BashScriptBlock;
      expect(bashBlock.commands.length, equals(3));
      expect(bashBlock.commands[0], equals('# comment inside bash'));
      expect(bashBlock.commands[1], equals('echo "inside"'));
      expect(bashBlock.commands[2], equals('  '));
    });

    test('Parse script containing bash block with leading \$ prefix on labels', () {
      final commands = [
        '\$ #Bash',
        'DELAY=5',
        r'echo $DELAY',
        '\$#EndBash',
      ];

      final blocks = ScriptExecutionParser.parse(commands);

      expect(blocks.length, equals(1));
      expect(blocks[0], isA<BashScriptBlock>());
      final bashBlock = blocks[0] as BashScriptBlock;
      expect(bashBlock.commands.length, equals(2));
      expect(bashBlock.commands[0], equals('DELAY=5'));
      expect(bashBlock.commands[1], equals(r'echo $DELAY'));
    });

    test('Parse script containing server bash block and lowercase end labels', () {
      final commands = [
        'input tap 100 200',
        '#bash server',
        'echo "running on server"',
        'dir',
        '#end bash',
        '#Bash',
        'echo "running on android"',
        '#end',
      ];

      final blocks = ScriptExecutionParser.parse(commands);

      expect(blocks.length, equals(3));
      expect(blocks[0], isA<SingleCommandBlock>());
      expect((blocks[0] as SingleCommandBlock).command, equals('input tap 100 200'));

      expect(blocks[1], isA<ServerBashScriptBlock>());
      final serverBlock = blocks[1] as ServerBashScriptBlock;
      expect(serverBlock.commands.length, equals(2));
      expect(serverBlock.commands[0], equals('echo "running on server"'));
      expect(serverBlock.commands[1], equals('dir'));

      expect(blocks[2], isA<BashScriptBlock>());
      final androidBlock = blocks[2] as BashScriptBlock;
      expect(androidBlock.commands.length, equals(1));
      expect(androidBlock.commands[0], equals('echo "running on android"'));
    });

    test('Flatten sub-script with simple import', () {
      final parentCommands = [
        '#import sub_test',
      ];
      final subScript = ScriptEntity(
        id: '1',
        name: 'sub_test',
        description: 'test description',
        commands: [
          'echo "Hello"',
          'echo "World"',
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final flattened = ScriptExecutionParser.flatten(parentCommands, [subScript]);

      expect(flattened.length, equals(2));
      expect(flattened[0], equals('echo "Hello"'));
      expect(flattened[1], equals('echo "World"'));
    });

    test('Flatten sub-script with environment labels inside parent environment block', () {
      final parentCommands = [
        '#bash server',
        'if (\$true) {',
        '  #import sub_test',
        '}',
        '#end',
      ];
      final subScript = ScriptEntity(
        id: '1',
        name: 'sub_test',
        description: 'test description',
        commands: [
          '#bash server',
          'echo "hello"',
          '#end',
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final flattened = ScriptExecutionParser.flatten(parentCommands, [subScript]);

      expect(flattened.length, equals(5));
      expect(flattened[0], equals('#bash server'));
      expect(flattened[1], equals('if (\$true) {'));
      expect(flattened[2], equals('echo "hello"'));
      expect(flattened[3], equals('}'));
      expect(flattened[4], equals('#end'));
    });

    test('Flatten #import client inside #bash server without parameters', () {
      final parentCommands = [
        '#bash server',
        '#import client sub_test',
        '#end',
      ];
      final subScript = ScriptEntity(
        id: '2',
        name: 'sub_test',
        description: 'test description',
        commands: [
          'input tap 100 200',
          'sleep 1',
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final flattened = ScriptExecutionParser.flatten(parentCommands, [subScript]);

      expect(flattened.length, equals(6));
      expect(flattened[0], equals('#bash server'));
      expect(flattened[1], equals("@'"));
      expect(flattened[2], equals('input tap 100 200'));
      expect(flattened[3], equals('sleep 1'));
      expect(flattened[4], equals("'@ | adb -s {SERIAL} shell sh"));
      expect(flattened[5], equals('#end'));
    });

    test('Flatten #import client inside #bash server with parameters', () {
      final parentCommands = [
        '#bash server',
        '#import client sub_test "Tuan An" 20',
        '#end',
      ];
      final subScript = ScriptEntity(
        id: '3',
        name: 'sub_test',
        description: 'test description',
        commands: [
          r'echo "Hello $1"',
          r'echo "Age is $2"',
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final flattened = ScriptExecutionParser.flatten(parentCommands, [subScript]);

      expect(flattened.length, equals(6));
      expect(flattened[0], equals('#bash server'));
      expect(flattened[1], equals("@'"));
      expect(flattened[2], equals(r'echo "Hello $1"'));
      expect(flattened[3], equals(r'echo "Age is $2"'));
      expect(flattened[4], equals("'@ | adb -s {SERIAL} shell \"sh -s 'Tuan An' '20'\""));
      expect(flattened[5], equals('#end'));
    });

    test('Flatten #import and #import client with double-quoted script name containing whitespaces', () {
      final parentCommands = [
        '#bash server',
        '#import client "Auto Post" "test_arg"',
        '#import "Normal Script"',
        '#end',
      ];
      final subScript1 = ScriptEntity(
        id: '3',
        name: 'Auto Post',
        description: 'test description',
        commands: [
          r'echo "Hello $1"',
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final subScript2 = ScriptEntity(
        id: '4',
        name: 'Normal Script',
        description: 'test description',
        commands: [
          '#bash server',
          'Write-Output "Normal script run"',
          '#end',
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final flattened = ScriptExecutionParser.flatten(parentCommands, [subScript1, subScript2]);

      expect(flattened.length, equals(6));
      expect(flattened[0], equals('#bash server'));
      expect(flattened[1], equals("@'"));
      expect(flattened[2], equals(r'echo "Hello $1"'));
      expect(flattened[3], equals("'@ | adb -s {SERIAL} shell \"sh -s 'test_arg'\""));
      expect(flattened[4], equals('Write-Output "Normal script run"'));
      expect(flattened[5], equals('#end'));
    });

    test('Flatten #import client with single-quoted script name containing whitespaces', () {
      final parentCommands = [
        '#bash server',
        "#import client 'Auto Post'",
        '#end',
      ];
      final subScript = ScriptEntity(
        id: '3',
        name: 'Auto Post',
        description: 'test description',
        commands: [
          r'echo "Hello $1"',
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final flattened = ScriptExecutionParser.flatten(parentCommands, [subScript]);

      expect(flattened.length, equals(5));
      expect(flattened[0], equals('#bash server'));
      expect(flattened[1], equals("@'"));
      expect(flattened[2], equals(r'echo "Hello $1"'));
      expect(flattened[3], equals("'@ | adb -s {SERIAL} shell sh"));
      expect(flattened[4], equals('#end'));
    });

    test('Throw exception when #import client is used outside #bash server block', () {
      final parentCommands = [
        '#import client sub_test',
      ];
      final subScript = ScriptEntity(
        id: '2',
        name: 'sub_test',
        description: 'test description',
        commands: [
          'input tap 100 200',
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(
        () => ScriptExecutionParser.flatten(parentCommands, [subScript]),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Chỉ thị "#import client" chỉ hợp lệ bên trong khối "#bash server"'),
        )),
      );
    });

    test('Throw exception when using normal #import to import Android script into #bash server', () {
      final parentCommands = [
        '#bash server',
        '#import sub_test',
        '#end',
      ];
      final subScript = ScriptEntity(
        id: '4',
        name: 'sub_test',
        description: 'test description',
        commands: [
          'input tap 100 200',
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(
        () => ScriptExecutionParser.flatten(parentCommands, [subScript]),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('không thể import trực tiếp vào khối "#bash server" bằng "#import"'),
        )),
      );
    });

    test('Throw exception when using normal #import to import PowerShell script into Android #bash', () {
      final parentCommands = [
        '#bash',
        '#import sub_test',
        '#end',
      ];
      final subScript = ScriptEntity(
        id: '5',
        name: 'sub_test',
        description: 'test description',
        commands: [
          '#bash server',
          'Write-Output "PowerShell code"',
          '#end',
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(
        () => ScriptExecutionParser.flatten(parentCommands, [subScript]),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Không thể import script con "sub_test" chứa mã PowerShell (#bash server) vào môi trường Android Bash (#bash)'),
        )),
      );
    });

    test('Throw exception when using #import client on a script containing PowerShell code', () {
      final parentCommands = [
        '#bash server',
        '#import client sub_test',
        '#end',
      ];
      final subScript = ScriptEntity(
        id: '6',
        name: 'sub_test',
        description: 'test description',
        commands: [
          '#bash server',
          'Write-Output "PowerShell code"',
          '#end',
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(
        () => ScriptExecutionParser.flatten(parentCommands, [subScript]),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Không thể sử dụng "#import client" cho script con "sub_test" chứa mã PowerShell (#bash server)'),
        )),
      );
    });
  });
}
