import 'dart:io';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import '../models/api_endpoint.dart';

class LocalAPIServer {
  HttpServer? _server;
  final Map<String, APIEndpoint> _endpoints = {};

  Future<void> start({int port = 3000}) async {
    var handler = const shelf.Pipeline()
        .addMiddleware(shelf.logRequests())
        .addHandler(_handleRequest);

    _server = await io.serve(handler, 'localhost', port);
    print('Local API Server running on port ${_server!.port}');
  }

  Future<shelf.Response> _handleRequest(shelf.Request request) async {
    final endpoint = _endpoints[request.url.path];

    if (endpoint == null) {
      return shelf.Response.notFound('Endpoint not found');
    }

    if (request.method != endpoint.method) {
      return shelf.Response(405, body: 'Method not allowed');
    }

    // Mock response
    return shelf.Response.ok(
      '{"status": "success", "message": "Mock response"}',
      headers: {'content-type': 'application/json'},
    );
  }

  void registerEndpoint(APIEndpoint endpoint) {
    final path = Uri.parse(endpoint.url).path;
    _endpoints[path] = endpoint;
  }

  Future<void> stop() async {
    await _server?.close();
    _server = null;
  }
}
