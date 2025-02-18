import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';

class APIRuntime {
  late final WebViewController _controller;

  Future<void> initialize() async {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString('''
        <!DOCTYPE html>
        <html>
        <body>
          <script>
            function executeAPI(code, request) {
              const response = {
                status: 200,
                headers: {},
                body: null
              };
              
              try {
                eval(code);
                if (typeof handleRequest === 'function') {
                  handleRequest(request, response);
                }
              } catch (e) {
                response.status = 500;
                response.body = JSON.stringify({ error: e.toString() });
              }
              
              return JSON.stringify(response);
            }
          </script>
        </body>
        </html>
      ''');
  }

  Future<Map<String, dynamic>> executeLogic(
      String code, Map<String, dynamic> request) async {
    final result = await _controller.runJavaScriptReturningResult(
        "executeAPI(`$code`, ${jsonEncode(request)})");
    return jsonDecode(result.toString());
  }
}
