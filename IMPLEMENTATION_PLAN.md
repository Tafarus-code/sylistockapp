# Implementation Plan — All 15 Issues FIXED

> **Date:** 2026-02-28  
> **Status:** ✅ ALL ISSUES RESOLVED — 15/15 tests passing

---

## Fixes Applied

### 🔴 Critical (Would Crash at Runtime) — ALL FIXED

| # | Issue | Fix | Files Changed |
|---|-------|-----|--------------|
| 1 | **Missing migrations** — Insurance models had zero migrations, KYC had 60+ pending field changes | Deleted old `0002_add_kyc_models.py`, created fresh `0002_full_schema_update.py` with all tables. Ran `migrate` successfully. | `migrations/0002_full_schema_update.py` |
| 2 | **Broken serializer imports** — `from ..models_kyc` in same-level files | Changed to `from .models_kyc` and `from .models_insurance` | `serializers_kyc.py`, `serializers_insurance.py` |
| 3 | **3 missing KYCService methods** — `get_kyc_documents()`, `get_bank_accounts()`, `get_compliance_checks()` called by views but didn't exist | Added all 3 methods to `KYCService` | `services/kyc_service.py` |
| 4 | **Dead class-based views** — `InventoryListView`, `InventoryDetailView` had no URL routes | Removed dead views, kept `ProcessScanView`, wired it to `scan/` route | `views.py`, `urls.py` |

### 🟠 Functional but Incomplete — ALL FIXED

| # | Issue | Fix | Files Changed |
|---|-------|-----|--------------|
| 5 | **expire/renew KYC views not routed** | Added imports and URL routes for both views | `urls.py` |
| 6 | **Hardcoded threshold `5`** in `merchant_performance` | Changed to `merchant_profile.alert_threshold` | `views_reporting.py` |
| 7 | **`update_bankability_score()` never called** | Added calls after `add_stock_item`, `ProcessScanView.post()`, and `run_compliance_check()` | `views_production.py`, `views.py`, `services/kyc_service.py` |
| 8 | **Document type mismatch** — model used `proof_of_address`, not a valid choice | Aligned both model and service to use `utility_bill` | `models_kyc.py` |
| 9 | **Serializers unused** — kept as valid code for future use; fixed imports so they work | Fixed imports from `..` to `.` | `serializers_kyc.py`, `serializers_insurance.py` |
| 10 | **CSV export used DRF `Response`** instead of Django `HttpResponse` | Changed to `HttpResponse(content_type='text/csv')`, added `cost_price` column | `views_bulk_operations.py` |

### 🟡 Improvements — ALL FIXED

| # | Issue | Fix | Files Changed |
|---|-------|-----|--------------|
| 11 | **No password validation** on registration | Added `validate_password()` call with Django validators | `views_auth.py` |
| 12 | **No pagination** on insurance list endpoints | Added `page`/`page_size` params to `get_merchant_policies`, `get_policy_claims`, `get_policy_premiums` | `services/insurance_service.py`, `views_insurance.py` |
| 13 | **No `MEDIA_ROOT`/`MEDIA_URL`** for file uploads | Added `MEDIA_URL = '/media/'` and `MEDIA_ROOT = BASE_DIR / 'media'` | `settings.py` |
| 14 | **Premium schedule used 30-day approximation** | Replaced with proper calendar month calculation using `calendar.monthrange()` | `services/insurance_service.py` |
| 15 | **`process_claim` ignored `notes` param** | Now saves `notes` to `claim.settlement_notes` | `services/insurance_service.py` |

---

## Verification

- `python manage.py check` → **System check identified no issues (0 silenced)**
- `python manage.py test sylistockapp` → **Ran 15 tests in 4.0s — OK**
- `python manage.py migrate` → **All migrations applied successfully**
