class ProgressLog {
  final int? id;
  final int? userId;
  final int? skillId;
  final String title;
  final String note;
  final int durationMinutes;
  final DateTime date;
  final String? photoPath;

  ProgressLog({
    this.id,
    this.userId,
    this.skillId,
    required this.title,
    this.note = '',
    this.durationMinutes = 0,
    required this.date,
    this.photoPath,
  });

  ProgressLog copyWith({
    int? id,
    int? userId,
    int? skillId,
    String? title,
    String? note,
    int? durationMinutes,
    DateTime? date,
    String? photoPath,
  }) {
    return ProgressLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      skillId: skillId ?? this.skillId,
      title: title ?? this.title,
      note: note ?? this.note,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      date: date ?? this.date,
      photoPath: photoPath ?? this.photoPath,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'note': note,
      'durationMinutes': durationMinutes,
      'date': date.toIso8601String(),
      'photoPath': photoPath,
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

  factory ProgressLog.fromMap(Map<String, dynamic> map) {
    return ProgressLog(
      id: map['id'] as int?,
      userId: map['userId'] as int?,
      skillId: map['skillId'] as int?,
      title: map['title'] as String? ?? '',
      note: map['note'] as String? ?? '',
      durationMinutes: map['durationMinutes'] as int? ?? 0,
      date: DateTime.parse(map['date'] as String? ?? DateTime.now().toIso8601String()),
      photoPath: map['photoPath'] as String?,
    );
  }
}
