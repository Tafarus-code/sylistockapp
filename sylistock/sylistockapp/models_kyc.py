"""
KYC (Know Your Customer) models for bank compliance
"""
from django.db import models
from django.contrib.auth.models import User
from django.utils.translation import gettext_lazy as _
from django.utils import timezone
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
        ('pending', _('Pending')),
        ('verified', _('Verified')),
        ('rejected', _('Rejected')),
        ('expired', _('Expired')),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4,
                          editable=False)
    verification = models.ForeignKey(
        'KYCVerification', on_delete=models.CASCADE,
        related_name='documents'
    )
    document_type = models.CharField(max_length=30, choices=DOCUMENT_TYPES)
    file_name = models.CharField(max_length=255)
    file = models.FileField(upload_to='kyc_documents/')
    file_size = models.IntegerField(default=0)
    mime_type = models.CharField(max_length=100)
    upload_date = models.DateTimeField(auto_now_add=True)
    verification_status = models.CharField(max_length=20,
                                           choices=VERIFICATION_STATUS,
                                           default='pending')
    verification_score = models.IntegerField(default=0)
    verification_notes = models.TextField(blank=True)
    expiry_date = models.DateField(null=True, blank=True)

    class Meta:
        verbose_name = _("KYC Document")
        verbose_name_plural = _("KYC Documents")
        ordering = ['-upload_date']

    def __str__(self):
        return f"{self.get_document_type_display()} - {self.verification}"

    def is_expired(self):
        """Check if document has expired"""
        if self.expiry_date:
            return self.expiry_date < timezone.now().date()
        return False

    def is_valid(self):
        """Check if document is valid and not expired"""
        return (self.verification_status == 'verified' and
                not self.is_expired())


class KYCVerification(models.Model):
    """KYC verification process tracking"""
    VERIFICATION_LEVELS = [
        ('basic', _('Basic')),
        ('standard', _('Standard')),
        ('enhanced', _('Enhanced')),
    ]

    STATUS_CHOICES = [
        ('pending', _('Pending')),
        ('in_progress', _('In Progress')),
        ('approved', _('Approved')),
        ('rejected', _('Rejected')),
        ('expired', _('Expired')),
        ('suspended', _('Suspended')),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4,
                          editable=False)
    merchant = models.ForeignKey('MerchantProfile', on_delete=models.CASCADE,
                                 related_name='kyc_verifications')
    verification_level = models.CharField(max_length=20,
                                          choices=VERIFICATION_LEVELS,
                                          default='basic')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES,
                              default='pending')
    overall_score = models.IntegerField(default=0)
    submitted_at = models.DateTimeField(auto_now_add=True)
    reviewed_at = models.DateTimeField(null=True, blank=True)
    approved_at = models.DateTimeField(null=True, blank=True)
    expires_at = models.DateTimeField(null=True, blank=True)
    reviewer = models.ForeignKey(User, on_delete=models.SET_NULL, null=True,
                                 blank=True, related_name='kyc_reviews')
    previous_verification = models.ForeignKey(
        'self', on_delete=models.SET_NULL, null=True, blank=True
    )

    class Meta:
        verbose_name = _("KYC Verification")
        verbose_name_plural = _("KYC Verifications")
        ordering = ['-submitted_at']

    def __str__(self):
        return f"KYC {self.verification_level} - {self.merchant}"

    def get_required_documents(self):
        """Get required documents based on verification level"""
        requirements = {
            'basic': ['national_id', 'utility_bill'],
            'standard': ['national_id', 'utility_bill',
                         'business_registration'],
            'enhanced': [
                'national_id', 'utility_bill', 'business_registration',
                'tax_certificate', 'bank_statement'
            ],
        }
        return requirements.get(self.verification_level, [])

    def is_approved(self):
        """Check if KYC verification is approved"""
        return self.status == 'approved' and not self.is_expired()

    def is_expired(self):
        """Check if KYC verification has expired"""
        if self.expires_at:
            return self.expires_at < timezone.now()
        return False

    def get_completion_percentage(self):
        """Calculate completion percentage based on uploaded documents"""
        required_docs = self.get_required_documents()
        uploaded_docs = self.documents.filter(
            verification_status='verified'
        ).values_list('document_type', flat=True)

        if not required_docs:
            return 0

        completed = sum(1 for doc in required_docs if doc in uploaded_docs)
        return int((completed / len(required_docs)) * 100)


class BankAccount(models.Model):
    """Bank account information for KYC verification"""
    ACCOUNT_TYPES = [
        ('checking', _('Checking Account')),
        ('savings', _('Savings Account')),
        ('business', _('Business Account')),
        ('current', _('Current Account')),
    ]

    VERIFICATION_STATUS = [
        ('pending', _('Pending')),
        ('verified', _('Verified')),
        ('rejected', _('Rejected')),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4,
                          editable=False)
    verification = models.ForeignKey(
        'KYCVerification', on_delete=models.CASCADE,
        related_name='bank_accounts'
    )
    account_number = models.CharField(max_length=50)
    account_name = models.CharField(max_length=255)
    bank_name = models.CharField(max_length=255)
    bank_code = models.CharField(max_length=20, blank=True)
    branch_name = models.CharField(max_length=255, blank=True)
    account_type = models.CharField(max_length=20, choices=ACCOUNT_TYPES)
    verification_status = models.CharField(max_length=20,
                                           choices=VERIFICATION_STATUS,
                                           default='pending')
    verification_score = models.IntegerField(default=0)
    verification_notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    verified_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        verbose_name = _("Bank Account")
        verbose_name_plural = _("Bank Accounts")
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.bank_name} - {self.account_number[-4:]}"

    def mask_account_number(self):
        """Return masked account number for display"""
        if len(self.account_number) <= 4:
            return '*' * len(self.account_number)
        return '*' * (len(self.account_number) - 4) + self.account_number[-4:]


class ComplianceCheck(models.Model):
    """Compliance check results and scoring"""
    CHECK_TYPES = [
        ('identity', _('Identity Verification')),
        ('address', _('Address Verification')),
        ('business', _('Business Verification')),
        ('financial', _('Financial Verification')),
        ('risk', _('Risk Assessment')),
    ]

    RESULT_TYPES = [
        ('pass', _('Pass')),
        ('fail', _('Fail')),
        ('review', _('Manual Review Required')),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4,
                          editable=False)
    verification = models.ForeignKey(
        'KYCVerification', on_delete=models.CASCADE,
        related_name='compliance_checks'
    )
    check_type = models.CharField(max_length=20, choices=CHECK_TYPES)
    result = models.CharField(max_length=20, choices=RESULT_TYPES)
    score = models.IntegerField(default=0)
    max_score = models.IntegerField(default=100)
    details = models.JSONField(default=dict, blank=True)
    checked_at = models.DateTimeField(auto_now_add=True)
    checked_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True,
                                   blank=True)

    class Meta:
        verbose_name = _("Compliance Check")
        verbose_name_plural = _("Compliance Checks")
        ordering = ['-checked_at']

    def __str__(self):
        return f"{self.get_check_type_display()} - {self.result}"

    def get_percentage_score(self):
        """Get score as percentage"""
        if self.max_score == 0:
            return 0
        return int((self.score / self.max_score) * 100)
