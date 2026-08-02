import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/grocery_item.dart';
import '../models/consumption_log.dart';
import '../services/prediction_service.dart';

class DatabaseService {
  SupabaseClient get _client => SupabaseConfig.client;

  // In-memory mock storage for when Supabase is not configured
  static final List<GroceryItem> _mockItems = [
    GroceryItem(
      id: 'mock-1',
      householdId: 'demo-household',
      name: 'Whole Milk (1 Gallon)',
      category: 'Dairy',
      status: ItemStatus.LOW,
      unit: 'bottles',
      quantity: 1.0,
      predictedOutDate: DateTime.now().add(const Duration(days: 1)),
      lastRestockedAt: DateTime.now().subtract(const Duration(days: 5)),
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    GroceryItem(
      id: 'mock-2',
      householdId: 'demo-household',
      name: 'Organic Avocados',
      category: 'Produce',
      status: ItemStatus.OUT_OF_STOCK,
      unit: 'pcs',
      quantity: 4.0,
      predictedOutDate: DateTime.now().subtract(const Duration(days: 1)),
      lastRestockedAt: DateTime.now().subtract(const Duration(days: 7)),
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    ),
    GroceryItem(
      id: 'mock-3',
      householdId: 'demo-household',
      name: 'Dark Roast Coffee Beans',
      category: 'Beverages',
      status: ItemStatus.IN_STOCK,
      unit: 'packs',
      quantity: 2.0,
      predictedOutDate: DateTime.now().add(const Duration(days: 2)),
      lastRestockedAt: DateTime.now().subtract(const Duration(days: 10)),
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    GroceryItem(
      id: 'mock-4',
      householdId: 'demo-household',
      name: 'Extra Firm Tofu',
      category: 'Produce',
      status: ItemStatus.IN_STOCK,
      unit: 'packs',
      quantity: 3.0,
      predictedOutDate: DateTime.now().add(const Duration(days: 5)),
      lastRestockedAt: DateTime.now().subtract(const Duration(days: 2)),
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    GroceryItem(
      id: 'mock-5',
      householdId: 'demo-household',
      name: 'Paper Towels (6 Rolls)',
      category: 'Household & Cleaning',
      status: ItemStatus.LOW,
      unit: 'packs',
      quantity: 1.0,
      predictedOutDate: DateTime.now().add(const Duration(days: 1)),
      lastRestockedAt: DateTime.now().subtract(const Duration(days: 12)),
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    GroceryItem(
      id: 'mock-6',
      householdId: 'demo-household',
      name: 'Oat Milk (1 Liter)',
      category: 'Dairy',
      status: ItemStatus.IN_STOCK,
      unit: 'cartons',
      quantity: 2.0,
      predictedOutDate: DateTime.now().add(const Duration(days: 6)),
      lastRestockedAt: DateTime.now().subtract(const Duration(days: 1)),
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  static final List<ConsumptionLog> _mockLogs = [];
  static final StreamController<List<GroceryItem>> _mockStreamController =
      StreamController<List<GroceryItem>>.broadcast();

  /// Stream of real-time grocery items updates
  Stream<List<GroceryItem>> streamGroceryItems(String householdId) {
    if (!SupabaseConfig.isConfigured) {
      // Emit current mock state immediately and on updates
      Future.microtask(() => _mockStreamController.add(List.from(_mockItems)));
      return _mockStreamController.stream;
    }

    return _client
        .from('grocery_items')
        .stream(primaryKey: ['id'])
        .eq('household_id', householdId)
        .order('name', ascending: true)
        .map((data) => data.map((json) => GroceryItem.fromJson(json)).toList());
  }

  /// Fetch grocery items
  Future<List<GroceryItem>> getGroceryItems(String householdId) async {
    if (!SupabaseConfig.isConfigured) {
      return List.from(_mockItems);
    }

    final response = await _client
        .from('grocery_items')
        .select()
        .eq('household_id', householdId)
        .order('name', ascending: true);

    return (response as List)
        .map((json) => GroceryItem.fromJson(json))
        .toList();
  }

  /// Create item
  Future<GroceryItem> addItem(GroceryItem item) async {
    if (!SupabaseConfig.isConfigured) {
      _mockItems.add(item);
      _notifyMockListeners();
      await logConsumption(item.id, LogAction.RESTOCKED);
      return item;
    }

    final response = await _client
        .from('grocery_items')
        .insert(item.toJson()..remove('id'))
        .select()
        .single();

    final newItem = GroceryItem.fromJson(response);
    await logConsumption(newItem.id, LogAction.RESTOCKED);
    return newItem;
  }

  /// Update item
  Future<void> updateItem(GroceryItem item) async {
    if (!SupabaseConfig.isConfigured) {
      final index = _mockItems.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _mockItems[index] = item;
        _notifyMockListeners();
      }
      return;
    }

    await _client
        .from('grocery_items')
        .update(item.toJson())
        .eq('id', item.id);
  }

  /// Update status (e.g. IN_STOCK, LOW, OUT_OF_STOCK)
  Future<void> updateItemStatus(String itemId, ItemStatus status) async {
    final now = DateTime.now();

    if (!SupabaseConfig.isConfigured) {
      final index = _mockItems.indexWhere((i) => i.id == itemId);
      if (index != -1) {
        final current = _mockItems[index];
        _mockItems[index] = current.copyWith(
          status: status,
          lastRestockedAt: status == ItemStatus.IN_STOCK ? now : current.lastRestockedAt,
          updatedAt: now,
        );
        _notifyMockListeners();
      }

      final logAction = (status == ItemStatus.OUT_OF_STOCK || status == ItemStatus.LOW)
          ? LogAction.EMPTIED
          : LogAction.RESTOCKED;

      await logConsumption(itemId, logAction);
      await recalculateAndSavePrediction(itemId);
      return;
    }

    final Map<String, dynamic> updateData = {
      'status': status.name,
      'updated_at': now.toIso8601String(),
    };

    if (status == ItemStatus.IN_STOCK) {
      updateData['last_restocked_at'] = now.toIso8601String();
    }

    await _client.from('grocery_items').update(updateData).eq('id', itemId);

    final logAction = (status == ItemStatus.OUT_OF_STOCK || status == ItemStatus.LOW)
        ? LogAction.EMPTIED
        : LogAction.RESTOCKED;

    await logConsumption(itemId, logAction);
    await recalculateAndSavePrediction(itemId);
  }

  /// Delete item
  Future<void> deleteItem(String itemId) async {
    if (!SupabaseConfig.isConfigured) {
      _mockItems.removeWhere((i) => i.id == itemId);
      _notifyMockListeners();
      return;
    }

    await _client.from('grocery_items').delete().eq('id', itemId);
  }

  /// Log consumption action
  Future<void> logConsumption(String itemId, LogAction action) async {
    final log = ConsumptionLog(
      id: 'log-${DateTime.now().millisecondsSinceEpoch}',
      itemId: itemId,
      action: action,
      createdAt: DateTime.now(),
    );

    if (!SupabaseConfig.isConfigured) {
      _mockLogs.add(log);
      return;
    }

    await _client.from('consumption_logs').insert({
      'item_id': itemId,
      'action': action.name,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Fetch consumption logs
  Future<List<ConsumptionLog>> getConsumptionLogs(String itemId) async {
    if (!SupabaseConfig.isConfigured) {
      return _mockLogs.where((l) => l.itemId == itemId).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    final response = await _client
        .from('consumption_logs')
        .select()
        .eq('item_id', itemId)
        .order('created_at', ascending: true);

    return (response as List)
        .map((json) => ConsumptionLog.fromJson(json))
        .toList();
  }

  /// Recalculate and update predicted_out_date
  Future<DateTime?> recalculateAndSavePrediction(String itemId) async {
    try {
      final logs = await getConsumptionLogs(itemId);
      final predictedDate = PredictionService.calculateNextDepletion(logs);

      if (!SupabaseConfig.isConfigured) {
        final index = _mockItems.indexWhere((i) => i.id == itemId);
        if (index != -1) {
          _mockItems[index] = _mockItems[index].copyWith(
            predictedOutDate: predictedDate,
          );
          _notifyMockListeners();
        }
        return predictedDate;
      }

      await _client.from('grocery_items').update({
        'predicted_out_date': predictedDate.toIso8601String().split('T')[0],
      }).eq('id', itemId);

      return predictedDate;
    } catch (e) {
      return null;
    }
  }

  /// Batch restock items
  Future<void> batchRestockItems(List<String> itemIds) async {
    if (itemIds.isEmpty) return;

    for (final id in itemIds) {
      await updateItemStatus(id, ItemStatus.IN_STOCK);
    }
  }

  static void _notifyMockListeners() {
    _mockStreamController.add(List.from(_mockItems));
  }
}
