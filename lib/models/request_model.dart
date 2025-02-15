import 'package:postgrest/src/types.dart';

class RequestModel {
  final String id;
  final String name;
  final String url;
  final String method;
  final Map<String, dynamic> headers;
  final dynamic body;

  RequestModel({
    required this.id,
    required this.name,
    required this.url,
    required this.method,
    required this.headers,
    this.body,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
        'method': method,
        'headers': headers,
        'body': body,
      };

  static Future<List<RequestModel>> fromJson(PostgrestMap json) async {
    final items = json['data'] as List;
    return items
        .map((item) => RequestModel(
              id: item['id'],
              name: item['name'],
              url: item['url'],
              method: item['method'],
              headers: item['headers'],
              body: item['body'],
            ))
        .toList();
  }
}
