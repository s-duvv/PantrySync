import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../config/constants.dart';
import '../../models/grocery_item.dart';

class AddItemDialog extends StatefulWidget {
  final String householdId;
  final GroceryItem? existingItem;

  const AddItemDialog({
    super.key,
    required this.householdId,
    this.existingItem,
  });

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late String _selectedCategory;
  late String _selectedUnit;
  late ItemStatus _selectedStatus;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingItem?.name ?? '');
    _quantityController = TextEditingController(
      text: (widget.existingItem?.quantity ?? 1.0).toStringAsFixed(1),
    );
    _selectedCategory = widget.existingItem?.category ?? AppConstants.categories.first;
    _selectedUnit = widget.existingItem?.unit ?? AppConstants.units.first;
    _selectedStatus = widget.existingItem?.status ?? ItemStatus.IN_STOCK;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final quantity = double.tryParse(_quantityController.text) ?? 1.0;

    final item = GroceryItem(
      id: widget.existingItem?.id ?? const Uuid().v4(),
      householdId: widget.householdId,
      name: _nameController.text.trim(),
      category: _selectedCategory,
      status: _selectedStatus,
      unit: _selectedUnit,
      quantity: quantity,
      predictedOutDate: widget.existingItem?.predictedOutDate,
      lastRestockedAt: widget.existingItem?.lastRestockedAt ?? now,
      createdAt: widget.existingItem?.createdAt ?? now,
      updatedAt: now,
    );

    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingItem != null;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        isEditing ? 'Edit Grocery Item' : 'Add New Grocery Item',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Item Name
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Item Name',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    hintText: 'e.g. Whole Milk, Avocados',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.shopping_bag_outlined, color: AppColors.primaryAccent),
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a name' : null,
                ),
                const SizedBox(height: 16),

                // Category & Unit Row
                Row(
                  children: [
                    // Category Dropdown
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _selectedCategory,
                        dropdownColor: AppColors.surface,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Category',
                          labelStyle: const TextStyle(color: AppColors.textSecondary),
                          filled: true,
                          fillColor: AppColors.surfaceLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: AppConstants.categories.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Text(cat, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCategory = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Unit Dropdown
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _selectedUnit,
                        dropdownColor: AppColors.surface,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Unit',
                          labelStyle: const TextStyle(color: AppColors.textSecondary),
                          filled: true,
                          fillColor: AppColors.surfaceLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: AppConstants.units.map((u) {
                          return DropdownMenuItem(
                            value: u,
                            child: Text(u, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedUnit = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Quantity & Status Row
                Row(
                  children: [
                    // Quantity
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _quantityController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Quantity',
                          labelStyle: const TextStyle(color: AppColors.textSecondary),
                          filled: true,
                          fillColor: AppColors.surfaceLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Status Selector
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<ItemStatus>(
                        isExpanded: true,
                        value: _selectedStatus,
                        dropdownColor: AppColors.surface,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Status',
                          labelStyle: const TextStyle(color: AppColors.textSecondary),
                          filled: true,
                          fillColor: AppColors.surfaceLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: ItemStatus.IN_STOCK,
                            child: Text('In Stock', style: TextStyle(color: AppColors.inStock), overflow: TextOverflow.ellipsis),
                          ),
                          DropdownMenuItem(
                            value: ItemStatus.LOW,
                            child: Text('Low Stock', style: TextStyle(color: AppColors.lowStock), overflow: TextOverflow.ellipsis),
                          ),
                          DropdownMenuItem(
                            value: ItemStatus.OUT_OF_STOCK,
                            child: Text('Out of Stock', style: TextStyle(color: AppColors.outOfStock), overflow: TextOverflow.ellipsis),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedStatus = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Save Action Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isEditing ? 'Save Changes' : 'Add to Inventory',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
