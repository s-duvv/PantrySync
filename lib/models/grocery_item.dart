enum ItemStatus { IN_STOCK, LOW, OUT_OF_STOCK }

class GroceryItem {
  final String id;
  final String householdId;
  final String name;
  final String category;
  final ItemStatus status;
  final String unit;
  final double quantity;
  final DateTime? predictedOutDate;
  final DateTime lastRestockedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  GroceryItem({
    required this.id,
    required this.householdId,
    required this.name,
    required this.category,
    required this.status,
    required this.unit,
    this.quantity = 1.0,
    this.predictedOutDate,
    required this.lastRestockedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GroceryItem.fromJson(Map<String, dynamic> json) {
    return GroceryItem(
      id: json['id'],
      householdId: json['household_id'],
      name: json['name'],
      category: json['category'] ?? 'General',
      status: ItemStatus.values.byName(json['status'] ?? 'IN_STOCK'),
      unit: json['unit'] ?? 'pcs',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      predictedOutDate: json['predicted_out_date'] != null
          ? DateTime.parse(json['predicted_out_date'])
          : null,
      lastRestockedAt: json['last_restocked_at'] != null
          ? DateTime.parse(json['last_restocked_at'])
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'household_id': householdId,
        'name': name,
        'category': category,
        'status': status.name,
        'unit': unit,
        'quantity': quantity,
        'predicted_out_date':
            predictedOutDate?.toIso8601String().split('T')[0],
        'last_restocked_at': lastRestockedAt.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

  GroceryItem copyWith({
    String? id,
    String? householdId,
    String? name,
    String? category,
    ItemStatus? status,
    String? unit,
    double? quantity,
    DateTime? predictedOutDate,
    DateTime? lastRestockedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GroceryItem(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      name: name ?? this.name,
      category: category ?? this.category,
      status: status ?? this.status,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      predictedOutDate: predictedOutDate ?? this.predictedOutDate,
      lastRestockedAt: lastRestockedAt ?? this.lastRestockedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
