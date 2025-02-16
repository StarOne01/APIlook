import 'package:flutter/material.dart';

class SyntaxHighlighterView extends StatelessWidget {
  final String code;
  final String language;
  final Map<String, TextStyle> theme;

  const SyntaxHighlighterView({
    required this.code,
    required this.language,
    required this.theme,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SelectableText.rich(
      TextSpan(
        children: _highlightSyntax(),
      ),
      style: const TextStyle(fontFamily: 'monospace'),
    );
  }

  List<TextSpan> _highlightSyntax() {
    // Add syntax highlighting logic here
    return [TextSpan(text: code)];
  }
}
