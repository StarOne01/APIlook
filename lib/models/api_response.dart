class APIResponse {
  final int statusCode;
  final Map<String, String> headers;
  final dynamic body;
  final DateTime timestamp;
  final String? error;

  APIResponse({
    required this.statusCode,
    required this.headers,
    required this.body,
    required this.timestamp,
    this.error,
  });

  Map<String, dynamic> toJson() => {
        'statusCode': statusCode,
        'headers': headers,
        'body': body,
        'timestamp': timestamp.toIso8601String(),
        if (error != null) 'error': error,
      };
}
