import 'package:http/http.dart';

class Collection {
  final String id;
  final String name;
  final String description;
  final String type;
  final bool isPinned;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Request> requests;
  final String? icon;

  Collection({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.isPinned = false,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.requests = const [],
    this.icon,
  });

  Collection copyWith({
    String? id,
    String? name,
    String? description,
    String? type,
    bool? isPinned,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Request>? requests,
    String? icon,
  }) {
    return Collection(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      isPinned: isPinned ?? this.isPinned,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      requests: requests ?? this.requests,
      icon: icon ?? this.icon,
    );
  }
}
