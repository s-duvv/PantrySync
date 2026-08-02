class Household {
  final String id;
  final String name;
  final DateTime createdAt;

  Household({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory Household.fromJson(Map<String, dynamic> json) {
    return Household(
      id: json['id'],
      name: json['name'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'created_at': createdAt.toIso8601String(),
      };
}

class UserProfile {
  final String id;
  final String? householdId;
  final String displayName;
  final String role; // 'admin' or 'member'
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    this.householdId,
    required this.displayName,
    this.role = 'member',
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      householdId: json['household_id'],
      displayName: json['display_name'] ?? 'User',
      role: json['role'] ?? 'member',
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'household_id': householdId,
        'display_name': displayName,
        'role': role,
        'updated_at': updatedAt.toIso8601String(),
      };

  UserProfile copyWith({
    String? id,
    String? householdId,
    String? displayName,
    String? role,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
