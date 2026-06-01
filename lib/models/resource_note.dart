import 'dart:convert';

/// Model Catatan Belajar / Key Takeaway untuk Modul Resource
class ResourceNote {
  final int? id;
  final int resourceId;
  final String content;
  final DateTime createdAt;

  ResourceNote({
    this.id,
    required this.resourceId,
    required this.content,
    required this.createdAt,
  });

  /// Mengubah objek menjadi Map untuk penyimpanan SQLite
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'resourceId': resourceId,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  /// Membuat objek dari Map SQLite
  factory ResourceNote.fromMap(Map<String, dynamic> map) {
    return ResourceNote(
      id: map['id'] as int?,
      resourceId: map['resourceId'] as int,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  /// Helper untuk konversi ke format JSON
  String toJson() => json.encode(toMap());

  /// Membuat salinan objek dengan modifikasi bidang tertentu
  ResourceNote copyWith({
    int? id,
    int? resourceId,
    String? content,
    DateTime? createdAt,
  }) {
    return ResourceNote(
      id: id ?? this.id,
      resourceId: resourceId ?? this.resourceId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
