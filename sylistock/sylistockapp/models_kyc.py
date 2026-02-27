"""
KYC (Know Your Customer) models for bank compliance
"""
from django.db import models
from django.contrib.auth.models import User
from django.utils.translation import gettext_lazy as _
import uuid


class KYCDocument(models.Model):
    """KYC document types and verification status"""
    DOCUMENT_TYPES = [
        ('national_id', _('National ID Card')),
        ('passport', _('Passport')),
        ('driver_license', _('Driver License')),
        ('business_registration', _('Business Registration')),
        ('tax_certificate', _('Tax Certificate')),
        ('bank_statement', _('Bank Statement')),
        ('utility_bill', _('Utility Bill')),
    ]
    
    VERIFICATION_STATUS = [
        ('pending', _('Pending Verification')),
        ('verified', _('Verified')),
        ('rejected', _('Rejected')),
        ('expired', _('Expired')),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    merchant = models.ForeignKey('MerchantProfile', on_delete=models.CASCADE, related_name='kyc_documents')
    document_type = models.CharField(max_length=25, choices=DOCUMENT_TYPES)
    document_number = models.CharField(max_length=100, blank=True)
    document_image = models.ImageField(upload_to='kyc_documents/', null=True, blank=True)
    verification_status = models.CharField(max_length=20, choices=VERIFICATION_STATUS, default='pending')
    verification_notes = models.TextField(blank=True)
    expiry_date = models.DateField(null=True, blank=True)
    issued_date = models.DateField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    verified_at = models.DateTimeField(null=True, blank=True)
    verified_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)
    
    class Meta:
        verbose_name = _("KYC Document")
        verbose_name_plural = _("KYC Documents")
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.merchant.business_name} - {self.get_document_type_display()}"


class KYCVerification(models.Model):
    """Complete KYC verification process for merchants"""
    VERIFICATION_LEVELS = [
        ('basic', _('Basic Verification')),
        ('enhanced', _('Enhanced Verification')),
        ('premium', _('Premium Verification')),
    ]
    
    STATUS_CHOICES = [
        ('pending', _('Pending')),
        ('in_review', _('In Review')),
        ('approved', _('Approved')),
        ('rejected', _('Rejected')),
        ('requires_more_info', _('Requires More Information')),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    merchant = models.OneToOneField('MerchantProfile', on_delete=models.CASCADE, related_name='kyc_verification')
    verification_level = models.CharField(max_length=20, choices=VERIFICATION_LEVELS, default='basic')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    overall_score = models.IntegerField(default=0, help_text="Overall KYC score (0-100)")
    risk_assessment = models.TextField(blank=True, help_text="AI-powered risk assessment")
    compliance_notes = models.TextField(blank=True)
    approved_at = models.DateTimeField(null=True, blank=True)
    approved_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='kyc_approvals')
    expires_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = _("KYC Verification")
        verbose_name_plural = _("KYC Verifications")
        ordering = ['-created_at']
    
    def __str__(self):
        return f"KYC Verification - {self.merchant.business_name}"
    
    def is_approved(self):
        return self.status == 'approved' and (self.expires_at is None or self.expires_at > timezone.now())
    
    def get_required_documents(self):
        """Get required documents based on verification level"""
        if self.verification_level == 'basic':
            return ['national_id', 'business_registration']
        elif self.verification_level == 'enhanced':
            return ['national_id', 'business_registration', 'tax_certificate', 'bank_statement']
        elif self.verification_level == 'premium':
            return ['national_id', 'passport', 'business_registration', 'tax_certificate', 'bank_statement', 'utility_bill']
        return []


class BankAccount(models.Model):
    """Bank account information for merchants"""
    ACCOUNT_TYPES = [
        ('current', _('Current Account')),
        ('savings', _('Savings Account')),
        ('business', _('Business Account')),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    merchant = models.ForeignKey('MerchantProfile', on_delete=models.CASCADE, related_name='bank_accounts')
    bank_name = models.CharField(max_length=100)
    bank_code = models.CharField(max_length=20, help_text="Bank routing code")
    account_number = models.CharField(max_length=50)
    account_name = models.CharField(max_length=100)
    account_type = models.CharField(max_length=20, choices=ACCOUNT_TYPES, default='business')
    is_primary = models.BooleanField(default=False)
    is_verified = models.BooleanField(default=False)
    verification_date = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = _("Bank Account")
        verbose_name_plural = _("Bank Accounts")
        ordering = ['-is_primary', '-created_at']
    
    def __str__(self):
        return f"{self.bank_name} - {self.account_number[-4:]}"


class ComplianceCheck(models.Model):
    """Compliance and regulatory checks"""
    CHECK_TYPES = [
        ('sanctions', _('Sanctions Check')),
        ('pep', _('Politically Exposed Person Check')),
        ('aml', _('Anti-Money Laundering Check')),
        ('fraud', _('Fraud Detection')),
        ('credit', _('Credit History Check')),
    ]
    
    STATUS_CHOICES = [
        ('pending', _('Pending')),
        ('passed', _('Passed')),
        ('failed', _('Failed')),
        ('flagged', _('Flagged for Review')),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    merchant = models.ForeignKey('MerchantProfile', on_delete=models.CASCADE, related_name='compliance_checks')
    check_type = models.CharField(max_length=20, choices=CHECK_TYPES)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    check_result = models.JSONField(default=dict, blank=True, help_text="Detailed check results")
    risk_score = models.IntegerField(default=0, help_text="Risk score (0-100)")
    recommendations = models.TextField(blank=True)
    performed_at = models.DateTimeField(auto_now_add=True)
    next_check_due = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        verbose_name = _("Compliance Check")
        verbose_name_plural = _("Compliance Checks")
        ordering = ['-performed_at']
    
    def __str__(self):
        return f"{self.merchant.business_name} - {self.get_check_type_display()}"
