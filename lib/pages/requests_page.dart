import 'package:apilook/auth/auth_controller.dart';
import 'package:apilook/dashboard.dart';
import 'package:apilook/pages/profile_page.dart';
import 'package:apilook/pages/requests_page.dart';
import 'package:apilook/pages/settings_page.dart';
import 'package:apilook/services/supabase_service.dart';
import 'package:apilook/syntax_highlighter.dart';
import 'package:apilook/theme.dart';
import 'package:apilook/views/login_view.dart';
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
  // UI Controllers
  late final TabController _tabController;
  late final TextEditingController _urlController;
  late final TextEditingController _bodyController;

  // Request State
  String _selectedMethod = 'GET';
  final Map<String, String> _headers = {};
  String _response = '';
  int? _statusCode;
  double? _responseTime;

  // HTTP Methods
  final List<String> _httpMethods = ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _urlController = TextEditingController();
    _bodyController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    // Responsive layout
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth > 900) {
        return _buildDesktopLayout();
      }
      return _buildMobileLayout();
    });
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          // Left panel - Request Config
          Expanded(
            flex: 1,
            child: _buildRequestPanel(),
          ),
          // Right panel - Response
          Expanded(
            flex: 1,
            child: _buildResponsePanel(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _sendRequest,
        child: const Icon(Icons.send),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('API Client'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Request'),
              Tab(text: 'Response'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildRequestPanel(),
            _buildResponsePanel(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _sendRequest,
          child: const Icon(Icons.send),
        ),
      ),
    );
  }

  Future<void> _sendRequest() async {
    try {
      setState(() {
        _response = '';
        _statusCode = null;
        _responseTime = null;
      });

      final stopwatch = Stopwatch()..start();

      final uri = Uri.parse(_urlController.text);
      final request = http.Request(_selectedMethod, uri);

      // Add headers
      request.headers.addAll(_headers);

      // Add body for non-GET requests
      if (_selectedMethod != 'GET' && _bodyController.text.isNotEmpty) {
        request.body = _bodyController.text;
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      stopwatch.stop();

      setState(() {
        _response = response.body;
        _statusCode = response.statusCode;
        _responseTime = stopwatch.elapsedMilliseconds.toDouble();
      });
    } catch (e) {
      setState(() {
        _response = 'Error: ${e.toString()}';
        _statusCode = 500;
      });
    }
  }

  Widget _buildRequestPanel() {
    return Card(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMethodSelector(),
          const SizedBox(height: 16),
          _buildUrlField(),
          const SizedBox(height: 16),
          _buildHeadersSection(),
          const SizedBox(height: 16),
          _buildBodySection(),
        ],
      ),
    );
  }

  Widget _buildResponsePanel() {
    return Card(
      child: Column(
        children: [
          _buildResponseTabs(),
          Expanded(
            child: _buildResponseContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseTabs() {
    return TabBar(
      controller: _tabController,
      tabs: const [
        Tab(text: 'Pretty', icon: Icon(Icons.code)),
        Tab(text: 'Raw', icon: Icon(Icons.text_fields)),
        Tab(text: 'Preview', icon: Icon(Icons.preview)),
      ],
    );
  }

  Widget _buildResponseContent() {
    if (_response.isEmpty) {
      return const Center(child: Text('No response yet'));
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildPrettyResponse(),
        _buildRawResponse(),
        _buildPreviewResponse(),
      ],
    );
  }

  Widget _buildMethodSelector() {
    return DropdownButtonFormField<String>(
      value: _selectedMethod,
      decoration: const InputDecoration(
        labelText: 'Method',
        border: OutlineInputBorder(),
      ),
      items: _httpMethods.map((String method) {
        return DropdownMenuItem<String>(
          value: method,
          child: Text(method),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() => _selectedMethod = newValue);
        }
      },
    );
  }

  Widget _buildUrlField() {
    return TextField(
      controller: _urlController,
      decoration: const InputDecoration(
        labelText: 'URL',
        hintText: 'https://api.example.com',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.link),
      ),
      keyboardType: TextInputType.url,
    );
  }

  Widget _buildHeadersSection() {
    return Card(
      child: ExpansionTile(
        title: const Text('Headers'),
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _headers.length + 1,
            itemBuilder: (context, index) {
              if (index == _headers.length) {
                return ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Add Header'),
                  onTap: () {
                    setState(() {
                      _headers[''] = '';
                    });
                  },
                );
              }

              String key = _headers.keys.elementAt(index);
              return ListTile(
                title: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Key',
                        ),
                        onChanged: (value) {
                          setState(() {
                            String oldValue = _headers[key]!;
                            _headers.remove(key);
                            _headers[value] = oldValue;
                          });
                        },
                        controller: TextEditingController(text: key),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Value',
                        ),
                        onChanged: (value) {
                          setState(() {
                            _headers[key] = value;
                          });
                        },
                        controller: TextEditingController(text: _headers[key]),
                      ),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      _headers.remove(key);
                    });
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBodySection() {
    return Card(
      child: ExpansionTile(
        title: const Text('Body'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _bodyController,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: 'Request Body (JSON)',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status: ${_statusCode ?? "N/A"}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'Time: ${_responseTime?.toStringAsFixed(2) ?? "N/A"} ms',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () => _copyToClipboard(_response),
            tooltip: 'Copy Response',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => Share.share(_response),
            tooltip: 'Share Response',
          ),
        ],
      ),
    );
  }

  Widget _buildPrettyResponse() {
    try {
      final dynamic parsedJson = jsonDecode(_response);
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: JsonView(
          json: parsedJson,
          theme: JsonViewTheme(
            backgroundColor: Theme.of(context).cardColor,
            stringStyle: const TextStyle(color: Colors.green),
            numberStyle: const TextStyle(color: Colors.blue),
            boolStyle: const TextStyle(color: Colors.red),
          ),
        ),
      );
    } catch (e) {
      return Center(child: Text('Invalid JSON: $e'));
    }
  }

  Widget _buildRawResponse() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status and timing info
          Text(
            'Status Code: ${_statusCode ?? "N/A"}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            'Response Time: ${_responseTime?.toStringAsFixed(2) ?? "N/A"} ms',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Headers section
          const Text(
            'Headers:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          for (var header in _headers.entries)
            Text('${header.key}: ${header.value}'),
          const SizedBox(height: 16),

          // Response body
          const Text(
            'Body:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          SelectableText(
            _response,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
  }

  Widget _buildPreviewResponse() {
    if (_response.isEmpty) {
      return const Center(child: Text('No response to preview'));
    }

    try {
      // Try to parse JSON
      final dynamic parsedJson = jsonDecode(_response);

      // If it's a list of maps, show as table
      if (parsedJson is List &&
          parsedJson.isNotEmpty &&
          parsedJson.first is Map) {
        // Get columns from first item
        final columns = (parsedJson.first as Map).keys.toList();

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              columns: columns
                  .map((col) => DataColumn(label: Text(col.toString())))
                  .toList(),
              rows: parsedJson.map<DataRow>((item) {
                return DataRow(
                  cells: columns
                      .map((col) => DataCell(Text(item[col]?.toString() ?? '')))
                      .toList(),
                );
              }).toList(),
            ),
          ),
        );
      }

      // If it's a single map, show as key-value pairs
      if (parsedJson is Map) {
        return SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Key')),
              DataColumn(label: Text('Value')),
            ],
            rows: parsedJson.entries
                .map((entry) => DataRow(cells: [
                      DataCell(Text(entry.key.toString())),
                      DataCell(Text(entry.value?.toString() ?? '')),
                    ]))
                .toList(),
          ),
        );
      }
    } catch (e) {
      // If not valid JSON, try other formats
      if (_response.trim().startsWith('<')) {
        return WebViewWidget(
          controller: WebViewController()
            ..loadHtmlString(_response)
            ..setBackgroundColor(Theme.of(context).scaffoldBackgroundColor),
        );
      } else if (_response.trim().startsWith('data:image')) {
        return Center(
          child: Image.memory(
            base64Decode(_response.split(',')[1]),
            errorBuilder: (context, error, stackTrace) =>
                const Text('Unable to preview image'),
          ),
        );
      }
    }

    // Fallback to raw view
    return _buildRawResponse();
  }
}
