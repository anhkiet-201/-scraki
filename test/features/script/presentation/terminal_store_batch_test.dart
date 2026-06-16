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

    test('Flatten sub-script with parameter containing whitespace and quotes', () {
      final parentCommands = [
        '#run-script sub_test name="Hello cvbc" age=25',
      ];
      final subScript = ScriptEntity(
        id: '1',
        name: 'sub_test',
        description: 'test description',
        commands: [
          'echo "{input:name}"',
          'echo {input:age}',
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final flattened = ScriptExecutionParser.flatten(parentCommands, [subScript]);

      expect(flattened.length, equals(2));
      expect(flattened[0], equals('echo "Hello cvbc"'));
      expect(flattened[1], equals('echo 25'));
    });

    test('Flatten sub-script with environment labels inside parent environment block', () {
      final parentCommands = [
        '#bash server',
        'if (\$true) {',
        '  #run-script sub_test',
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
  });
}
