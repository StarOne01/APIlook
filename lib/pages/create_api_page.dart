import 'dart:convert';
import 'dart:io';

import 'package:apilook/services/local_api_server.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/api_endpoint.dart';
import '../widgets/code_workspace.dart';

class CreateAPIPage extends StatefulWidget {
  const CreateAPIPage({super.key});

  @override
  State<CreateAPIPage> createState() => _CreateAPIPageState();
}

class _CreateAPIPageState extends State<CreateAPIPage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _urlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedMethod = 'GET';
  final Map<String, String> _headers = {};
  final Map<String, String> _parameters = {};
  bool _isPublic = false;
  String? _testResponse;

  final LocalAPIServer _localServer = LocalAPIServer();
  bool _isTestMode = false;

  @override
  void initState() {
    super.initState();
    _startLocalServer();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    _localServer.stop();
    super.dispose();
  }

  String _apiLogic = '''
// Write your API logic here
function handleRequest(req, res) {
  res.json({
    message: "Hello World"
  });
}
''';

  final _responseExampleController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create API'),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            tooltip: 'Test API',
            onPressed: _isTestMode ? _testAPI : null,
          ),
          IconButton(
            icon: Icon(_isTestMode ? Icons.stop : Icons.play_circle),
            tooltip: _isTestMode ? 'Stop Server' : 'Start Server',
            onPressed: _toggleTestMode,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'API Name',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                value?.isEmpty ?? true ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _urlController,
                            decoration: const InputDecoration(
                              labelText: 'Endpoint URL',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                value?.isEmpty ?? true ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildMethodSelector(),
                          const SizedBox(height: 24),
                          _buildHeadersSection(),
                          const SizedBox(height: 24),
                          _buildParametersSection(),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: const Text('Public API'),
                            subtitle: const Text('Make this API public'),
                            value: _isPublic,
                            onChanged: (value) =>
                                setState(() => _isPublic = value),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 400,
                      child: _buildWorkspace(),
                    ),
                    const SizedBox(height: 16),
                    _buildTestSection(),
                  ],
                ),
              ),
            );
          } else {
            return Row(
              children: [
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'API Name',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                value?.isEmpty ?? true ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _urlController,
                            decoration: const InputDecoration(
                              labelText: 'Endpoint URL',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                value?.isEmpty ?? true ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildMethodSelector(),
                          const SizedBox(height: 24),
                          _buildHeadersSection(),
                          const SizedBox(height: 24),
                          _buildParametersSection(),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: const Text('Public API'),
                            subtitle: const Text('Make this API public'),
                            value: _isPublic,
                            onChanged: (value) =>
                                setState(() => _isPublic = value),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                    flex: 3,
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: SafeArea(
                          child: SingleChildScrollView(
                              child: Column(
                        children: [
                          _buildWorkspace(),
                          const SizedBox(height: 16),
                          _buildTestSection(),
                        ],
                      ))),
                    )),
                const SizedBox(width: 16),
              ],
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveAPI,
        label: const Text('Save API'),
        icon: const Icon(Icons.save),
      ),
    );
  }

  Widget _buildMethodSelector() {
    return DropdownButtonFormField<String>(
      value: _selectedMethod,
      decoration: const InputDecoration(
        labelText: 'HTTP Method',
        border: OutlineInputBorder(),
      ),
      items: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH']
          .map((method) => DropdownMenuItem(
                value: method,
                child: Text(method),
              ))
          .toList(),
      onChanged: (value) => setState(() => _selectedMethod = value!),
    );
  }

  Widget _buildHeadersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Headers',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addHeader,
            ),
          ],
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _headers.length,
          itemBuilder: (context, index) {
            String key = _headers.keys.elementAt(index);
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: key,
                        decoration: const InputDecoration(labelText: 'Key'),
                        onChanged: (value) => _updateHeaderKey(index, value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: _headers[key],
                        decoration: const InputDecoration(labelText: 'Value'),
                        onChanged: (value) => _updateHeaderValue(key, value),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _removeHeader(key),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildParametersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Parameters',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addParameter,
            ),
          ],
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _parameters.length,
          itemBuilder: (context, index) {
            String key = _parameters.keys.elementAt(index);
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: key,
                        decoration: const InputDecoration(labelText: 'Key'),
                        onChanged: (value) => _updateParameterKey(index, value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: _parameters[key],
                        decoration: const InputDecoration(labelText: 'Value'),
                        onChanged: (value) => _updateParameterValue(key, value),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _removeParameter(key),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildWorkspace() {
    return SizedBox(
      height: 400,
      child: APIWorkspace(
        code: _apiLogic,
        onCodeChanged: (code) => setState(() => _apiLogic = code),
        onExecute: _executeAPILogic,
      ),
    );
  }

  Widget _buildTestSection() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Test Mode'),
          value: _isTestMode,
          onChanged: (value) => setState(() => _isTestMode = value),
        ),
        if (_isTestMode) ...[
          ElevatedButton(
            onPressed: _testAPI,
            child: const Text('Test API'),
          ),
          if (_testResponse != null)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Response:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(_testResponse!),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }

  void _addHeader() {
    setState(() {
      _headers[''] = '';
    });
  }

  void _updateHeaderKey(int index, String newKey) {
    String oldKey = _headers.keys.elementAt(index);
    String? value = _headers[oldKey];
    setState(() {
      _headers.remove(oldKey);
      _headers[newKey] = value ?? '';
    });
  }

  void _updateHeaderValue(String key, String value) {
    setState(() {
      _headers[key] = value;
    });
  }

  void _removeHeader(String key) {
    setState(() {
      _headers.remove(key);
    });
  }

  void _addParameter() {
    setState(() {
      _parameters[''] = '';
    });
  }

  void _updateParameterKey(int index, String newKey) {
    String oldKey = _parameters.keys.elementAt(index);
    String? value = _parameters[oldKey];
    setState(() {
      _parameters.remove(oldKey);
      _parameters[newKey] = value ?? '';
    });
  }

  void _updateParameterValue(String key, String value) {
    setState(() {
      _parameters[key] = value;
    });
  }

  void _removeParameter(String key) {
    setState(() {
      _parameters.remove(key);
    });
  }

  Future<void> _saveAPI() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final response =
          await Supabase.instance.client.from('api_endpoints').insert({
        'name': _nameController.text,
        'url': _urlController.text,
        'method': _selectedMethod,
        'description': _descriptionController.text,
        'headers': _headers,
        'parameters': _parameters,
        'is_public': _isPublic,
        'user_id': Supabase.instance.client.auth.currentUser?.id,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (response.error != null) {
        throw response.error!;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving API: $e')),
      );
    }
  }

  Future<void> _testAPI() async {
    if (!_isTestMode) return;

    try {
      final uri = Uri.parse('http://localhost:8080${_urlController.text}');
      final response = await http.get(uri);

      String formattedResponse = '';
      try {
        final jsonData = json.decode(response.body);
        formattedResponse =
            const JsonEncoder.withIndent('  ').convert(jsonData);
      } catch (e) {
        formattedResponse = response.body;
      }

      setState(() {
        _testResponse = '''
Status: ${response.statusCode}
Time: ${DateTime.now().millisecondsSinceEpoch}ms

Headers:
${response.headers.entries.map((e) => '${e.key}: ${e.value}').join('\n')}

Body:
$formattedResponse
''';
      });
    } catch (e) {
      setState(() => _testResponse = jsonEncode({
            'error': 'Execution failed',
            'message': e.toString(),
          }));
    }
  }

  Future<void> _executeAPILogic(String code) async {
    if (!_isTestMode) return;

    try {
      final endpoint = APIEndpoint(
        id: 'test',
        userId: 'test',
        name: _nameController.text,
        url: _urlController.text,
        method: _selectedMethod,
        headers: _headers,
        parameters: _parameters,
        createdAt: DateTime.now(),
        logic: code,
      );

      _localServer.registerEndpoint(endpoint);

      final uri = Uri.parse('http://localhost:8080${_urlController.text}');
      final response = await http.get(uri);

      String formattedResponse = '';
      try {
        final jsonData = json.decode(response.body);
        formattedResponse =
            const JsonEncoder.withIndent('  ').convert(jsonData);
      } catch (e) {
        formattedResponse = response.body;
      }

      setState(() {
        _testResponse = '''
Status: ${response.statusCode}
Time: ${DateTime.now().millisecondsSinceEpoch}ms

Headers:
${response.headers.entries.map((e) => '${e.key}: ${e.value}').join('\n')}

Body:
$formattedResponse
''';
      });
    } catch (e) {
      setState(() => _testResponse = 'Error executing API logic: $e');
    }
  }

  Future<void> _startLocalServer() async {
    try {
      await _localServer.start();
      final endpoint = APIEndpoint(
        id: 'test',
        userId: 'test',
        name: _nameController.text,
        url: _urlController.text,
        method: _selectedMethod,
        headers: _headers,
        parameters: _parameters,
        logic: _apiLogic,
        createdAt: DateTime.now(),
      );
      _localServer.registerEndpoint(endpoint);
      setState(() => _testResponse = 'Server started successfully');
    } catch (e) {
      setState(() => _testResponse = 'Server error: $e');
    }
  }

  Future<void> _toggleTestMode() async {
    if (_isTestMode) {
      await _localServer.stop();
    } else {
      await _startLocalServer();
    }
    setState(() => _isTestMode = !_isTestMode);
  }
}
