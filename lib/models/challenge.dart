class Challenge {
  final int? id;
  final int? userId;
  final int? skillId;
  final String title;
  final String description;
  final DateTime targetDate;
  final int isCompleted;

  Challenge({
    this.id,
    this.userId,
    this.skillId,
    required this.title,
    this.description = '',
    required this.targetDate,
    this.isCompleted = 0,
  });

  Challenge copyWith({
    int? id,
    int? userId,
    int? skillId,
    String? title,
    String? description,
    DateTime? targetDate,
    int? isCompleted,
  }) {
    return Challenge(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      skillId: skillId ?? this.skillId,
      title: title ?? this.title,
      description: description ?? this.description,
      targetDate: targetDate ?? this.targetDate,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'description': description,
      'targetDate': targetDate.toIso8601String(),
      'isCompleted': isCompleted,
    };
    if (id != null) {
      map['id'] = id;
    }
    if (userId != null) {
      map['userId'] = userId;
    }
    if (skillId != null) {
      map['skillId'] = skillId;
    }
    return map;
  }

  factory Challenge.fromMap(Map<String, dynamic> map) {
    return Challenge(
      id: map['id'] as int?,
      userId: map['userId'] as int?,
      skillId: map['skillId'] as int?,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      targetDate: DateTime.parse(map['targetDate'] as String? ?? DateTime.now().toIso8601String()),
      isCompleted: map['isCompleted'] as int? ?? 0,
    );
  }
}
