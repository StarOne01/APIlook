import 'package:apilize/auth/auth_controller.dart';
import 'package:apilize/dashboard.dart';
import 'package:apilize/pages/profile_page.dart';
import 'package:apilize/pages/requests_page.dart';
import 'package:apilize/pages/settings_page.dart';
import 'package:apilize/services/supabase_service.dart';
import 'package:apilize/syntax_highlighter.dart';
import 'package:apilize/theme.dart';
import 'package:apilize/views/login_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ResponseViewMode { prettyJson, table, treeView, rawText }

class RequestModel {
  final String id;
  final String name;
  final String url;
  final String method;
  final Map<String, dynamic> headers;
  final dynamic body;
  final DateTime timestamp;
  final Map<String, String> environment;
  final ResponseMetrics? metrics;
  final String? generatedCode;

  RequestModel({
    required this.id,
    required this.name,
    required this.url,
    required this.method,
    required this.headers,
    this.body,
    DateTime? timestamp,
    Map<String, String>? environment,
    this.metrics,
    this.generatedCode,
  })  : this.timestamp = timestamp ?? DateTime.now(),
        this.environment = environment ?? {};

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
        'method': method,
        'headers': headers,
        'body': body ?? '',
        'timestamp': timestamp.toIso8601String(),
        'environment': environment,
        'metrics': metrics?.toJson(),
        'generatedCode': generatedCode,
      };

  Future<void> saveToCollection(String collectionName) async {
    // Save to local storage or database
  }
}

class ResponseMetrics {
  final int statusCode;
  final double dnsLookup;
  final double tcpConnection;
  final double tlsHandshake;
  final double serverProcessing;
  final double contentTransfer;
  final double total;

  ResponseMetrics({
    required this.statusCode,
    required this.dnsLookup,
    required this.tcpConnection,
    required this.tlsHandshake,
    required this.serverProcessing,
    required this.contentTransfer,
    required this.total,
  });

  Map<String, dynamic> toJson() => {
        'statusCode': statusCode,
        'dnsLookup': dnsLookup,
        'tcpConnection': tcpConnection,
        'tlsHandshake': tlsHandshake,
        'serverProcessing': serverProcessing,
        'contentTransfer': contentTransfer,
        'total': total,
      };
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

class RequestPage extends StatefulWidget {
  const RequestPage({super.key});

  @override
  State<RequestPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestPage>
    with TickerProviderStateMixin {
  // 2. Declare state variables
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final Map<String, String> _headers = {};
  String method = 'GET';
  String _responseHeaders = '';
  final List<RequestModel> _history = [];
  String _response = '';
  int? _statusCode;
  double? _responseTime;
  String _selectedLanguage = 'curl';
  @override
  Widget build(BuildContext context) {
    return _buildBody();
  }

  Widget _buildSpeedDial() {
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      activeBackgroundColor: Theme.of(context).colorScheme.error,
      activeForegroundColor: Theme.of(context).colorScheme.onError,
      elevation: 8.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      children: [
        SpeedDialChild(
          child: const Icon(Icons.save),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          foregroundColor: Theme.of(context).colorScheme.onSecondary,
          label: 'Save Collection',
          onTap: () => _saveToCollection(),
        ),
        SpeedDialChild(
          child: const Icon(Icons.code),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          foregroundColor: Theme.of(context).colorScheme.onTertiary,
          label: 'Generate Code',
          onTap: () => _showCodeGenerationSheet(),
        ),
      ],
    );
  }

