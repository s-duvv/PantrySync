enum ItemStatus { IN_STOCK, LOW, OUT_OF_STOCK }

class GroceryItem {
  final String id;
  final String householdId;
  final String name;
  final String category;
  final ItemStatus status;
  final String unit;
  final DateTime? predictedOutDate;
  final DateTime lastRestockedAt;

  GroceryItem({
    required this.id,
    required this.householdId,
    required this.name,
    required this.category,
    required this.status,
    required this.unit,
    this.predictedOutDate,
    required this.lastRestockedAt,
  });

  factory GroceryItem.fromJson(Map<String, dynamic> json) {
    return GroceryItem(
      id: json['id'],
      householdId: json['household_id'],
      name: json['name'],
      category: json['category'] ?? 'General',
      status: ItemStatus.values.byName(json['status']),
      unit: json['unit'] ?? 'pcs',
      predictedOutDate: json['predicted_out_date'] != null 
          ? DateTime.parse(json['predicted_out_date']) 
          : null,
      lastRestockedAt: DateTime.parse(json['last_restocked_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'household_id': householdId,
    'name': name,
    'category': category,
    'status': status.name,
    'unit': unit,
    'predicted_out_date': predictedOutDate?.toIso8601String().split('T')[0],
    'last_restocked_at': lastRestockedAt.toIso8601String(),
  };
}