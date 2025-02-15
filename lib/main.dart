import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';

class RequestModel {
  final String id;
  final String name;
  final String url;
  final String method;
  final Map<String, String> headers;
  final dynamic body;
  final ResponseData response;

  RequestModel({
    required this.id,
    required this.name,
    required this.url,
    required this.method,
    required this.headers,
    this.body,
    required this.response,
    required int statusCode,
    double? responseTime,
  });
}

class ResponseData {
  final int statusCode;
  final String body;
  final Map<String, String> headers;
  final double time;

  ResponseData({
    required this.statusCode,
    required this.body,
    required this.headers,
    required this.time,
  });
}

class AppState {
  final urlController = TextEditingController();
  String selectedMethod = 'GET';
  String responseBody = '';
  int? statusCode;
  Map<String, String> headers = {};
  String requestBody = '';
  DateTime? requestStartTime;
  int? responseStatusCode;
  Map<String, String> responseHeaders = {};
  double? responseTime;
  final List<RequestModel> history = [];
  String url = '';
  String method = 'GET';
  String body = '';

  Widget _buildBodySection() => const SizedBox();
  Widget _buildCollectionsTab() => const SizedBox();
  Widget _buildEnvironmentSelector() => const SizedBox();
  Widget _buildResponseSection() => const SizedBox();
  Future<void> _saveToSupabase() async {}
  void _copyToClipboard(String text) =>
      Clipboard.setData(ClipboardData(text: text));
  Future<void> _saveResponse() async {}
}

class JsonView extends StatelessWidget {
  final dynamic json;
  final JsonViewTheme theme;

  const JsonView({super.key, required this.json, required this.theme});

  @override
  Widget build(BuildContext context) {
    return SelectableText(
      const JsonEncoder.withIndent('  ').convert(json),
      style: const TextStyle(fontFamily: 'monospace'),
    );
  }
}

class JsonViewTheme {
  final Color backgroundColor;
  final TextStyle stringStyle;
  final TextStyle numberStyle;
  final TextStyle boolStyle;

  JsonViewTheme({
    required this.backgroundColor,
    required this.stringStyle,
    required this.numberStyle,
    required this.boolStyle,
  });
}

void main() {
  runApp(const APIlize());
}

class APIlize extends StatelessWidget {
  const APIlize({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'APIlize',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const APITesterHome(),
    );
  }
}

class APITesterHome extends StatefulWidget {
  const APITesterHome({super.key});

  @override
  State<APITesterHome> createState() => _APITesterHomeState();
}

class _APITesterHomeState extends State<APITesterHome> {
  final urlController = TextEditingController();
  String selectedMethod = 'GET';
  String responseBody = '';
  int? statusCode;
  Map<String, String> headers = {};
  String requestBody = '';
  int? responseStatusCode;
  DateTime? requestStartTime;
  Map<String, String> responseHeaders = {};
  double? responseTime;
  final List<RequestModel> history = [];
  String url = '';
  String method = 'GET';
  String body = '';

  Future<void> sendRequest() async {
    try {
      final Uri url = Uri.parse(urlController.text);
      late http.Response response;

      switch (selectedMethod) {
        case 'GET':
          response = await http.get(url);
          break;
        case 'POST':
          response = await http.post(url, body: requestBody);
          break;
        case 'PUT':
          response = await http.put(url, body: requestBody);
          break;
        case 'DELETE':
          response = await http.delete(url);
          break;
      }

      await _handleResponse(response);
    } catch (e) {
      setState(() {
        responseBody = 'Error: $e';
        statusCode = null;
      });
    }
  }

  Future<void> _saveResponse() async {
    final String? path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Response',
      fileName: 'response.txt',
    );

