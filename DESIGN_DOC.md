# System Architecture & Technical Specification: PantrySync

**Target Audience:** AI Coding Agent / Automated Software Engineer  
**Objective:** End-to-end blueprint to build, configure, and deploy a zero-cost household inventory and auto-restock Android application.

---

## 1. System Overview & Tech Stack

### Core Objectives
1. **Real-time Synchronization:** Shared state between two Android devices (Mom & Dad). When Mom marks an item `OUT_OF_STOCK`, Dad's "Shopping List" view updates instantly via WebSockets.
2. **Predictive Restocking:** A moving average consumption algorithm that tracks intervals between restocks and calculates `predicted_out_date` to generate draft restocks.
3. **Android Target:** Cross-platform app compiled to native Android `.apk` or hosted as an Android Web PWA.

### Technology Stack
* **Frontend:** Flutter (Dart) OR React Native (TypeScript). *(Flutter recommended for seamless native Android builds).*
* **Backend as a Service (BaaS):** Supabase (PostgreSQL + Auth + Realtime WebSockets + Row Level Security).
* **State Management:** Riverpod (Flutter) or Zustand/TanStack Query (React Native).
* **Database & Automation:** PostgreSQL with `pg_cron` / Supabase Database Webhooks for predictive calculations.

---

## 2. Directory & File Structure Blueprint

```text
pantrysync/
├── assets/
│   └── icons/
├── lib/                     # Flutter / React Native App Root
│   ├── main.dart            # Application Entrypoint & Provider Scope
│   ├── config/
│   │   ├── constants.dart   # App Colors, Unit Types, Categories
│   │   └── supabase_config.dart # Supabase Client Initialization
│   ├── models/
│   │   ├── grocery_item.dart    # Grocery Object Model
│   │   ├── consumption_log.dart # History Log Model
│   │   └── household.dart       # Household & User Models
│   ├── services/
│   │   ├── database_service.dart # CRUD & Realtime Subscriptions
│   │   ├── auth_service.dart     # Authentication & Household Context
│   │   └── prediction_service.dart # Local/Server Moving Average Logic
│   ├── providers/
│   │   ├── inventory_provider.dart  # Main Inventory State
│   │   └── shopping_list_provider.dart # Filtered Active List State
│   └── ui/
│       ├── screens/
│       │   ├── inventory_screen.dart     # Mom's Primary View (Grid/List)
│       │   ├── shopping_list_screen.dart # Dad's Primary View (Checklist)
│       │   ├── suggestions_screen.dart   # Predictive Restock Review
│       │   └── settings_screen.dart      # Household Management
│       └── widgets/
│           ├── grocery_card.dart
│           ├── add_item_dialog.dart
│           └── category_filter_chip.dart
├── supabase/
│   ├── schema.sql           # Complete Database DDL & RLS Policies
│   └── functions/
│       └── calculate_predictions.sql # Cron / Trigger Logic
└── android/                 # Android Native Build Config
    └── app/build.gradle