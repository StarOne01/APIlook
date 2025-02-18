import 'package:apilize/services/local_api_server.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/api_endpoint.dart';

class CreateAPIPage extends StatefulWidget {
  const CreateAPIPage({super.key});

  @override
  State<CreateAPIPage> createState() => _CreateAPIPageState();
}

class _CreateAPIPageState extends State<CreateAPIPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  String _selectedMethod = 'GET';
  final Map<String, String> _headers = {};
  final Map<String, String> _parameters = {};

  final LocalAPIServer _localServer = LocalAPIServer();
  bool _isTestMode = false;
  String? _testResponse;

  @override
  void initState() {
    super.initState();
    _startLocalServer();
  }

  Future<void> _startLocalServer() async {
    await _localServer.start();
  }

  @override
  void dispose() {
    _localServer.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create API')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'API Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                border: OutlineInputBorder(),
                hintText: 'https://api.example.com/endpoint',
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'URL is required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Method',
                border: OutlineInputBorder(),
              ),
              value: _selectedMethod,
              items: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'].map((method) {
                return DropdownMenuItem(value: method, child: Text(method));
              }).toList(),
              onChanged: (value) => setState(() => _selectedMethod = value!),
            ),
            const SizedBox(height: 24),
            _buildHeadersSection(),
            const SizedBox(height: 24),
            _buildParametersSection(),
            const SizedBox(height: 32),
            _buildTestSection(),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveAPI,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Save API'),
            ),
          ],
        ),
      ),
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
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final response =
            await Supabase.instance.client.from('api_endpoints').insert({
          'name': _nameController.text,
          'url': _urlController.text,
          'method': _selectedMethod,
          'headers': _headers,
          'parameters': _parameters,
        });

        if (mounted) {
          if (response.error == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('API saved successfully')),
            );
            Navigator.pop(context);
          } else {
            throw response.error!;
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving API: $e')),
          );
        }
      }
    }
  }

  Future<void> _testAPI() async {
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
      );

      _localServer.registerEndpoint(endpoint);

      final uri =
          Uri.parse('http://localhost:3000${Uri.parse(endpoint.url).path}');
      final response = await http.get(uri);

      setState(() {
        _testResponse = '''
Status: ${response.statusCode}
Body: ${response.body}
''';
      });
    } catch (e) {
      setState(() {
        _testResponse = 'Error: $e';
      });
    }
  }
}
