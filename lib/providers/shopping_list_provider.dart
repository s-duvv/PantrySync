import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/grocery_item.dart';
import '../services/prediction_service.dart';
import 'inventory_provider.dart';

// Active Shopping List Items (OUT_OF_STOCK & LOW)
final shoppingListItemsProvider = Provider<List<GroceryItem>>((ref) {
  final inventoryAsync = ref.watch(inventoryStreamProvider);

  return inventoryAsync.when(
    data: (items) {
      return items.where((item) {
        return item.status == ItemStatus.OUT_OF_STOCK ||
            item.status == ItemStatus.LOW;
      }).toList()
        ..sort((a, b) {
          // Out of stock first, then low stock
          if (a.status == ItemStatus.OUT_OF_STOCK &&
              b.status != ItemStatus.OUT_OF_STOCK) {
            return -1;
          }
          if (a.status != ItemStatus.OUT_OF_STOCK &&
              b.status == ItemStatus.OUT_OF_STOCK) {
            return 1;
          }
          return a.name.compareTo(b.name);
        });
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Grouped Shopping List by Category
final groupedShoppingListProvider = Provider<Map<String, List<GroceryItem>>>((ref) {
  final items = ref.watch(shoppingListItemsProvider);
  final Map<String, List<GroceryItem>> grouped = {};

  for (final item in items) {
    grouped.putIfAbsent(item.category, () => []).add(item);
  }

  return grouped;
});

// Predicted Restock Suggestions Provider
final restockSuggestionsProvider = Provider<List<GroceryItem>>((ref) {
  final inventoryAsync = ref.watch(inventoryStreamProvider);

  return inventoryAsync.when(
    data: (items) {
      return items.where((item) {
        // Items currently marked IN_STOCK but predicted to deplete within 2 days
        if (item.status != ItemStatus.IN_STOCK) return false;
        if (item.predictedOutDate == null) return false;
        return PredictionService.isRestockSuggested(item.predictedOutDate);
      }).toList()
        ..sort((a, b) {
          final dateA = a.predictedOutDate ?? DateTime.now();
          final dateB = b.predictedOutDate ?? DateTime.now();
          return dateA.compareTo(dateB);
        });
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
