import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

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

      setState(() {
        responseBody = const JsonEncoder.withIndent('  ')
            .convert(json.decode(response.body));
        statusCode = response.statusCode;
      });
    } catch (e) {
      setState(() {
        responseBody = 'Error: $e';
        statusCode = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final bool isWideScreen = constraints.maxWidth > 600;

      return Scaffold(
        appBar: AppBar(
          title: const Text('APIlize'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            if (!Platform.isAndroid && !Platform.isIOS)
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: () {/* Save request */},
                tooltip: 'Save (Ctrl+S)',
              ),
          ],
        ),
        body: isWideScreen
            ? Row(
                children: [
                  Expanded(child: _buildRequestPanel()),
                  const VerticalDivider(),
                  Expanded(child: _buildResponsePanel()),
                ],
              )
            : Column(
                children: [
                  Expanded(child: _buildRequestPanel()),
                  const Divider(),
                  Expanded(child: _buildResponsePanel()),
                ],
              ),
      );
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
}
