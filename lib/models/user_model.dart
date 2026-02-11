class UserModel {
  final String id;
  final String displayName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({required this.id, required this.displayName, required this.createdAt, required this.updatedAt});

  UserModel copyWith({String? id, String? displayName, DateTime? createdAt, DateTime? updatedAt}) {
    return UserModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'displayName': displayName,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final createdRaw = json['created_at'];
    final updatedRaw = json['updated_at'];
    return UserModel(
      id: (json['id'] ?? '').toString(),
      displayName: (json['displayName'] ?? 'You').toString(),
      createdAt: DateTime.tryParse(createdRaw?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse(updatedRaw?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
