from django.contrib import admin
from .models import MerchantProfile, Product, StockItem, InventoryLog, Category
from .models_kyc import (
    KYCDocument, KYCVerification, BankAccount, ComplianceCheck
)
from .models_insurance import (
    InsurancePolicy, InsuranceClaim, InsuranceRiskAssessment,
    InsuranceCoverage, InsurancePremium
)


@admin.register(MerchantProfile)
class MerchantProfileAdmin(admin.ModelAdmin):
    list_display = [
        'business_name', 'user', 'location',
        'bankability_score', 'business_age', 'created_at',
    ]
    search_fields = ['business_name', 'user__username', 'location']
    list_filter = ['location']


@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = ['name', 'barcode']
    search_fields = ['name', 'barcode']


@admin.register(StockItem)
class StockItemAdmin(admin.ModelAdmin):
    list_display = [
        'product', 'merchant', 'quantity',
        'cost_price', 'sale_price', 'updated_at',
    ]
    list_filter = ['merchant']
    search_fields = [
        'product__name', 'product__barcode',
        'merchant__business_name',
    ]


@admin.register(InventoryLog)
class InventoryLogAdmin(admin.ModelAdmin):
    list_display = [
        'product', 'merchant', 'action',
        'quantity_changed', 'source', 'device_id', 'timestamp',
    ]
    list_filter = ['action', 'source', 'timestamp']
    search_fields = ['product__name', 'merchant__business_name']


@admin.register(KYCDocument)
class KYCDocumentAdmin(admin.ModelAdmin):
    list_display = [
        'document_type', 'verification', 'file_name',
        'verification_status', 'verification_score', 'upload_date',
    ]
    list_filter = ['document_type', 'verification_status']
    search_fields = ['file_name']


@admin.register(KYCVerification)
class KYCVerificationAdmin(admin.ModelAdmin):
    list_display = [
        'merchant', 'verification_level', 'status',
        'overall_score', 'submitted_at', 'reviewed_at',
    ]
    list_filter = ['verification_level', 'status']
    search_fields = ['merchant__business_name']


@admin.register(BankAccount)
class BankAccountAdmin(admin.ModelAdmin):
    list_display = [
        'bank_name', 'account_name', 'account_type',
        'verification_status', 'verification_score', 'created_at',
    ]
    list_filter = ['verification_status', 'account_type']
    search_fields = ['bank_name', 'account_name']


@admin.register(ComplianceCheck)
class ComplianceCheckAdmin(admin.ModelAdmin):
    list_display = [
        'verification', 'check_type', 'result',
        'score', 'max_score', 'checked_at',
    ]
    list_filter = ['check_type', 'result']


@admin.register(InsurancePolicy)
class InsurancePolicyAdmin(admin.ModelAdmin):
    list_display = [
        'policy_number', 'merchant', 'policy_type', 'status',
        'total_coverage_amount', 'premium_amount',
        'start_date', 'end_date',
    ]
    list_filter = ['policy_type', 'status']
    search_fields = [
        'policy_number', 'merchant__business_name',
    ]


@admin.register(InsuranceClaim)
class InsuranceClaimAdmin(admin.ModelAdmin):
    list_display = [
        'claim_number', 'policy', 'claim_type', 'status',
        'estimated_loss', 'approved_amount', 'submitted_at',
    ]
    list_filter = ['claim_type', 'status']
    search_fields = ['claim_number']


@admin.register(InsuranceRiskAssessment)
class InsuranceRiskAssessmentAdmin(admin.ModelAdmin):
    list_display = [
        'merchant', 'risk_level', 'risk_score',
        'inventory_value', 'assessment_date',
    ]
    list_filter = ['risk_level']
    search_fields = ['merchant__business_name']


@admin.register(InsuranceCoverage)
class InsuranceCoverageAdmin(admin.ModelAdmin):
    list_display = [
        'policy_type', 'coverage_type', 'is_included',
        'coverage_limit', 'deductible_percentage',
    ]
    list_filter = ['policy_type', 'coverage_type', 'is_included']


@admin.register(InsurancePremium)
class InsurancePremiumAdmin(admin.ModelAdmin):
    list_display = [
        'premium_number', 'policy', 'amount',
        'due_date', 'payment_status', 'paid_amount',
    ]
    list_filter = ['payment_status']
    search_fields = ['premium_number']


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ['name', 'merchant', 'icon', 'is_active', 'created_at']
    list_filter = ['is_active', 'merchant']
    search_fields = ['name', 'description']
