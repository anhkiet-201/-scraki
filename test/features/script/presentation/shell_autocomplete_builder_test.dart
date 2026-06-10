import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:re_editor/re_editor.dart';
import 'package:scraki/features/script/presentation/utils/shell_autocomplete_builder.dart';

// Dummy context to pass to the builder
class FakeBuildContext extends Iterable<BuildContext> implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ShellAutocompletePromptsBuilder Tests', () {
    late ShellAutocompletePromptsBuilder builder;
    final context = FakeBuildContext();

    setUp(() {
      builder = ShellAutocompletePromptsBuilder([
        const CodeKeywordPrompt(word: 'adb'),
        const CodeKeywordPrompt(word: 'shell'),
        const CodeKeywordPrompt(word: 'am'),
        
        // Placeholder variables
        const PlaceholderPrompt(
          word: '{input}',
          displayName: '{input}',
          insertText: '{input}',
          baseSelectOffset: 7,
          extentSelectOffset: 7,
        ),
        const PlaceholderPrompt(
          word: '{input:tên_biến}',
          displayName: '{input:tên_biến}',
          insertText: '{input:tên_biến}',
          baseSelectOffset: 7,
          extentSelectOffset: 15,
        ),
        const PlaceholderPrompt(
          word: '{SERIAL}',
          displayName: '{SERIAL}',
          insertText: '{SERIAL}',
          baseSelectOffset: 8,
          extentSelectOffset: 8,
        ),
        const PlaceholderPrompt(
          word: '{random(max)}',
          displayName: '{random(max)}',
          insertText: '{random(max)}',
          baseSelectOffset: 8,
          extentSelectOffset: 11,
        ),
      ]);
    });

    test('Trigger suggestions when typing "ad"', () {
      final codeLine = const CodeLine('adb');
      final selection = const CodeLineSelection(
        baseIndex: 0,
        baseOffset: 2,
        extentIndex: 0,
        extentOffset: 2,
      );

      final result = builder.build(context, codeLine, selection);
      expect(result, isNotNull);
      expect(result!.input, equals('ad'));
      expect(result.prompts.length, equals(1));
      expect(result.prompts.first.word, equals('adb'));
    });

    test('Trigger placeholders when typing "{"', () {
      final codeLine = const CodeLine('{');
      final selection = const CodeLineSelection(
        baseIndex: 0,
        baseOffset: 1,
        extentIndex: 0,
        extentOffset: 1,
      );

      final result = builder.build(context, codeLine, selection);
      expect(result, isNotNull);
      expect(result!.input, equals('{'));
      // Tất cả placeholder prompts đều match '{' vì chúng bắt đầu bằng '{'
      expect(result.prompts.length, equals(4));
    });

    test('Trigger specific placeholder when typing "{in"', () {
      final codeLine = const CodeLine('{in');
      final selection = const CodeLineSelection(
        baseIndex: 0,
        baseOffset: 3,
        extentIndex: 0,
        extentOffset: 3,
      );

      final result = builder.build(context, codeLine, selection);
      expect(result, isNotNull);
      expect(result!.input, equals('{in'));
      // Match {input} và {input:tên_biến}
      expect(result.prompts.length, equals(2));
      expect(result.prompts[0].word, equals('{input}'));
      expect(result.prompts[1].word, equals('{input:tên_biến}'));
    });

    test('PlaceholderPrompt selection adjustment offsets', () {
      const prompt = PlaceholderPrompt(
        word: '{input:tên_biến}',
        displayName: '{input:tên_biến}',
        insertText: '{input:tên_biến}',
        baseSelectOffset: 7,
        extentSelectOffset: 15,
      );

      // Khi input rỗng hoặc dài 0
      final p0 = prompt.copyWithInputLength(0);
      expect(p0.autocomplete.selection.baseOffset, equals(7));
      expect(p0.autocomplete.selection.extentOffset, equals(15));

      // Khi input dài 3 (ví dụ "{in")
      final p3 = prompt.copyWithInputLength(3);
      expect(p3.autocomplete.selection.baseOffset, equals(10));
      expect(p3.autocomplete.selection.extentOffset, equals(18));
    });

    test('PlaceholderPrompt match is case insensitive', () {
      const prompt = PlaceholderPrompt(
        word: '{SERIAL}',
        displayName: '{SERIAL}',
        insertText: '{SERIAL}',
        baseSelectOffset: 8,
        extentSelectOffset: 8,
      );

      expect(prompt.match('{se'), isTrue);
      expect(prompt.match('{SE'), isTrue);
      expect(prompt.match('{sEr'), isTrue);
    });

    test('Do not suggest inside single quotes', () {
      final codeLine = const CodeLine("echo 'ad'");
      final selection = const CodeLineSelection(
        baseIndex: 0,
        baseOffset: 8, // Trỏ ở chữ 'd' trong 'ad'
        extentIndex: 0,
        extentOffset: 8,
      );

      final result = builder.build(context, codeLine, selection);
      expect(result, isNull);
    });

    test('Suggest placeholders inside double quotes, but not other commands', () {
      final codeLine = const CodeLine('echo "{in"');
      final selection = const CodeLineSelection(
        baseIndex: 0,
        baseOffset: 9, // Trỏ ở chữ 'n'
        extentIndex: 0,
        extentOffset: 9,
      );

      final result = builder.build(context, codeLine, selection);
      expect(result, isNotNull);
      expect(result!.input, equals('{in'));
      expect(result.prompts.length, equals(2));
    });
  });
}
