import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/constants.dart';
import '../../models/grocery_item.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/shopping_list_provider.dart';

class ShoppingListScreen extends ConsumerWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shoppingItems = ref.watch(shoppingListItemsProvider);
    final groupedItems = ref.watch(groupedShoppingListProvider);
    final dbService = ref.watch(databaseServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.shopping_cart, color: AppColors.lowStock),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Dad\'s Shopping List (${shoppingItems.length})',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (shoppingItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: TextButton.icon(
                onPressed: () async {
                  final ids = shoppingItems.map((e) => e.id).toList();
                  await dbService.batchRestockItems(ids);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All items marked as Restocked!'),
                        backgroundColor: AppColors.inStock,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.done_all, color: AppColors.inStock, size: 18),
                label: const Text(
                  'Restock All',
                  style: TextStyle(
                    color: AppColors.inStock,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: shoppingItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.inStock.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      size: 72,
                      color: AppColors.inStock,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pantry is Fully Stocked!',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No items marked OUT_OF_STOCK or LOW.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: groupedItems.entries.map((entry) {
                final category = entry.key;
                final items = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Header
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppColors.primaryAccent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            category.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.primaryAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${items.length})',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Items Checklist Card Group
                    ...items.map((item) {
                      final isOut = item.status == ItemStatus.OUT_OF_STOCK;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isOut
                                ? AppColors.outOfStock.withOpacity(0.3)
                                : AppColors.lowStock.withOpacity(0.3),
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: CheckboxListTile(
                          value: false, // Checkbox triggers instant restock
                          activeColor: AppColors.inStock,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onChanged: (bool? value) async {
                            if (value == true) {
                              await dbService.updateItemStatus(
                                  item.id, ItemStatus.IN_STOCK);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${item.name} restocked!'),
                                    backgroundColor: AppColors.inStock,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            }
                          },
                          title: Text(
                            item.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            'Need ${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 1)} ${item.unit}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          secondary: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: (isOut ? AppColors.outOfStock : AppColors.lowStock)
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isOut ? 'OUT' : 'LOW',
                              style: TextStyle(
                                color: isOut
                                    ? AppColors.outOfStock
                                    : AppColors.lowStock,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                    const SizedBox(height: 12),
                  ],
                );
              }).toList(),
            ),
    );
  }
}
