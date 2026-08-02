import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/constants.dart';
import '../../models/grocery_item.dart';
import '../../providers/inventory_provider.dart';
import '../widgets/add_item_dialog.dart';
import '../widgets/category_filter_chip.dart';
import '../widgets/grocery_card.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddItemDialog(BuildContext context, {GroceryItem? existingItem}) async {
    final householdId = ref.read(currentHouseholdIdProvider) ?? 'demo-household';

    final result = await showDialog<GroceryItem>(
      context: context,
      builder: (context) => AddItemDialog(
        householdId: householdId,
        existingItem: existingItem,
      ),
    );

    if (result != null) {
      final dbService = ref.read(databaseServiceProvider);
      if (existingItem != null) {
        await dbService.updateItem(result);
      } else {
        await dbService.addItem(result);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = ref.watch(filteredInventoryProvider);
    final stats = ref.watch(inventoryStatsProvider);
    final selectedCategory = ref.watch(selectedCategoryFilterProvider);
    final inventoryAsync = ref.watch(inventoryStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.inventory_2, color: AppColors.primaryAccent),
            SizedBox(width: 8),
            Text(
              'Mom\'s Pantry',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accentTeal.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accentTeal),
            ),
            child: const Row(
              children: [
                Icon(Icons.sensors, color: AppColors.accentTeal, size: 14),
                SizedBox(width: 4),
                Text(
                  'LIVE SYNC',
                  style: TextStyle(
                    color: AppColors.accentTeal,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _StatBadge(
                      label: 'In Stock',
                      count: stats.inStockCount,
                      color: AppColors.inStock,
                      icon: Icons.check_circle,
                    ),
                  ),
                  Container(height: 30, width: 1, color: AppColors.border),
                  Expanded(
                    child: _StatBadge(
                      label: 'Low',
                      count: stats.lowCount,
                      color: AppColors.lowStock,
                      icon: Icons.warning_amber,
                    ),
                  ),
                  Container(height: 30, width: 1, color: AppColors.border),
                  Expanded(
                    child: _StatBadge(
                      label: 'Out of Stock',
                      count: stats.outOfStockCount,
                      color: AppColors.outOfStock,
                      icon: Icons.remove_shopping_cart,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (query) {
                ref.read(searchQueryProvider.notifier).state = query;
              },
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search items or categories...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),

          // Category Chips Bar
          CategoryFilterBar(
            selectedCategory: selectedCategory,
            onCategorySelected: (cat) {
              ref.read(selectedCategoryFilterProvider.notifier).state = cat;
            },
          ),
          const SizedBox(height: 12),

          // Grocery Items List
          Expanded(
            child: inventoryAsync.when(
              data: (_) {
                if (filteredItems.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 64,
                          color: AppColors.textMuted,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No inventory items found',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tap + below to add your first item',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return GroceryCard(
                      item: item,
                      onTap: () => _openAddItemDialog(context, existingItem: item),
                      onStatusChanged: (newStatus) async {
                        final dbService = ref.read(databaseServiceProvider);
                        await dbService.updateItemStatus(item.id, newStatus);
                      },
                      onDelete: () async {
                        final dbService = ref.read(databaseServiceProvider);
                        await dbService.deleteItem(item.id);
                      },
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, stack) => Center(
                child: Text(
                  'Error loading inventory: $err',
                  style: const TextStyle(color: AppColors.outOfStock),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddItemDialog(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Item',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _StatBadge({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
