import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:code_editor/code_editor.dart';
import 'dart:convert';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/vs.dart';

class APIWorkspace extends StatefulWidget {
  final String code;
  final Function(String) onCodeChanged;
  final Future<void> Function(String) onExecute;

  const APIWorkspace({
    Key? key,
    required this.code,
    required this.onCodeChanged,
    required this.onExecute,
  }) : super(key: key);

  @override
  State<APIWorkspace> createState() => _APIWorkspaceState();
}

class _APIWorkspaceState extends State<APIWorkspace> {
  late final WebViewController _webViewController;
  final List<ConsoleLog> _logs = [];
  bool _isInitialized = false;
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _codeController.text = widget.code;
  }

  Future<void> _initializeWebView() async {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(_getHtmlContent())
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() => _isInitialized = true);
          },
        ),
      );
  }

  String _getHtmlContent() => '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body { margin: 0; padding: 16px; font-family: monospace; }
      </style>
    </head>
    <body>
      <script>
        const console = {
          log: (msg) => window.flutter_inappwebview.callHandler('console', 'log', msg),
          error: (msg) => window.flutter_inappwebview.callHandler('console', 'error', msg),
          warn: (msg) => window.flutter_inappwebview.callHandler('console', 'warn', msg),
        };
      </script>
    </body>
    </html>
  ''';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _codeController,
              maxLines: null,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
              style: const TextStyle(fontFamily: 'monospace'),
              onChanged: widget.onCodeChanged,
            ),
          ),
        ),
        _buildConsole(),
      ],
    );
  }

  Widget _buildConsole() {
    return Container(
      height: 150,
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildConsoleHeader(),
          Expanded(
            child: ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) => _logs[index].buildWidget(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsoleHeader() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          const Text(
            'Console',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.clear, color: Colors.white70, size: 16),
            onPressed: () => setState(() => _logs.clear()),
            tooltip: 'Clear console',
          ),
        ],
      ),
    );
  }

  Future<void> _executeCode() async {
    if (!_isInitialized) return;

    setState(() {
      _logs.add(ConsoleLog(
        type: LogType.info,
        message: 'Executing code...',
        timestamp: DateTime.now(),
      ));
    });

    try {
      final result = await _webViewController.runJavaScriptReturningResult('''
        try {
          ${_codeController.text}
          'success';
        } catch (e) {
          e.toString();
        }
      ''');

      setState(() {
        _logs.add(ConsoleLog(
          type: LogType.success,
          message: 'Execution completed: $result',
          timestamp: DateTime.now(),
        ));
      });
    } catch (e) {
      setState(() {
        _logs.add(ConsoleLog(
          type: LogType.error,
          message: e.toString(),
          timestamp: DateTime.now(),
        ));
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}

enum LogType { info, error, warning, success }

class ConsoleLog {
  final LogType type;
  final String message;
  final DateTime timestamp;

  ConsoleLog({
    required this.type,
    required this.message,
    required this.timestamp,
  });

  Widget buildWidget() {
    final color = {
      LogType.info: Colors.white,
      LogType.error: Colors.redAccent,
      LogType.warning: Colors.orangeAccent,
      LogType.success: Colors.greenAccent,
    }[type]!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        '[${timestamp.toIso8601String()}] $message',
        style: TextStyle(
          color: color,
          fontFamily: 'monospace',
          fontSize: 12,
        ),
      ),
    );
  }
}

class APIRuntime {
  late final WebViewController _controller;

  Future<void> initialize() async {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(_getHtmlContent());
  }

  String _getHtmlContent() => '''
    <!DOCTYPE html>
    <html>
    <head><meta charset="utf-8"></head>
    <body>
      <script>
        function executeCode(code) {
          try {
            eval(code);
            return JSON.stringify({ success: true, result: 'Code executed successfully' });
          } catch (e) {
            return JSON.stringify({ success: false, error: e.toString() });
          }
        }
      </script>
    </body>
    </html>
  ''';

  Future<Map<String, dynamic>> executeCode(String code) async {
    final result =
        await _controller.runJavaScriptReturningResult("executeCode(`$code`)");
    return jsonDecode(result.toString());
  }
}
