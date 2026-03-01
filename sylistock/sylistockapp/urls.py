from django.urls import path
from .views import ProcessScanView
from .views_production import (
    add_stock_item,
    remove_stock_item,
    update_stock_item,
    get_stock_items,
    inventory_history,
)
from .views_alerts import (
    low_stock_alerts,
    set_stock_alert_threshold,
)
from .views_reporting import (
    sales_report,
    merchant_performance,
)
from .views_stock_management import (
    search_items,
    get_item_details,
    bulk_update_prices,
)
from .views_bulk_operations import (
    bulk_import_inventory,
    export_inventory,
    bulk_update_inventory,
)
from .views_kyc import (
    initiate_kyc,
    upload_kyc_document,
    add_bank_account,
    perform_compliance_checks,
    evaluate_kyc_application,
    get_kyc_status,
    get_kyc_documents,
    get_bank_accounts,
    get_compliance_checks,
    expire_kyc_verification,
    renew_kyc_verification,
)
from .views_insurance import (
    calculate_premium,
    assess_risk,
    create_insurance_policy,
    submit_claim,
    process_claim,
    get_policy_details,
    get_merchant_policies,
    get_policy_claims,
    get_policy_premiums,
    get_merchant_risk_assessment,
)

urlpatterns = [
    # Barcode scan processing
    path('scan/', ProcessScanView.as_view(), name='process-scan'),

    # Stock management
    path('items/', get_stock_items, name='stock-items'),
    path('items/add/', add_stock_item, name='add-stock-item'),
    path('items/update/<int:item_id>/', update_stock_item,
         name='update-stock-item'),
    path('items/remove/<int:item_id>/', remove_stock_item,
         name='remove-stock-item'),
    path('items/search/', search_items, name='search-items'),
    path('items/history/', inventory_history, name='inventory-history'),
    path('items/bulk-update-prices/', bulk_update_prices,
         name='bulk-update-prices'),
    path('items/<int:item_id>/', get_item_details, name='item-details'),

    # Alerts
    path('alerts/low-stock/', low_stock_alerts, name='low-stock-alerts'),
    path('alerts/threshold/', set_stock_alert_threshold,
         name='set-alert-threshold'),

    # Reports
    path('reports/sales/', sales_report, name='sales-report'),
    path('reports/performance/', merchant_performance,
         name='performance-report'),

    # Bulk operations
    path('bulk/import/', bulk_import_inventory, name='bulk-import'),
    path('bulk/export/', export_inventory, name='bulk-export'),
    path('bulk/update/', bulk_update_inventory, name='bulk-update'),

    # KYC (Know Your Customer)
    path('kyc/initiate/', initiate_kyc, name='kyc-initiate'),
    path('kyc/upload-document/', upload_kyc_document,
         name='kyc-upload-document'),
    path('kyc/add-bank-account/', add_bank_account,
         name='kyc-add-bank-account'),
    path('kyc/compliance-checks/', perform_compliance_checks,
         name='kyc-compliance-checks'),
    path('kyc/evaluate/', evaluate_kyc_application,
         name='kyc-evaluate'),
    path('kyc/status/<uuid:kyc_id>/', get_kyc_status,
         name='kyc-status'),
    path('kyc/documents/<uuid:kyc_id>/', get_kyc_documents,
         name='kyc-documents'),
    path('kyc/bank-accounts/<uuid:kyc_id>/', get_bank_accounts,
         name='kyc-bank-accounts'),
    path('kyc/compliance/<uuid:kyc_id>/', get_compliance_checks,
         name='kyc-compliance'),
    path('kyc/expire/', expire_kyc_verification,
         name='kyc-expire'),
    path('kyc/renew/', renew_kyc_verification,
         name='kyc-renew'),

    # Insurance
    path('insurance/calculate-premium/', calculate_premium,
         name='insurance-calculate-premium'),
    path('insurance/assess-risk/', assess_risk,
         name='insurance-assess-risk'),
    path('insurance/create-policy/', create_insurance_policy,
         name='insurance-create-policy'),
    path('insurance/submit-claim/', submit_claim,
         name='insurance-submit-claim'),
    path('insurance/process-claim/', process_claim,
         name='insurance-process-claim'),
    path('insurance/policy/<uuid:policy_id>/',
         get_policy_details, name='insurance-policy-details'),
    path('insurance/merchant/<int:merchant_id>/policies/',
         get_merchant_policies, name='insurance-merchant-policies'),
    path('insurance/policy/<uuid:policy_id>/claims/',
         get_policy_claims, name='insurance-policy-claims'),
    path('insurance/policy/<uuid:policy_id>/premiums/',
         get_policy_premiums, name='insurance-policy-premiums'),
    path('insurance/merchant/<int:merchant_id>/risk/',
         get_merchant_risk_assessment,
         name='insurance-risk-assessment'),
]
