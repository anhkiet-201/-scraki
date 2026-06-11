import 'package:flutter_test/flutter_test.dart';
import 'package:scraki/features/script/presentation/utils/script_execution_parser.dart';

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
  });
}
