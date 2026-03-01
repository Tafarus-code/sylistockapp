# Implementation Plan — Sylistockapp

> **Last Updated:** 2026-03-01  
> **Django Tests:** ✅ 15/15 passing  
> **Flutter Analyze:** ✅ 0 errors (286 info/warnings)

---

## ✅ COMPLETED — Working End-to-End (Flutter ↔ Django)

| # | Feature | Details |
|---|---------|---------|
| 1 | **Authentication** | Register, Login, Logout, Profile — Token auth via `views_auth.py` ↔ `auth_service.dart` ↔ `login_screen.dart` |
| 2 | **Inventory CRUD** | List, Add, Update items — `views_production.py` ↔ `enhanced_inventory_service.dart` ↔ `item_form_screen.dart`, `inventory_list_screen.dart` |
| 3 | **Inventory Search** | Search by name/barcode — `views_stock_management.py` ↔ `enhanced_inventory_service.searchItems` |
| 4 | **Item Details** | View item by ID — `get_item_details` ↔ `enhanced_inventory_service.getItemById` |
| 5 | **Category CRUD** | Create, Read, Update, Delete categories with icons/colors — `views_categories.py` ↔ `enhanced_inventory_service` ↔ `category_management_screen.dart` |
| 6 | **Category Selection** | Pick category when adding items, create new from selection screen — `category_selection_screen.dart` |
| 7 | **Barcode Scanner → Search/Add** | Camera scan → search item → add if new — `enhanced_scanner_screen.dart` |
| 8 | **Settings & Connection Test** | Configure API URL, test backend connection — `settings_screen.dart` |
| 9 | **Bankability Dashboard (partial)** | Fetches live `bankability_score` from Django profile. Local credit engine runs on Hive data. |
| 10 | **Database Migrations** | All models migrated: MerchantProfile, Product, StockItem, InventoryLog, Category, KYC models, Insurance models |
| 11 | **Hive Storage (robust)** | Singleton `EnhancedInventoryService`, safe box init, auto-cleanup of corrupted data on startup |

---

## 🔴 CRITICAL — Must Fix

| # | Task | What Exists | What's Missing | Effort |
|---|------|-------------|----------------|--------|
| 1 | **Fix Insurance navigation bug** | Drawer "Insurance" item exists | Routes to `_navigateToScreen(3)` = KYC tab, NOT Insurance. Insurance dashboard is **unreachable** from main navigation. | S |
| 2 | **Connect KYC Dashboard to Django** | Django: 10+ KYC endpoints fully implemented. Flutter: `kyc_dashboard_screen.dart` (666 lines rich UI). `ApiConfig` has all KYC URLs. | Screen uses `Future.delayed` + **hardcoded mock data**. No `kyc_service.dart` in Flutter. | L |
| 3 | **Connect Insurance Dashboard to Django** | Django: 10+ Insurance endpoints fully implemented. Flutter: `insurance_dashboard_screen.dart` (620 lines rich UI). `ApiConfig` has all Insurance URLs. | Screen uses `Future.delayed` + **hardcoded mock data**. No `insurance_service.dart` in Flutter. | L |

---

## 🟠 HIGH PRIORITY — Backend Exists, Needs Flutter Connection

| # | Task | Backend | Flutter Gap | Effort |
|---|------|---------|-------------|--------|
| 4 | **Build Reports Screen** | `views_reporting.py`: `sales_report`, `merchant_performance` fully working. `ApiService` has methods. | `reports_screen.dart` is a 25-line "Coming Soon!" placeholder. | M |
| 5 | **Build KYC Sub-Screens** | Django: `upload_kyc_document`, `add_bank_account`, `perform_compliance_checks`, `get_kyc_status`, etc. | `kyc_upload_screen.dart`, `kyc_bank_account_screen.dart`, `kyc_compliance_screen.dart` — all "Coming Soon!" placeholders. | L |
| 6 | **Build Insurance Sub-Screens** | Django: `get_policy_details`, `submit_claim`, `process_claim`, `get_policy_premiums`, etc. | `insurance_policy_screen.dart`, `insurance_claims_screen.dart`, `insurance_premiums_screen.dart` — all "Coming Soon!" placeholders. | L |
| 7 | **Build Alerts Screen** | `views_alerts.py`: `low_stock_alerts`, `set_stock_alert_threshold`. `ApiService.getLowStockAlerts()` exists. | No Flutter screen to view alerts or configure thresholds. | M |
| 8 | **Wire Delete Item to API** | `views_production.py`: `remove_stock_item` endpoint exists. | `enhanced_inventory_service.deleteItem` only deletes from local Hive, does NOT call `ApiConfig.removeItem(id)`. | S |

---

## 🟡 MEDIUM PRIORITY — Improvements

| # | Task | Details | Effort |
|---|------|---------|--------|
| 9 | **Wire Scanner to ProcessScanView** | Scanner uses search+add flow. Should call `ApiConfig.scanProcess` for proper IN/OUT actions with audit trail in `InventoryLog`. | M |
| 10 | **Fix Scanner → Item Details** | `_navigateToItemDetails` has `// TODO` and shows a snackbar instead of navigating to `ItemDetailsScreen`. | S |
| 11 | **Save Category on Product (server-side)** | `Product.category` FK exists in Django but `add_stock_item` view doesn't accept `category_id`. Flutter sends category locally but it's not persisted on the server. | S |
| 12 | **Server-side Bankability Scoring** | Django's `MerchantProfile.update_bankability_score()` works. Flutter `BankabilityEngine` calculates locally only. Should fetch server score or sync. | M |
| 13 | **Build Inventory History Screen** | Django `inventory_history` endpoint + `ApiService.getHistory()` exist. No Flutter UI to show the audit trail timeline. | M |

---

## 🟢 LOW PRIORITY — Nice to Have

| # | Task | Details | Effort |
|---|------|---------|--------|
| 14 | **Build Bulk Operations Screen** | Django CSV import/export/bulk update all work. Need Flutter UI with file picker. | M |
| 15 | **Logistics/What3Words Screen** | `What3WordsService` exists. Drawer shows "coming soon!". Need dedicated screen. | S |
| 16 | **Help & About Screens** | Drawer entries → "coming soon!" snackbar. Simple info screens. | S |
| 17 | **Offline Sync Queue** | Hive used as fallback cache. Proper offline queue for scans/operations would improve reliability. | L |

---

## Recommended Next Steps

1. **Fix the Insurance nav bug** (5 min)
2. **Create `kyc_service.dart`** and connect KYC dashboard to Django
3. **Create `insurance_service.dart`** and connect Insurance dashboard to Django
4. **Build the Reports screen** with charts using Django's sales/performance data
5. **Wire deleteItem to API**

*Effort: S = Small (<2h), M = Medium (2–6h), L = Large (6h+)*
