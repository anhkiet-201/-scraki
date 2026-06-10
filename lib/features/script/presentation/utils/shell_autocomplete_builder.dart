import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';

/// Prompt thông minh dành cho các biến placeholder của Scraki.
/// Hỗ trợ tự động bôi đen tham số mặc định sau khi được chèn vào editor.
class PlaceholderPrompt extends CodePrompt {
  final String displayName;
  final String insertText;
  final int baseSelectOffset; // Offset bắt đầu bôi đen (tính từ đầu insertText)
  final int extentSelectOffset; // Offset kết thúc bôi đen (tính từ đầu insertText)
  final int inputLength; // Độ dài input đã gõ, dùng để bù trừ công thức của re_editor

  const PlaceholderPrompt({
    required super.word,
    required this.displayName,
    required this.insertText,
    required this.baseSelectOffset,
    required this.extentSelectOffset,
    this.inputLength = 0,
  });

  PlaceholderPrompt copyWithInputLength(int length) {
    return PlaceholderPrompt(
      word: word,
      displayName: displayName,
      insertText: insertText,
      baseSelectOffset: baseSelectOffset,
      extentSelectOffset: extentSelectOffset,
      inputLength: length,
    );
  }

  @override
  CodeAutocompleteResult get autocomplete {
    // re_editor tự động trừ đi input.length ở kết quả cuối cùng,
    // nên ta cần cộng bù inputLength vào selection offset.
    return CodeAutocompleteResult(
      input: '',
      word: insertText,
      selection: TextSelection(
        baseOffset: baseSelectOffset + inputLength,
        extentOffset: extentSelectOffset + inputLength,
      ),
    );
  }

  @override
  bool match(String input) {
    final lowerWord = word.toLowerCase();
    final lowerInput = input.toLowerCase();
    return lowerWord != lowerInput && lowerWord.startsWith(lowerInput);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlaceholderPrompt &&
        other.word == word &&
        other.displayName == displayName &&
        other.insertText == insertText &&
        other.baseSelectOffset == baseSelectOffset &&
        other.extentSelectOffset == extentSelectOffset &&
        other.inputLength == inputLength;
  }

  @override
  int get hashCode => Object.hash(
        word,
        displayName,
        insertText,
        baseSelectOffset,
        extentSelectOffset,
        inputLength,
      );
}

class ShellAutocompletePromptsBuilder implements CodeAutocompletePromptsBuilder {
  final List<CodePrompt> allPrompts;

  ShellAutocompletePromptsBuilder(this.allPrompts);

  @override
  CodeAutocompleteEditingValue? build(
    BuildContext context,
    CodeLine codeLine,
    CodeLineSelection selection,
  ) {
    final String text = codeLine.text;
    final Characters charactersBefore =
        text.substring(0, selection.extentOffset).characters;
    if (charactersBefore.isEmpty) {
      return null;
    }
    final Characters charactersAfter =
        text.substring(selection.extentOffset).characters;

    // Kiểm tra xem vị trí cursor có đang nằm trong cặp dấu nháy đơn hay không
    final bool isInsideSingleQuote =
        charactersBefore.containsSymbols(const ['\'']) &&
            charactersAfter.containsSymbols(const ['\'']);
            
    // Kiểm tra xem vị trí cursor có đang nằm trong cặp dấu nháy kép hay không
    final bool isInsideDoubleQuote =
        charactersBefore.containsSymbols(const ['"']) &&
            charactersAfter.containsSymbols(const ['"']);

    int start = charactersBefore.length - 1;
    for (; start >= 0; start--) {
      final String char = charactersBefore.elementAt(start);
      if (!_isValidShellWordPart(char)) {
        break;
      }
    }
    
    final String input =
        charactersBefore.getRange(start + 1, charactersBefore.length).string;
    if (input.isEmpty) {
      return null;
    }

    // Nếu cursor ở trong dấu nháy đơn, ta không gợi ý (để tránh xung đột chuỗi literal).
    if (isInsideSingleQuote) {
      return null;
    }

    // Nếu ở trong dấu nháy kép, ta chỉ gợi ý các biến placeholder bắt đầu bằng '{'.
    if (isInsideDoubleQuote && !input.startsWith('{')) {
      return null;
    }

    // Lọc danh sách prompt khớp với input
    final matchedPrompts = allPrompts.where((prompt) => prompt.match(input));
    if (matchedPrompts.isEmpty) {
      return null;
    }

    // Áp dụng độ dài input động cho các PlaceholderPrompt
    final finalPrompts = matchedPrompts.map((prompt) {
      if (prompt is PlaceholderPrompt) {
        return prompt.copyWithInputLength(input.length);
      }
      return prompt;
    }).toList();

    return CodeAutocompleteEditingValue(
      input: input,
      prompts: finalPrompts,
      index: 0,
    );
  }

  bool _isValidShellWordPart(String char) {
    final int code = char.codeUnits.first;
    // Hỗ trợ chữ cái, số, gạch dưới, gạch ngang, dấu mở/đóng ngoặc nhọn, và dấu hai chấm.
    return (code >= 65 && code <= 90) || // A-Z
        (code >= 97 && code <= 122) || // a-z
        (code >= 48 && code <= 57) || // 0-9
        char == '_' ||
        char == '-' ||
        char == '{' ||
        char == '}' ||
        char == ':';
  }
}

extension _CharactersExtension on Characters {
  bool containsSymbols(List<String> symbols) {
    for (int i = length - 1; i >= 0; i--) {
      if (symbols.contains(elementAt(i))) {
        return true;
      }
    }
    return false;
  }
}
