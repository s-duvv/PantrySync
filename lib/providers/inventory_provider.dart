import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/supabase_config.dart';
import '../models/grocery_item.dart';
import '../models/household.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

// Services Providers
final databaseServiceProvider = Provider((ref) => DatabaseService());
final authServiceProvider = Provider((ref) => AuthService());

// Current Household ID Provider
final currentHouseholdIdProvider = StateProvider<String?>((ref) => 'demo-household');

// User Profile Provider
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  if (!SupabaseConfig.isConfigured) {
    return UserProfile(
      id: 'demo-user-id',
      householdId: 'demo-household',
      displayName: 'Mom & Dad (Demo)',
      role: 'admin',
      updatedAt: DateTime.now(),
    );
  }
  final authService = ref.watch(authServiceProvider);
  final profile = await authService.fetchProfile();
  if (profile?.householdId != null) {
    ref.read(currentHouseholdIdProvider.notifier).state = profile!.householdId;
  }
  return profile;
});

// Category Filter Provider ('All' or specific category name)
final selectedCategoryFilterProvider = StateProvider<String>((ref) => 'All');

// Search Query Provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// Realtime Inventory Stream Provider
final inventoryStreamProvider = StreamProvider<List<GroceryItem>>((ref) {
  final householdId = ref.watch(currentHouseholdIdProvider) ?? 'demo-household';
  final dbService = ref.watch(databaseServiceProvider);
  return dbService.streamGroceryItems(householdId);
});

// Filtered Inventory Provider
final filteredInventoryProvider = Provider<List<GroceryItem>>((ref) {
  final inventoryAsync = ref.watch(inventoryStreamProvider);
  final selectedCategory = ref.watch(selectedCategoryFilterProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();

  return inventoryAsync.when(
    data: (items) {
      return items.where((item) {
        final matchesCategory = selectedCategory == 'All' ||
            item.category.toLowerCase() == selectedCategory.toLowerCase();

        final matchesSearch = searchQuery.isEmpty ||
            item.name.toLowerCase().contains(searchQuery) ||
            item.category.toLowerCase().contains(searchQuery);

        return matchesCategory && matchesSearch;
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Inventory Summary Statistics Provider
class InventoryStats {
  final int totalCount;
  final int inStockCount;
  final int lowCount;
  final int outOfStockCount;

  InventoryStats({
    required this.totalCount,
    required this.inStockCount,
    required this.lowCount,
    required this.outOfStockCount,
  });
}

final inventoryStatsProvider = Provider<InventoryStats>((ref) {
  final inventoryAsync = ref.watch(inventoryStreamProvider);

  return inventoryAsync.when(
    data: (items) {
      final inStock = items.where((i) => i.status == ItemStatus.IN_STOCK).length;
      final low = items.where((i) => i.status == ItemStatus.LOW).length;
      final outOfStock = items.where((i) => i.status == ItemStatus.OUT_OF_STOCK).length;

      return InventoryStats(
        totalCount: items.length,
        inStockCount: inStock,
        lowCount: low,
        outOfStockCount: outOfStock,
      );
    },
    loading: () => InventoryStats(
        totalCount: 0, inStockCount: 0, lowCount: 0, outOfStockCount: 0),
    error: (_, __) => InventoryStats(
        totalCount: 0, inStockCount: 0, lowCount: 0, outOfStockCount: 0),
  );
});
