import 'dart:async';
import 'dart:io';
import 'dart:convert';
import '../models/api_endpoint.dart';

class LocalAPIServer {
  HttpServer? _server;
  bool _isRunning = false;
  final Map<String, APIEndpoint> _endpoints = {};
  static const int PORT = 8080;
  static const int MAX_RETRIES = 3;

  bool get isRunning => _isRunning;

  Future<bool> _isPortAvailable(InternetAddress address, int port) async {
    try {
      final socket = await ServerSocket.bind(address, port, shared: true);
      await socket.close();
      return true;
    } catch (e) {
      print('Port $port not available on $address: $e');
      return false;
    }
  }

  Future<void> start() async {
    if (_isRunning) return;

    try {
      // First try to bind to IPv4 loopback
      _server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        PORT,
        shared: true,
      );

      _isRunning = true;
      print('Server started on ${_server!.address.host}:${_server!.port}');

      _server!.listen(
        _handleRequest,
        onError: (e) {
          print('Server error: $e');
          stop();
        },
      );
    } catch (e) {
      print('Failed to start server: $e');
      _isRunning = false;
      rethrow;
    }
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _isRunning = false;
    _endpoints.clear();
  }

  void registerEndpoint(APIEndpoint endpoint) {
    // Normalize URL path to ensure it starts with /
    final path =
        endpoint.url.startsWith('/') ? endpoint.url : '/${endpoint.url}';
    _endpoints[path] = endpoint;
    print('Registered endpoint: $path');
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      request.response.headers.add('Access-Control-Allow-Origin', '*');

      final endpoint = _endpoints[request.uri.path];
      if (endpoint == null) {
        request.response.statusCode = HttpStatus.notFound;
        request.response.write('Endpoint not found');
        await request.response.close();
        return;
      }

      // Use the endpoint's logic instead of static response
      final response = {
        'endpoint': endpoint.name,
        'method': endpoint.method,
        'headers': endpoint.headers,
        'parameters': endpoint.parameters,
        'logic': endpoint.logic
      };

      final bytes = utf8.encode(json.encode(response));

      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentType = ContentType.json;
      request.response.add(bytes);
      await request.response.close();
    } catch (e) {
      print('Error handling request: $e');
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write('Internal server error');
      await request.response.close();
    }
  }
}
