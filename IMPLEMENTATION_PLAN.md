# Implementation Plan — Fix All 30 Issues

> **Date:** 2026-02-28  
> **Scope:** Fix every incomplete feature, field mismatch, missing route, stub, and bug identified in the audit.

---

## Phase 1 — Model Layer Fixes

All model changes are grouped first so we can generate a single migration at the end.

### 1.1 `sylistockapp/models.py` — Add missing fields

| Change | Detail |
|--------|--------|
| `MerchantProfile.business_age` | Add `PositiveIntegerField(default=0)` — referenced by `kyc_service.py` |
| `MerchantProfile.alert_threshold` | Add `PositiveIntegerField(default=5)` — used by `set_stock_alert_threshold` |
| `MerchantProfile.created_at` | Add `DateTimeField(auto_now_add=True)` — referenced by `insurance_service.py` |
| `MerchantProfile.updated_at` | Add `DateTimeField(auto_now=True)` |
| `MerchantProfile.__str__` | Add missing `__str__` method |
| `StockItem.cost_price` | Change to `default=0` so it is not required on creation |
| `StockItem.sale_price` | Change to `default=0` so it is not required on creation |
| `StockItem.created_at` | Add `DateTimeField(auto_now_add=True)` — views currently return `item.pk` as placeholder |
| `StockItem.updated_at` | Add `DateTimeField(auto_now=True)` — views currently return `item.pk` as placeholder |

**Status: DONE**

### 1.2 `sylistockapp/models_insurance.py` — Add `paid_date`

| Change | Detail |
|--------|--------|
| `InsurancePremium.paid_date` | Add `DateTimeField(null=True, blank=True)` — referenced by serializer and service |

**Status: DONE**

### 1.3 `sylistockapp/models_kyc.py` — Change `ImageField` to `FileField`

| Change | Detail |
|--------|--------|
| `KYCDocument.file` | Change from `ImageField` to `FileField` so PDFs can be uploaded |

**Status: DONE**

### 1.4 Generate and apply migrations

Run:
```
python manage.py makemigrations sylistockapp
python manage.py migrate
```

**Status: TODO**

---

## Phase 2 — Service Layer Fixes

### 2.1 `sylistockapp/services/kyc_service.py` — Fix all field name mismatches

| Location | Bug | Fix |
|----------|-----|-----|
| `upload_document()` | `status='uploaded'` — no `status` field on KYCDocument | Use `verification_status='pending'` |
| `_validate_document()` | `document.validation_score` | Use `document.verification_score` |
| `_validate_document()` | `document.issues` — field does not exist | Use `document.verification_notes = '; '.join(issues)` |
| `_validate_document()` | `document.status = 'validated'` | Use `document.verification_status = 'verified'` |
| `_check_image_quality()` | Always returns `30` (stub) | Implement file-size heuristic |
| `verify_bank_account()` | `status='pending'` on BankAccount.objects.create | Use `verification_status='pending'` |
| `_verify_bank_details()` | `bank_account.issues` — field does not exist | Use `bank_account.verification_notes` |
| `_verify_bank_details()` | `bank_account.status` | Use `bank_account.verification_status` |
| `run_compliance_check()` | `ComplianceCheck.objects.create(status='in_progress')` — no `status` field | Pass `check_type`, `result`, `score`, `max_score`, `details` |
| `run_compliance_check()` | `compliance_check.overall_score` / `.check_results` / `.status` | Remove — use `create()` call directly |
| `_check_document_completeness()` | `doc.status == 'validated'` | Use `doc.verification_status == 'verified'` |
| `_check_bank_verification()` | `account.issues` / `account.status` | Use `account.verification_notes` / `account.verification_status` |
| `get_kyc_status()` | `kyc_verification.created_at` / `.updated_at` | Use `submitted_at` / `reviewed_at` |

**Status: DONE**

### 2.2 `sylistockapp/services/insurance_service.py` — Activate policy

| Change | Detail |
|--------|--------|
| `create_policy()` | After creation, set `policy.status = 'active'` and save |

**Status: DONE**

---

## Phase 3 — Serializer Fixes

### 3.1 `sylistockapp/serializers_kyc.py`

