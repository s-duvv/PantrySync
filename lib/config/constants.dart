import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette
  static const Color background = Color(0xFF0F172A); // Slate 900
  static const Color surface = Color(0xFF1E293B);    // Slate 800
  static const Color surfaceLight = Color(0xFF334155); // Slate 700
  static const Color cardBackground = Color(0x991E293B); // Glassmorphism backdrop

  static const Color primary = Color(0xFF6366F1);     // Indigo 500
  static const Color primaryAccent = Color(0xFF818CF8); // Indigo 400
  static const Color accentTeal = Color(0xFF14B8A6);  // Teal 500

  // Status Colors
  static const Color inStock = Color(0xFF10B981);     // Emerald 500
  static const Color lowStock = Color(0xFFF59E0B);    // Amber 500
  static const Color outOfStock = Color(0xFFEF4444);  // Red 500

  // Text Colors
  static const Color textPrimary = Color(0xFFF8FAFC);   // Slate 50
  static const Color textSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color textMuted = Color(0xFF64748B);     // Slate 500

  // Borders & Glass
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color border = Color(0xFF334155);
}

class AppConstants {
  static const String appName = 'PantrySync';
  
  static const List<String> categories = [
    'General',
    'Produce',
    'Dairy',
    'Pantry & Bakery',
    'Beverages',
    'Snacks',
    'Household & Cleaning',
    'Personal Care',
  ];

  static const List<String> units = [
    'pcs',
    'kg',
    'g',
    'lbs',
    'liters',
    'ml',
    'boxes',
    'packs',
    'bottles',
    'cans',
  ];
}

enum ItemCategory {
  general,
  produce,
  dairy,
  pantryAndBakery,
  beverages,
  snacks,
  household,
  personalCare;

  String get displayName {
    switch (this) {
      case ItemCategory.general:
        return 'General';
      case ItemCategory.produce:
        return 'Produce';
      case ItemCategory.dairy:
        return 'Dairy';
      case ItemCategory.pantryAndBakery:
        return 'Pantry & Bakery';
      case ItemCategory.beverages:
        return 'Beverages';
      case ItemCategory.snacks:
        return 'Snacks';
      case ItemCategory.household:
        return 'Household & Cleaning';
      case ItemCategory.personalCare:
        return 'Personal Care';
    }
  }

  IconData get icon {
    switch (this) {
      case ItemCategory.general:
        return Icons.inventory_2_outlined;
      case ItemCategory.produce:
        return Icons.eco_outlined;
      case ItemCategory.dairy:
        return Icons.breakfast_dining_outlined;
      case ItemCategory.pantryAndBakery:
        return Icons.bakery_dining_outlined;
      case ItemCategory.beverages:
        return Icons.local_cafe_outlined;
      case ItemCategory.snacks:
        return Icons.cookie_outlined;
      case ItemCategory.household:
        return Icons.cleaning_services_outlined;
      case ItemCategory.personalCare:
        return Icons.sanitizer_outlined;
    }
  }
}