    if (path != null) {
      final file = File(path);
      await file.writeAsString(responseBody);
    }
  }

  Future<void> _handleResponse(http.Response response) async {
    setState(() {
      responseStatusCode = response.statusCode;
      responseHeaders = response.headers;
      responseBody = response.body;
      responseTime = requestStartTime != null
          ? DateTime.now()
              .difference(requestStartTime!)
              .inMilliseconds
              .toDouble()
          : 0.0;

      // Add to history
      history.insert(
          0,
          RequestModel(
              id: DateTime.now().toString(),
              name: url.split('/').last,
              url: url,
              method: method,
              headers: headers,
              body: body,
              statusCode: responseStatusCode!,
              responseTime: responseTime,
              response: ResponseData(
                  statusCode: responseStatusCode!,
                  body: responseBody,
                  headers: responseHeaders,
                  time: responseTime!)));
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('API Client'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.send), text: 'Request'),
              Tab(icon: Icon(Icons.history), text: 'History'),
              Tab(icon: Icon(Icons.folder), text: 'Collections'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildRequestTab(),
            _buildHistoryTab(),
            _buildCollectionsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildEnvironmentSelector(),
          const SizedBox(height: 16),
          _buildUrlBar(),
          const SizedBox(height: 16),
          _buildHeadersSection(),
          const SizedBox(height: 16),
          _buildBodySection(),
          const SizedBox(height: 16),
          _buildSendButton(),
          if (responseBody.isNotEmpty) _buildResponseSection(),
        ],
      ),
    );
  }

  Widget _buildEnvironmentSelector() {
    return DropdownButton<String>(
      value: 'Default',
      items: ['Default', 'Development', 'Production']
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: (value) {
        // TODO: Implement environment switching
      },
    );
  }

  Widget _buildHeadersSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Headers',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Header'),
                  onPressed: () {
                    setState(() {
                      headers['New Header'] = '';
                    });
                  },
                ),
              ],
            ),
            const Divider(),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: headers.length,
              itemBuilder: (context, index) {
                String key = headers.keys.elementAt(index);
                return Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(labelText: 'Key'),
                        controller: TextEditingController(text: key),
                        onChanged: (newKey) {
                          final value = headers[key];
                          setState(() {
                            headers.remove(key);
                            headers[newKey] = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(labelText: 'Value'),
                        controller: TextEditingController(text: headers[key]),
                        onChanged: (value) {
                          setState(() {
                            headers[key] = value;
                          });
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          headers.remove(key);
                        });
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Body', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter request body',
              ),
              onChanged: (value) {
                setState(() {
                  requestBody = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Response (${responseStatusCode ?? "N/A"})',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${responseTime?.toStringAsFixed(2) ?? "N/A"} ms'),
              ],
            ),
            const Divider(),
            const Text('Headers:'),
            ...responseHeaders.entries.map((e) => Text('${e.key}: ${e.value}')),
            const SizedBox(height: 8),
            const Text('Body:'),
            SelectableText(responseBody),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return ListView.builder(
      itemCount: history.length,
      itemBuilder: (context, index) {
        final request = history[index];
        return ListTile(
          leading: Icon(_getMethodIcon(request.method)),
          title: Text(request.url),
          subtitle: Text(request.method),
          trailing: Text(request.name),
          onTap: () => _loadRequest(request),
        );
      },
    );
  }

  Widget _buildCollectionsTab() {
    return const Center(
      child: Text('Collections feature coming soon'),
    );
  }

  IconData _getMethodIcon(String method) {
    switch (method) {
      case 'GET':
        return Icons.download;
      case 'POST':
        return Icons.add;
      case 'PUT':
        return Icons.edit;
      case 'DELETE':
        return Icons.delete;
      default:
        return Icons.http;
    }
  }

  void _loadRequest(RequestModel request) {
    setState(() {
      url = request.url;
      method = request.method;
      headers.clear();
      headers.addAll(
          request.headers.map((key, value) => MapEntry(key, value.toString())));
      body = request.body?.toString() ?? '';
    });
  }

  Widget _buildRequestPanel() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildUrlBar(),
            const SizedBox(height: 16),
            _buildTabSection(),
            const SizedBox(height: 16),
            _buildSendButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildUrlBar() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: urlController,
            decoration: InputDecoration(
              labelText: 'URL',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: selectedMethod,
          items: ['GET', 'POST', 'PUT', 'DELETE']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (value) => setState(() => selectedMethod = value!),
        ),
      ],
    );
  }

  Widget _buildResponsePanel() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Status: ${statusCode ?? "N/A"}',
              style: Theme.of(context).textTheme.titleMedium),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              child: SelectableText(
                responseBody,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSection() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Headers'),
              Tab(text: 'Body'),
            ],
          ),
          SizedBox(
            height: 200,
            child: TabBarView(
              children: [
                _buildHeadersEditor(),
                _buildBodyEditor(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return ElevatedButton(
      onPressed: sendRequest,
      child: const Text('Send Request'),
    );
  }

  Widget _buildHeadersEditor() {
    return ListView.builder(
      itemCount: headers.length + 1,
      itemBuilder: (context, index) {
        if (index == headers.length) {
          return ListTile(
            title: ElevatedButton(
              onPressed: () {
                setState(() {
                  headers['New Header'] = '';
                });
              },
              child: const Text('Add Header'),
            ),
          );
        }

        String key = headers.keys.elementAt(index);
        return ListTile(
          title: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(labelText: 'Key'),
                  controller: TextEditingController(text: key),
                  onChanged: (newKey) {
                    String value = headers[key]!;
                    setState(() {
                      headers.remove(key);
                      headers[newKey] = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(labelText: 'Value'),
                  controller: TextEditingController(text: headers[key]),
                  onChanged: (value) {
                    setState(() {
                      headers[key] = value;
                    });
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  setState(() {
                    headers.remove(key);
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBodyEditor() {
    return TextField(
      maxLines: null,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: 'Enter request body',
      ),
      onChanged: (value) {
        setState(() {
          requestBody = value;
        });
      },
    );
  }

  Widget _buildResponseView() {
    if (responseBody == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text('Status: $responseStatusCode'),
            subtitle: Text('Time: ${responseTime?.toStringAsFixed(2)}ms'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () => _copyToClipboard(responseBody!),
                ),
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: _saveResponse,
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildFormattedResponse(),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  Widget _buildFormattedResponse() {
    try {
      final jsonData = json.decode(responseBody!);
      return JsonView(
        json: jsonData,
        theme: JsonViewTheme(
          backgroundColor: Theme.of(context).cardColor,
          stringStyle: const TextStyle(color: Colors.green),
          numberStyle: const TextStyle(color: Colors.blue),
          boolStyle: const TextStyle(color: Colors.red),
        ),
      );
    } catch (e) {
      return SelectableText(responseBody!);
    }
  }
}

class ApiClient extends StatefulWidget {
  const ApiClient({super.key});

  @override
  State<ApiClient> createState() => _ApiClientHomeState();
}

class _ApiClientHomeState extends State<ApiClient> {
  // State variables
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  String _method = 'GET';
  String _url = '';
  String _body = '';
  bool _isLoading = false;
  String? _response;
  double? _responseTime;
  int? _responseStatusCode;
  Map<String, String> _headers = {};
  Map<String, String> _responseHeaders = {};
  final List<RequestModel> _requestHistory = [];
  String? _responseBody;
  DateTime? _requestStartTime;

  @override
  void initState() {
    super.initState();
    _method = 'GET';
  }

  @override
  void dispose() {
    _urlController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _showAddHeaderDialog() async {
    final keyController = TextEditingController();
    final valueController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Header'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyController,
              decoration: const InputDecoration(labelText: 'Key'),
            ),
            TextField(
              controller: valueController,
              decoration: const InputDecoration(labelText: 'Value'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _headers[keyController.text] = valueController.text;
              });
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendRequest() async {
    setState(() {
      _isLoading = true;
      _requestStartTime = DateTime.now();
    });

    try {
      final response = await http.get(Uri.parse(_urlController.text));
      await _handleResponse(response);
    } catch (e) {
      setState(() {
        _responseBody = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleResponse(http.Response response) async {
    if (!mounted) return;

    setState(() {
      _responseHeaders = response.headers;
      _responseBody = response.body;
      _responseTime = _requestStartTime != null
          ? DateTime.now()
              .difference(_requestStartTime!)
              .inMilliseconds
              .toDouble()
          : null;
      _isLoading = false;
    });

    // Add to history
    _requestHistory.add(RequestModel(
      id: DateTime.now().toString(),
      name: Uri.parse(_urlController.text).pathSegments.lastOrNull ?? 'Unnamed',
      url: _urlController.text,
      method: _method,
      headers: _headers,
      body: _bodyController.text,
      response: ResponseData(
        statusCode: response.statusCode,
        body: _responseBody ?? '',
        headers: response.headers,
        time: _responseTime ?? 0,
      ),
      statusCode: response.statusCode,
      responseTime: _responseTime,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Client'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'URL',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => _url = value,
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _method,
                  items: ['GET', 'POST', 'PUT', 'DELETE']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) => setState(() => _method = value!),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Headers',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: _showAddHeaderDialog,
                          child: const Text('Add Header'),
                        ),
                      ],
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: _headers.length,
                      itemBuilder: (context, index) {
                        final key = _headers.keys.elementAt(index);
                        return ListTile(
                          title: Text(key),
                          subtitle: Text(_headers[key]!),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () =>
                                setState(() => _headers.remove(key)),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bodyController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Body',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _body = value,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _sendRequest,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Send Request'),
            ),
            if (_responseBody != null) ...[
              const SizedBox(height: 16),
              Text('Response Time: ${_responseTime?.toStringAsFixed(2)} ms'),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(_responseBody!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Rest of the widget building methods remain the same
  // but are now properly referenced in the build method
}
