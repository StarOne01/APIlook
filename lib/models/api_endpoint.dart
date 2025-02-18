class APIEndpoint {
  final String id;
  final String userId;
  final String name;
  final String url;
  final String method;
  final String logic;
  final Map<String, dynamic> headers;
  final Map<String, dynamic> parameters;
  final DateTime createdAt;
  final bool active;

  APIEndpoint({
    required this.id,
    required this.userId,
    required this.name,
    required this.url,
    required this.method,
    required this.logic,
    this.headers = const {},
    this.parameters = const {},
    required this.createdAt,
    this.active = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'url': url,
        'method': method,
        'logic': logic,
        'headers': headers,
        'parameters': parameters,
        'active': active,
      };

  factory APIEndpoint.fromJson(Map<String, dynamic> json) => APIEndpoint(
        id: json['id'],
        userId: json['user_id'],
        name: json['name'],
        url: json['url'],
        method: json['method'],
        logic: json['logic'] ?? '',
        headers: json['headers'] ?? {},
        parameters: json['parameters'] ?? {},
        createdAt: DateTime.parse(json['created_at']),
        active: json['active'] ?? true,
      );

  bool get isLocalhost =>
      Uri.parse(url).host == 'localhost' || Uri.parse(url).host == '127.0.0.1';
}
