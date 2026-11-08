from pathlib import Path

root = Path("project")

tool_file = root / "lib/features/tools/tool_runner.dart"
tool_source = tool_file.read_text()
old_regex = r"""RegExp('(?:^|[^\\w])${RegExp.escape(tool.name)}(?:[^\\w]|$)')"""
new_regex = r"""RegExp(r'(?:^|[^\\w])' + RegExp.escape(tool.name) + r'(?:[^\\w]|$)')"""
if tool_source.count(old_regex) != 1:
    raise SystemExit("Expected exactly one original tool-name RegExp; refusing an unsafe patch.")
tool_file.write_text(tool_source.replace(old_regex, new_regex, 1))

chat_file = root / "lib/features/chat/presentation/providers/chat_provider.dart"
chat_source = chat_file.read_text()
old_block = """        final instructionalToolText = tools.isNotEmpty &&
            !TextToolProtocol.userAsksHowTo(input) &&
            TextToolProtocol.isInstructionalToolAnswer(
              input,
              answerText,
              tools,
            );
        final visibleToolText = tools.isNotEmpty &&
                !TextToolProtocol.userAsksHowTo(input)
            ? TextToolProtocol.visible(answerText, tools)
            : answerText;"""
new_block = """        final instructionalToolText = tools.isNotEmpty &&
            !TextToolProtocol.userAsksHowTo(t.input) &&
            TextToolProtocol.isInstructionalToolAnswer(
              t.input,
              answerText,
              tools,
            );
        final visibleToolText = tools.isNotEmpty &&
                !TextToolProtocol.userAsksHowTo(t.input)
            ? TextToolProtocol.visible(answerText, tools)
            : answerText;"""
if chat_source.count(old_block) != 1:
    raise SystemExit("Expected exactly one ChatNotifier block with the undefined input reference; refusing an unsafe patch.")
chat_file.write_text(chat_source.replace(old_block, new_block, 1))

print("Applied both v1.3.7 Dart compile fixes.")
