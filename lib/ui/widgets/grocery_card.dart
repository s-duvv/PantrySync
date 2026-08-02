import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/constants.dart';
import '../../models/grocery_item.dart';
import '../../services/prediction_service.dart';

class GroceryCard extends StatelessWidget {
  final GroceryItem item;
  final VoidCallback onTap;
  final Function(ItemStatus) onStatusChanged;
  final VoidCallback onDelete;

  const GroceryCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onStatusChanged,
    required this.onDelete,
  });

  Color _getStatusColor() {
    switch (item.status) {
      case ItemStatus.IN_STOCK:
        return AppColors.inStock;
      case ItemStatus.LOW:
        return AppColors.lowStock;
      case ItemStatus.OUT_OF_STOCK:
        return AppColors.outOfStock;
    }
  }

  String _getStatusLabel() {
    switch (item.status) {
      case ItemStatus.IN_STOCK:
        return 'IN STOCK';
      case ItemStatus.LOW:
        return 'LOW';
      case ItemStatus.OUT_OF_STOCK:
        return 'OUT OF STOCK';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final daysRemaining = PredictionService.getDaysRemaining(item.predictedOutDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Item Name, Category & Action Popup Menu
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getCategoryIcon(item.category),
                      color: AppColors.primaryAccent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.category} • ${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 1)} ${item.unit}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor, width: 1),
                    ),
                    child: Text(
                      _getStatusLabel(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                    color: AppColors.surface,
                    onSelected: (value) {
                      if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: AppColors.outOfStock, size: 18),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: AppColors.outOfStock)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 12),

              // Restock & Prediction Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      children: [
                        const Icon(Icons.history, color: AppColors.textMuted, size: 14),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Restocked: ${DateFormat('MMM d').format(item.lastRestockedAt)}',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (item.predictedOutDate != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: DaysRemainingBadgeColor(daysRemaining).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_graph,
                            color: DaysRemainingBadgeColor(daysRemaining),
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            daysRemaining == 0
                                ? 'Empty Today'
                                : 'Empty in ~$daysRemaining d',
                            style: TextStyle(
                              color: DaysRemainingBadgeColor(daysRemaining),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Quick Action Status Toggle Buttons
              Row(
                children: [
                  Expanded(
                    child: _StatusActionButton(
                      label: 'In Stock',
                      icon: Icons.check_circle_outline,
                      isSelected: item.status == ItemStatus.IN_STOCK,
                      activeColor: AppColors.inStock,
                      onTap: () => onStatusChanged(ItemStatus.IN_STOCK),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatusActionButton(
                      label: 'Low',
                      icon: Icons.warning_amber_outlined,
                      isSelected: item.status == ItemStatus.LOW,
                      activeColor: AppColors.lowStock,
                      onTap: () => onStatusChanged(ItemStatus.LOW),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatusActionButton(
                      label: 'Out',
                      icon: Icons.remove_shopping_cart_outlined,
                      isSelected: item.status == ItemStatus.OUT_OF_STOCK,
                      activeColor: AppColors.outOfStock,
                      onTap: () => onStatusChanged(ItemStatus.OUT_OF_STOCK),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color DaysRemainingBadgeColor(int days) {
    if (days <= 2) return AppColors.outOfStock;
    if (days <= 4) return AppColors.lowStock;
    return AppColors.accentTeal;
  }

  IconData _getCategoryIcon(String categoryName) {
    final cat = ItemCategory.values.firstWhere(
      (c) => c.displayName.toLowerCase() == categoryName.toLowerCase(),
      orElse: () => ItemCategory.general,
    );
    return cat.icon;
  }
}

class _StatusActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _StatusActionButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.2) : AppColors.surfaceLight.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? activeColor : AppColors.textMuted,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? activeColor : AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
