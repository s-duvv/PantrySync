enum LogAction { RESTOCKED, EMPTIED }

class ConsumptionLog {
  final String id;
  final String itemId;
  final LogAction action;
  final DateTime createdAt;

  ConsumptionLog({
    required this.id,
    required this.itemId,
    required this.action,
    required this.createdAt,
  });

  factory ConsumptionLog.fromJson(Map<String, dynamic> json) {
    return ConsumptionLog(
      id: json['id'],
      itemId: json['item_id'],
      action: LogAction.values.byName(json['action']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'item_id': itemId,
        'action': action.name,
        'created_at': createdAt.toIso8601String(),
      };
}