| Location | Bug | Fix |
|----------|-----|-----|
| `KYCVerificationSerializer.fields` | `'review_notes'` — field does not exist on model | Remove from fields list |
| `ComplianceCheckSerializer.validate_score` | `self.max_score` crashes with AttributeError | Use `self.initial_data.get('max_score', 100)` |
| `UpdateKYCStatusSerializer.validate_status` | `self.overall_score` crashes with AttributeError | Use `self.initial_data.get('overall_score', 0)` |

**Status: DONE**

### 3.2 `sylistockapp/serializers_insurance.py`

| Change | Detail |
|--------|--------|
| `InsurancePremiumSerializer.fields` includes `'paid_date'` | Resolved by model change in Phase 1.2 |

**Status: DONE**

---

## Phase 4 — View Layer Fixes

### 4.1 `sylistockapp/views.py` — Replace hardcoded mock data

| Method | Fix |
|--------|-----|
| `InventoryListView.get()` | Query `StockItem.objects.filter(merchant=...)` |
| `InventoryListView.post()` | Create `Product` + `StockItem` in DB |
| `InventoryDetailView.get_object()` | Query `StockItem.objects.get(pk=pk, merchant=...)` |
| `InventoryDetailView.patch()` | Update actual `StockItem` and save |
| `InventoryDetailView.delete()` | Actually delete the `StockItem` |

**Status: DONE**

### 4.2 `sylistockapp/views_alerts.py` — Persist threshold, fix timestamps

| Change | Detail |
|--------|--------|
| `low_stock_alerts()` | `'last_updated': item.pk` to `item.updated_at` |
| `low_stock_alerts()` | Use `merchant_profile.alert_threshold` as default threshold |
| `set_stock_alert_threshold()` | Save to `merchant_profile.alert_threshold` and call `.save()` |

**Status: DONE**

### 4.3 `sylistockapp/views_stock_management.py` — Fix placeholder timestamps

| Change | Detail |
|--------|--------|
| `search_items()` | `'last_updated': item.pk` to `item.updated_at` |
| `get_item_details()` | `'created_at': item.pk` to `item.created_at`, same for `updated_at` |

**Status: DONE**

### 4.4 `sylistockapp/views_production.py` — Multiple fixes

| Change | Detail |
|--------|--------|
| `add_stock_item()` | Add `cost_price` from `request.data` — **DONE** |
| `add_stock_item()` | Add `source=` to `InventoryLog.objects.create()` — **DONE** |
| `remove_stock_item()` | Add `source=` to `InventoryLog.objects.create()` — **DONE** |
| `update_stock_item()` | Change `action='ADJUST'` to `'ADJ'` (match ACTION_TYPES choices) — **TODO** |
| `update_stock_item()` | Add `source=` to `InventoryLog.objects.create()` — **TODO** |
| `get_stock_items()` | `'last_updated': item.pk` to `item.updated_at` — **TODO** |
| `inventory_history()` | Add `@api_view` and `@permission_classes` decorators — **TODO** |

### 4.5 `sylistockapp/views_bulk_operations.py` — Add decorators, add cost_price

| Change | Detail |
|--------|--------|
| `export_inventory()` | Add `@api_view(['GET'])` and `@permission_classes([IsAuthenticated])` decorators |
| `bulk_import_inventory()` | Read `cost_price` from CSV row and pass to `StockItem` |

**Status: TODO**

### 4.6 `sylistockapp/views_reporting.py` — Add revenue calculation

| Change | Detail |
|--------|--------|
| `sales_report()` | Look up `StockItem.sale_price` for each product, multiply by quantity, add `total_revenue` to response |

**Status: TODO**

### 4.7 `sylistockapp/views_kyc.py` — Differentiate `evaluate_kyc_application`

| Change | Detail |
|--------|--------|
| `evaluate_kyc_application()` | Currently duplicates `perform_compliance_checks()`. Change to return a summary/decision view (call `get_kyc_status` + include completion percentage). |

**Status: TODO**

---

## Phase 5 — URL Routing Fixes

### 5.1 `sylistockapp/urls.py`