  late TabController _mainTabController;
  late TabController _responseTabController;
  late TabController _previewTabController;
  late final WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _responseTabController = TabController(length: 3, vsync: this);
    _previewTabController = TabController(length: 3, vsync: this);
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white);
  }

  final urlController = TextEditingController();
  String selectedMethod = 'GET';
  String responseBody = '';
  int? statusCode;
  String requestBody = '';
  int? responseStatusCode;
  DateTime? requestStartTime;
  Map<String, String> responseHeaders = {};
  double? responseTime;
  final List<RequestModel> history = [];
  String url = '';

  String body = '';
  ResponseViewMode _responseViewMode = ResponseViewMode.prettyJson;
  ResponseViewMode _viewMode = ResponseViewMode.prettyJson;
  String _generatedCode = '';
  bool get isDarkMode => Theme.of(context).brightness == Brightness.dark;

  final Map<String, TextStyle> darkCodeTheme = {
    'keyword': const TextStyle(color: Colors.blue),
    'string': const TextStyle(color: Colors.green),
    'number': const TextStyle(color: Colors.orange),
    'comment': const TextStyle(color: Colors.grey),
  };

  final Map<String, TextStyle> lightCodeTheme = {
    'keyword': const TextStyle(color: Colors.purple),
    'string': const TextStyle(color: Colors.green),
    'number': const TextStyle(color: Colors.blue),
    'comment': const TextStyle(color: Colors.grey),
  };
  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code copied to clipboard')),
    );
  }

  Future<void> _exportCode(String language, String code) async {
    final String fileName = 'request.$language';
    // Add export logic
  }

  Future<void> _testGeneratedCode() async {
    // Add test logic
  }

  Future<void> _saveAsSnippet() async {
    // Add save logic
  }

  String generateCode(String language) {
    // Add code generation logic
    return '';
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
              headers: _headers,
              body: requestBody,
              metrics: null,
              generatedCode: null));
    });
  }

  Widget _buildNarrowLayout() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Client'),
        actions: [
          IconButton(
            icon: const Icon(Icons.code),
            onPressed: _showCodeGenerationSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCollapsibleUrlBar(),
          Expanded(
            child: _buildRequestResponseTabs(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _sendRequest,
        child: const Icon(Icons.send),
      ),
    );
  }

  Widget _buildCollapsibleUrlBar() {
    return ExpansionTile(
      title:
          Text(urlController.text.isEmpty ? 'Enter URL' : urlController.text),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: _buildUrlBar(),
        ),
      ],
    );
  }

  Widget _buildRequestResponseTabs() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Headers'),
              Tab(text: 'Body'),
              Tab(text: 'Response'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildHeadersList(),
                _buildBodyEditor(),
                _buildResponseView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCodeGenerationSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => _buildCodeGenerationPanel(),
    );
  }

  Widget _buildHeadersList() {
    return Column(
      children: [
        Expanded(
          child: _headers.isEmpty
              ? const Center(
                  child: Text('No headers added yet'),
                )
              : ListView.builder(
                  itemCount: _headers.length,
                  itemBuilder: (context, index) {
                    final header = _headers.entries.elementAt(index);
                    return ListTile(
                      title: Text(header.key),
                      subtitle: Text(header.value),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () =>
                                _editHeader(header.key, header.value),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => setState(() {
                              _headers.remove(header.key);
                            }),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Header'),
            onPressed: _showAddHeaderDialog,
          ),
        ),
      ],
    );
  }

  Widget _buildWideLayout() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Client - Wide Layout'),
      ),
      body: Row(
        children: [
          Expanded(child: _buildRequestResponseTabs()),
        ],
      ),
    );
  }

  void _handleUrlChange(String value) {
    setState(() {
      url = value;
    });
  }

  void _handleBodyChange(String value) {
    setState(() {
      body = value;
    });
  }

  Widget _buildUrlBar() {
    return TextField(
      controller: _urlController,
      onChanged: _handleUrlChange,
      decoration: const InputDecoration(
        labelText: 'URL',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildBodyEditor() {
    return TextField(
      controller: _bodyController,
      onChanged: _handleBodyChange,
      maxLines: null,
      decoration: const InputDecoration(
        hintText: 'Enter request body',
      ),
    );
  }

  Widget _buildResponseView() {
    if (_response.isEmpty) {
      return const Center(
        child: Text('Send a request to see the response'),
      );
    }

    return Column(
      children: [
        TabBar(
          controller: _responseTabController,
          tabs: const [
            Tab(text: 'JSON'),
            Tab(text: 'Raw'),
            Tab(text: 'Preview'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _responseTabController,
            children: [
              _buildPrettyResponse(),
              _buildRawResponse(),
              _buildPreviewResponse(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrettyResponse() {
    if (_response.isEmpty) return const SizedBox();

    try {
      final jsonData = json.decode(_response);
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: JsonView(
            json: jsonData,
            theme: JsonViewTheme(
              backgroundColor: Theme.of(context).cardColor,
              stringStyle: const TextStyle(color: Colors.green),
              numberStyle: const TextStyle(color: Colors.blue),
              boolStyle: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      );
    } catch (e) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(_response),
        ),
      );
    }
  }

  Widget _buildRawResponse() {
    final StringBuffer rawResponse = StringBuffer();
    final uri = Uri.tryParse(_urlController.text);

    // Request Section
    rawResponse.writeln('REQUEST');
    rawResponse.writeln('=======\n');
    rawResponse.writeln('${method.toUpperCase()} ${uri?.path ?? ''} HTTP/1.1');
    rawResponse.writeln('Host: ${uri?.host ?? ''}');

    // Query Parameters
    if (uri?.queryParameters.isNotEmpty ?? false) {
      rawResponse.writeln('\nQuery Parameters:');
      uri!.queryParameters.forEach((key, value) {
        rawResponse.writeln('$key: $value');
      });
    }

    // Request Headers
    rawResponse.writeln('\nRequest Headers:');
    rawResponse.writeln('-------------');
    _headers.forEach((key, value) {
      rawResponse.writeln('$key: $value');
    });

    // Request Body
    if (_bodyController.text.isNotEmpty) {
      rawResponse.writeln('\nRequest Body:');
      rawResponse.writeln('-------------');
      rawResponse.writeln(_bodyController.text);
    }

    // Response Section
    rawResponse.writeln('\n\nRESPONSE');
    rawResponse.writeln('========\n');

    // Status Line
    rawResponse.writeln('HTTP/1.1 $_statusCode');

    // Response Headers
    rawResponse.writeln('\nResponse Headers:');
    rawResponse.writeln('---------------');
    responseHeaders.forEach((key, value) {
      rawResponse.writeln('$key: $value');
    });

    // Response Body
    rawResponse.writeln('\nResponse Body:');
    rawResponse.writeln('-------------');
    rawResponse.writeln(_response);

    // Metrics
    rawResponse.writeln('\nMETRICS');
    rawResponse.writeln('=======');
    rawResponse
        .writeln('Time: ${_responseTime?.toStringAsFixed(2) ?? 'N/A'} ms');
    rawResponse.writeln('Size: ${_response.length} bytes');
    rawResponse
        .writeln('Content-Type: ${responseHeaders['content-type'] ?? 'N/A'}');

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: SelectableText(
          rawResponse.toString(),
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            height: 1.5,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewResponse() {
    if (_response.isEmpty) return const SizedBox();

    try {
      final dynamic jsonData = json.decode(_response);

      if (jsonData is List) {
        return _buildJsonTable(jsonData);
      } else if (jsonData is Map) {
        return _buildJsonTable([jsonData]);
      } else {
        return Center(
            child: Text('Cannot display as table: ${jsonData.runtimeType}'));
      }
    } catch (e) {
      return Center(child: Text('Invalid JSON: $e'));
    }
  }

  Widget _buildJsonTable(List<dynamic> data) {
    if (data.isEmpty) return const Center(child: Text('No data'));

    // Get all unique keys from all objects
    final Set<String> keys = {};
    for (var item in data) {
      if (item is Map) {
        keys.addAll(item.keys.map((e) => e.toString()));
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: keys
              .map(
                (key) => DataColumn(
                  label: Text(
                    key,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              )
              .toList(),
          rows: data.map((item) {
            if (item is! Map)
              return DataRow(cells: [DataCell(Text(item.toString()))]);

            return DataRow(
              cells: keys.map((key) {
                final value = item[key];
                String displayText = '';

                if (value == null) {
                  displayText = 'null';
                } else if (value is Map || value is List) {
                  displayText = json.encode(value);
                } else {
                  displayText = value.toString();
                }

                return DataCell(
                  Text(
                    displayText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    if (value is Map || value is List) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(key),
                          content: SingleChildScrollView(
                            child: Text(
                              const JsonEncoder.withIndent('  ').convert(value),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                );
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCodeGenerationPanel() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Language selector at the top
            _buildLanguageSelector(),
            const SizedBox(height: 16),

            // Code preview in scrollable container
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(
                      _generateCode(_selectedLanguage),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Action buttons at bottom
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.copy),
                  tooltip: 'Copy to clipboard',
                  onPressed: () => _copyCode(_generateCode(_selectedLanguage)),
                ),
                IconButton(
                  icon: const Icon(Icons.download),
                  tooltip: 'Download code',
                  onPressed: () => _exportCode(
                      _selectedLanguage, _generateCode(_selectedLanguage)),
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  tooltip: 'Share code',
                  onPressed: () =>
                      Share.share(_generateCode(_selectedLanguage)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return SegmentedButton<String>(
      segments: [
        ButtonSegment(value: 'curl', label: const Text('cURL')),
        ButtonSegment(value: 'dart', label: const Text('Dart')),
        ButtonSegment(value: 'python', label: const Text('Python')),
        ButtonSegment(value: 'javascript', label: const Text('JS')),
      ],
      selected: {_selectedLanguage},
      onSelectionChanged: (Set<String> value) {
        setState(() {
          _selectedLanguage = value.first;
          _generatedCode = generateCode(_selectedLanguage);
        });
      },
    );
  }

  Future<void> _sendRequest() async {
    setState(() {
      _statusCode = null;
      _response = '';
      _responseTime = null;
    });

    final startTime = DateTime.now();

    try {
      final uri = Uri.parse(_urlController.text);
      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: _headers);
          break;
        case 'POST':
          response = await http.post(uri,
              headers: _headers, body: _bodyController.text);
          break;
        case 'PUT':
          response = await http.put(uri,
              headers: _headers, body: _bodyController.text);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: _headers);
          break;
        default:
          throw ArgumentError('Unsupported HTTP method: $method');
      }

      final endTime = DateTime.now();

      setState(() {
        _statusCode = response.statusCode;
        _responseHeaders = response.headers.toString();
        _response = response.body;
        _responseTime = endTime.difference(startTime).inMilliseconds.toDouble();
        _history.insert(
          0,
          RequestModel(
            id: DateTime.now().toString(),
            name: uri.path.split('/').last,
            url: _urlController.text,
            method: method,
            headers: Map<String, dynamic>.from(_headers),
            body: _bodyController.text,
          ),
        );
      });
    } catch (e) {
      setState(() {
        _response = 'Error: $e';
      });
    }
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

  Future<void> _editHeader(String key, String value) async {
    final keyController = TextEditingController(text: key);
    final valueController = TextEditingController(text: value);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Header'),
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
                _headers.remove(key);
                _headers[keyController.text] = valueController.text;
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _generateCode(String language) {
    final StringBuffer code = StringBuffer();

    switch (language) {
      case 'curl':
        code.write('curl -X $method ');
        _headers.forEach((key, value) {
          code.write('-H "$key: $value" ');
        });
        if (body.isNotEmpty) {
          code.write('-d \'$body\' ');
        }
        code.write('"$url"');
        break;

      case 'python':
        code.writeln('import requests\n');
        code.writeln('url = "$url"');
        if (_headers.isNotEmpty) {
          code.writeln('headers = ${_headers.toString()}');
        }
        if (body.isNotEmpty) {
          code.writeln('payload = \'$body\'');
        }
        code.writeln('\nresponse = requests.${method.toLowerCase()}(');
        code.writeln('    url,');
        if (_headers.isNotEmpty) code.writeln('    headers=headers,');
        if (body.isNotEmpty) code.writeln('    data=payload,');
        code.writeln(')');
        code.writeln('\nprint(response.status_code)');
        code.writeln('print(response.text)');
        break;

      default:
        code.write('Unsupported language');
    }

    return code.toString();
  }

  Widget _buildCodePreview() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: SelectableText(
          _generateCode(_selectedLanguage),
          style: const TextStyle(
            fontFamily: 'monospace',
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCodeActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          icon: const Icon(Icons.copy),
          tooltip: 'Copy to clipboard',
          onPressed: () {
            Clipboard.setData(ClipboardData(
              text: _generateCode(_selectedLanguage),
            ));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Code copied to clipboard')),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.download),
          tooltip: 'Download code',
          onPressed: () async {
            try {
              final code = _generateCode(_selectedLanguage);
              final extension = _selectedLanguage == 'curl'
                  ? 'sh'
                  : _selectedLanguage == 'python'
                      ? 'py'
                      : 'txt';
              final directory = await getApplicationDocumentsDirectory();
              final file = File('${directory.path}/request.$extension');
              await file.writeAsString(code);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Saved to ${file.path}')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error saving file: $e')),
              );
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.share),
          tooltip: 'Share code',
          onPressed: () {
            Share.share(_generateCode(_selectedLanguage));
          },
        ),
      ],
    );
  }

  Future<void> _saveToCollection() async {
    final nameController = TextEditingController();

    final bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save to Collection'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
              labelText: 'Collection Name', hintText: 'Enter collection name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      try {
        final collection = {
          'name': nameController.text,
          'request': {
            'url': urlController.text,
            'method': selectedMethod,
            'headers': _headers,
            'body': requestBody,
          }
        };

        // Save to local storage
        final prefs = await SharedPreferences.getInstance();
        final collections = prefs.getStringList('collections') ?? [];
        collections.add(jsonEncode(collection));
        await prefs.setStringList('collections', collections);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to collection')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    }
  }

  Widget _buildBody() {
    return Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Request Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // URL and Method Row
                  Row(
                    children: [
                      // Method Dropdown
                      DropdownButton<String>(
                        value: method,
                        items: ['GET', 'POST', 'PUT', 'DELETE']
                            .map((e) =>
                                DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (value) => setState(() => method = value!),
                      ),
                      const SizedBox(width: 16),
                      // URL TextField
                      Expanded(
                        child: TextField(
                          controller: _urlController,
                          decoration: const InputDecoration(
                            labelText: 'URL',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Headers Section
                  ExpansionTile(
                    title: const Text('Headers'),
                    children: [
                      _buildHeadersList(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Body Section
                  ExpansionTile(
                    title: const Text('Request Body'),
                    children: [
                      TextField(
                        controller: _bodyController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter request body',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Send Button
          ElevatedButton(
            onPressed: _sendRequest,
            child: const Text('Send Request'),
          ),
          const SizedBox(height: 16),
          // Response Section
          if (_response.isNotEmpty)
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status: $_statusCode'),
                      if (_responseTime != null)
                        Text('Time: ${_responseTime!.toStringAsFixed(2)}ms'),
                      const Divider(),
                      Expanded(child: _buildResponseView()),
                    ],
                  ),
                ),
              ),
            ),
        ]));
  }
}
