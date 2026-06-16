class User {
  final int? id;
  final String name;
  final String email;
  final String password;
  final DateTime createdAt;
  final String?
  photoPath; // Path atau nama archetype avatar terpilih / Base64 string
  final String? phone; // Nomor telepon pengguna

  User({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.createdAt,
    this.photoPath,
    this.phone,
  });

  /// Menyalin objek User dengan beberapa modifikasi bidang
  User copyWith({
    int? id,
    String? name,
    String? email,
    String? password,
    DateTime? createdAt,
    String? photoPath,
    String? phone,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
      photoPath: photoPath ?? this.photoPath,
      phone: phone ?? this.phone,
    );
  }

  /// Konversi objek ke Map untuk penyimpanan SQLite / JSON
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'email': email,
      'password': password,
      'createdAt': createdAt.toIso8601String(),
      'photoPath': photoPath,
      'phone': phone,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  /// Parsing Map/JSON dari SQLite / SharedPreferences ke objek User
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      photoPath: map['photoPath'] as String?,
      phone: map['phone'] as String?,
    );
  }
}
