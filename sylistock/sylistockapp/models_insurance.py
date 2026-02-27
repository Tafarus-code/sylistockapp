"""
Micro-Insurance models for inventory protection
"""
from django.db import models
from django.contrib.auth.models import User
from django.utils.translation import gettext_lazy as _
import uuid
from decimal import Decimal


class InsurancePolicy(models.Model):
    """Insurance policy for merchant inventory"""
    POLICY_TYPES = [
        ('basic', _('Basic Coverage')),
        ('standard', _('Standard Coverage')),
        ('premium', _('Premium Coverage')),
        ('comprehensive', _('Comprehensive Coverage')),
    ]
    
    STATUS_CHOICES = [
        ('active', _('Active')),
        ('expired', _('Expired')),
        ('cancelled', _('Cancelled')),
        ('pending', _('Pending')),
        ('suspended', _('Suspended')),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    merchant = models.ForeignKey('MerchantProfile', on_delete=models.CASCADE, related_name='insurance_policies')
    policy_number = models.CharField(max_length=50, unique=True)
    policy_type = models.CharField(max_length=20, choices=POLICY_TYPES, default='basic')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    
    # Coverage details
    total_coverage_amount = models.DecimalField(max_digits=12, decimal_places=2)
    deductible_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    premium_amount = models.DecimalField(max_digits=10, decimal_places=2)
    
    # Policy dates
    start_date = models.DateField()
    end_date = models.DateField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    # Payment information
    premium_paid = models.BooleanField(default=False)
    premium_paid_date = models.DateTimeField(null=True, blank=True)
    next_premium_due = models.DateField(null=True, blank=True)
    
    class Meta:
        verbose_name = _("Insurance Policy")
        verbose_name_plural = _("Insurance Policies")
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Policy {self.policy_number} - {self.merchant.business_name}"
    
    def is_active(self):
        """Check if policy is currently active"""
        from django.utils import timezone
        return (
            self.status == 'active' and 
            self.start_date <= timezone.now().date() <= self.end_date
        )
    
    def days_until_expiry(self):
        """Calculate days until policy expires"""
        from django.utils import timezone
        if self.end_date:
            delta = self.end_date - timezone.now().date()
            return delta.days
        return 0


class InsuranceClaim(models.Model):
    """Insurance claim for damaged or lost inventory"""
    CLAIM_TYPES = [
        ('theft', _('Theft')),
        ('damage', _('Damage')),
        ('loss', _('Loss')),
        ('fire', _('Fire')),
        ('flood', _('Flood')),
        ('other', _('Other')),
    ]
    
    STATUS_CHOICES = [
        ('submitted', _('Submitted')),
        ('under_review', _('Under Review')),
        ('approved', _('Approved')),
        ('rejected', _('Rejected')),
        ('paid', _('Paid')),
        ('closed', _('Closed')),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    policy = models.ForeignKey(InsurancePolicy, on_delete=models.CASCADE, related_name='claims')
    claim_number = models.CharField(max_length=50, unique=True)
    claim_type = models.CharField(max_length=20, choices=CLAIM_TYPES)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='submitted')
    
    # Claim details
    description = models.TextField()
    estimated_loss = models.DecimalField(max_digits=12, decimal_places=2)
    approved_amount = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    
    # Incident details
    incident_date = models.DateTimeField()
    incident_location = models.CharField(max_length=255, blank=True)
    police_report_filed = models.BooleanField(default=False)
    police_report_number = models.CharField(max_length=50, blank=True)
    
    # Supporting documents
    incident_photos = models.JSONField(default=list, blank=True)
    supporting_documents = models.JSONField(default=list, blank=True)
    
    # Processing details
    submitted_at = models.DateTimeField(auto_now_add=True)
    reviewed_at = models.DateTimeField(null=True, blank=True)
    approved_at = models.DateTimeField(null=True, blank=True)
    paid_at = models.DateTimeField(null=True, blank=True)
    reviewed_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)
    
    # Settlement details
    settlement_notes = models.TextField(blank=True)
    payment_reference = models.CharField(max_length=100, blank=True)
    
    class Meta:
        verbose_name = _("Insurance Claim")
        verbose_name_plural = _("Insurance Claims")
        ordering = ['-submitted_at']
    
    def __str__(self):
        return f"Claim {self.claim_number} - {self.policy.merchant.business_name}"


class InsuranceRiskAssessment(models.Model):
    """Risk assessment for insurance pricing"""
    RISK_LEVELS = [
        ('low', _('Low Risk')),
        ('medium', _('Medium Risk')),
        ('high', _('High Risk')),
        ('very_high', _('Very High Risk')),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    merchant = models.ForeignKey('MerchantProfile', on_delete=models.CASCADE, related_name='risk_assessments')
    risk_level = models.CharField(max_length=20, choices=RISK_LEVELS, default='medium')
    risk_score = models.IntegerField(default=50, help_text="Risk score (0-100)")
    
    # Assessment factors
    location_risk = models.IntegerField(default=50, help_text="Location-based risk score")
    inventory_value = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    security_measures = models.JSONField(default=dict, blank=True)
    previous_claims = models.IntegerField(default=0)
    
    # Assessment details
    assessment_date = models.DateTimeField(auto_now_add=True)
    next_assessment_due = models.DateTimeField(null=True, blank=True)
    assessment_notes = models.TextField(blank=True)
    
    class Meta:
        verbose_name = _("Insurance Risk Assessment")
        verbose_name_plural = _("Insurance Risk Assessments")
        ordering = ['-assessment_date']
    
    def __str__(self):
        return f"Risk Assessment - {self.merchant.business_name}"


class InsuranceCoverage(models.Model):
    """Specific coverage details for different policy types"""
    COVERAGE_TYPES = [
        ('theft', _('Theft Protection')),
        ('fire', _('Fire Protection')),
        ('flood', _('Flood Protection')),
        ('damage', _('Accidental Damage')),
        ('loss', _('Mysterious Loss')),
        ('business_interruption', _('Business Interruption')),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    policy_type = models.CharField(max_length=20, choices=InsurancePolicy.POLICY_TYPES)
    coverage_type = models.CharField(max_length=30, choices=COVERAGE_TYPES)
    is_included = models.BooleanField(default=False)
    coverage_limit = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    deductible_percentage = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    
    class Meta:
        verbose_name = _("Insurance Coverage")
        verbose_name_plural = _("Insurance Coverage")
        unique_together = ['policy_type', 'coverage_type']
    
    def __str__(self):
        return f"{self.policy_type} - {self.get_coverage_type_display()}"


class InsurancePremium(models.Model):
    """Premium calculation and payment tracking"""
    PAYMENT_STATUS = [
        ('pending', _('Pending')),
        ('paid', _('Paid')),
        ('overdue', _('Overdue')),
        ('cancelled', _('Cancelled')),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    policy = models.ForeignKey(InsurancePolicy, on_delete=models.CASCADE, related_name='premiums')
    premium_number = models.CharField(max_length=50)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    due_date = models.DateField()
    payment_status = models.CharField(max_length=20, choices=PAYMENT_STATUS, default='pending')
    
    # Payment details
    paid_amount = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    paid_date = models.DateTimeField(null=True, blank=True)
    payment_method = models.CharField(max_length=50, blank=True)
    payment_reference = models.CharField(max_length=100, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = _("Insurance Premium")
        verbose_name_plural = _("Insurance Premiums")
        ordering = ['due_date']
    
    def __str__(self):
        return f"Premium {self.premium_number} - {self.policy.policy_number}"