| Route | Bug | Fix |
|-------|-----|-----|
| `kyc/status/` | Missing path parameter | `kyc/status/<uuid:kyc_id>/` |
| `kyc/documents/` | Missing path parameter | `kyc/documents/<uuid:kyc_id>/` |
| `kyc/bank-accounts/` | Missing path parameter | `kyc/bank-accounts/<uuid:kyc_id>/` |
| `kyc/compliance/` | Missing path parameter | `kyc/compliance/<uuid:kyc_id>/` |
| `insurance/policy-details/` | Missing path parameter | `insurance/policy/<uuid:policy_id>/` |
| `insurance/merchant-policies/` | Missing path parameter | `insurance/merchant/<int:merchant_id>/policies/` |
| `insurance/policy-claims/` | Missing path parameter | `insurance/policy/<uuid:policy_id>/claims/` |
| `insurance/policy-premiums/` | Missing path parameter | `insurance/policy/<uuid:policy_id>/premiums/` |
| `insurance/risk-assessment/` | Missing path parameter | `insurance/merchant/<int:merchant_id>/risk/` |
| `inventory_history` | Not imported, no route | Add import + `path('items/history/', ...)` |
| `bulk_update_prices` | Not imported, no route | Add import + `path('items/bulk-update-prices/', ...)` |

**Status: TODO**

---

## Phase 6 — Admin, Tests, and Auth

### 6.1 `sylistockapp/admin.py` — Register all models

Register with basic `ModelAdmin` classes:
- `MerchantProfile` — `list_display`, `search_fields`
- `Product` — `list_display`, `search_fields`
- `StockItem` — `list_display`, `list_filter`
- `InventoryLog` — `list_display`, `list_filter`
- `KYCDocument` — `list_display`, `list_filter`
- `KYCVerification` — `list_display`, `list_filter`
- `BankAccount` — `list_display`
- `ComplianceCheck` — `list_display`
- `InsurancePolicy` — `list_display`, `list_filter`, `search_fields`
- `InsuranceClaim` — `list_display`, `list_filter`
- `InsuranceRiskAssessment` — `list_display`, `list_filter`
- `InsuranceCoverage` — `list_display`
- `InsurancePremium` — `list_display`, `list_filter`

**Status: TODO**

### 6.2 `sylistockapp/tests.py` — Write real tests

Add `APITestCase` tests for:
- Model creation (MerchantProfile, Product, StockItem)
- `add_stock_item` view (POST with auth)
- `remove_stock_item` view (POST with auth)
- `low_stock_alerts` view (GET)
- `search_items` view (GET)
- Insurance premium calculation
- KYC initiation flow

**Status: TODO**

### 6.3 Authentication endpoints

- Add `rest_framework.authtoken` to `INSTALLED_APPS` in `settings.py`
- Add token auth to `REST_FRAMEWORK` config
- Create `views_auth.py` with registration + login views
- Wire up in project `urls.py`

**Status: TODO**

### 6.4 Bankability score calculation

- Create `update_bankability_score()` helper on `MerchantProfile` or in a service
- Call it after: compliance check completion, scan processing, stock updates
- Score based on: KYC status, inventory accuracy, scan frequency, claim history

**Status: TODO**

---

## Execution Order

```
Phase 1 (Models)         -- DONE except migration
  |
Phase 2 (Services)       -- DONE
  |
Phase 3 (Serializers)    -- DONE
  |
Phase 4 (Views)          -- Partially done, 4.4-4.7 remain
  |
Phase 5 (URLs)           -- TODO
  |
Phase 6 (Admin/Tests)    -- TODO
  |
Migration                -- Run last after all model changes
```

---

## Summary

| Phase | Files Changed | Issues Fixed | Status |
|-------|--------------|-------------|--------|
| 1. Models | `models.py`, `models_insurance.py`, `models_kyc.py` | 1-4 (fields, types, migrations) | Done (migration pending) |
| 2. Services | `kyc_service.py`, `insurance_service.py` | 5-13 (field mismatches, stubs) | Done |
| 3. Serializers | `serializers_kyc.py`, `serializers_insurance.py` | 14-16 (bugs, missing fields) | Done |
| 4. Views | `views.py`, `views_alerts.py`, `views_stock_management.py`, `views_production.py`, `views_bulk_operations.py`, `views_reporting.py`, `views_kyc.py` | 17-25 (mock data, stubs, decorators, timestamps) | Partial |
| 5. URLs | `urls.py` | 26-28 (missing path params, unregistered routes) | TODO |
| 6. Admin/Tests/Auth | `admin.py`, `tests.py`, `views_auth.py`, `settings.py` | 29-30 (empty admin, dummy tests, no auth, bankability) | TODO |

