"""
Insurance serializers for API
"""
from rest_framework import serializers
from ..models_insurance import (
    InsurancePolicy, InsuranceClaim, InsuranceRiskAssessment, 
    InsuranceCoverage, InsurancePremium
)
from ..models import MerchantProfile


class InsurancePolicySerializer(serializers.ModelSerializer):
    """Serializer for insurance policies"""
    is_active = serializers.ReadOnlyField()
    days_until_expiry = serializers.ReadOnlyField()
    
    class Meta:
        model = InsurancePolicy
        fields = [
            'id', 'merchant', 'policy_number', 'policy_type', 'status',
            'total_coverage_amount', 'deductible_amount', 'premium_amount',
            'start_date', 'end_date', 'created_at', 'updated_at',
            'premium_paid', 'premium_paid_date', 'next_premium_due',
            'is_active', 'days_until_expiry'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'premium_paid_date']
    
    def validate_policy_type(self, value):
        """Validate policy type"""
        valid_types = [choice[0] for choice in InsurancePolicy.POLICY_TYPES]
        if value not in valid_types:
            raise serializers.ValidationError(f"Invalid policy type. Must be one of: {valid_types}")
        return value
    
    def validate_start_date(self, value):
        """Validate start date is not in the past"""
        from django.utils import timezone
        if value < timezone.now().date():
            raise serializers.ValidationError("Start date cannot be in the past")
        return value
    
    def validate_end_date(self, value):
        """Validate end date is after start date"""
        start_date = self.initial_data.get('start_date')
        if start_date and value <= start_date:
            raise serializers.ValidationError("End date must be after start date")
        return value


class InsuranceClaimSerializer(serializers.ModelSerializer):
    """Serializer for insurance claims"""
    
    class Meta:
        model = InsuranceClaim
        fields = [
            'id', 'policy', 'claim_number', 'claim_type', 'status',
            'description', 'estimated_loss', 'approved_amount',
            'incident_date', 'incident_location', 'police_report_filed',
            'police_report_number', 'incident_photos', 'supporting_documents',
            'submitted_at', 'reviewed_at', 'approved_at', 'paid_at',
            'reviewed_by', 'settlement_notes', 'payment_reference'
        ]
        read_only_fields = [
            'id', 'claim_number', 'submitted_at', 'reviewed_at', 
            'approved_at', 'paid_at', 'reviewed_by'
        ]
    
    def validate_claim_type(self, value):
        """Validate claim type"""
        valid_types = [choice[0] for choice in InsuranceClaim.CLAIM_TYPES]
        if value not in valid_types:
            raise serializers.ValidationError(f"Invalid claim type. Must be one of: {valid_types}")
        return value
    
    def validate_estimated_loss(self, value):
        """Validate estimated loss is positive"""
        if value <= 0:
            raise serializers.ValidationError("Estimated loss must be positive")
        return value


class InsuranceRiskAssessmentSerializer(serializers.ModelSerializer):
    """Serializer for insurance risk assessments"""
    
    class Meta:
        model = InsuranceRiskAssessment
        fields = [
            'id', 'merchant', 'risk_level', 'risk_score',
            'location_risk', 'inventory_value', 'security_measures',
            'previous_claims', 'assessment_date', 'next_assessment_due',
            'assessment_notes'
        ]
        read_only_fields = ['id', 'assessment_date']


class InsuranceCoverageSerializer(serializers.ModelSerializer):
    """Serializer for insurance coverage details"""
    
    class Meta:
        model = InsuranceCoverage
        fields = [
            'id', 'policy_type', 'coverage_type', 'is_included',
            'coverage_limit', 'deductible_percentage'
        ]
        read_only_fields = ['id']


class InsurancePremiumSerializer(serializers.ModelSerializer):
    """Serializer for insurance premiums"""
    
    class Meta:
        model = InsurancePremium
        fields = [
            'id', 'policy', 'premium_number', 'amount', 'due_date',
            'payment_status', 'paid_amount', 'paid_date',
            'payment_method', 'payment_reference',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class PremiumCalculationSerializer(serializers.Serializer):
    """Serializer for premium calculation requests"""
    merchant_id = serializers.UUIDField()
    coverage_amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    policy_type = serializers.ChoiceField(
        choices=InsurancePolicy.POLICY_TYPES,
        default='basic'
    )
    risk_score = serializers.IntegerField(default=50, min_value=0, max_value=100)
    
    def validate_merchant_id(self, value):
        """Validate merchant exists"""
        if not MerchantProfile.objects.filter(id=value).exists():
            raise serializers.ValidationError("Merchant not found")
        return value
    
    def validate_coverage_amount(self, value):
        """Validate coverage amount"""
        if value <= 0:
            raise serializers.ValidationError("Coverage amount must be positive")
        if value > 10000000:  # 10 million limit
            raise serializers.ValidationError("Coverage amount exceeds maximum limit")
        return value


class RiskAssessmentRequestSerializer(serializers.Serializer):
    """Serializer for risk assessment requests"""
    merchant_id = serializers.UUIDField()
    
    def validate_merchant_id(self, value):
        """Validate merchant exists"""
        if not MerchantProfile.objects.filter(id=value).exists():
            raise serializers.ValidationError("Merchant not found")
        return value


class InsurancePolicyCreateSerializer(serializers.Serializer):
    """Serializer for creating insurance policies"""
    merchant_id = serializers.UUIDField()
    coverage_amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    policy_type = serializers.ChoiceField(
        choices=InsurancePolicy.POLICY_TYPES,
        default='basic'
    )
    start_date = serializers.DateField(required=False)
    end_date = serializers.DateField(required=False)
    
    def validate_merchant_id(self, value):
        """Validate merchant exists"""
        if not MerchantProfile.objects.filter(id=value).exists():
            raise serializers.ValidationError("Merchant not found")
        return value
    
    def validate_coverage_amount(self, value):
        """Validate coverage amount"""
        if value <= 0:
            raise serializers.ValidationError("Coverage amount must be positive")
        if value > 10000000:  # 10 million limit
            raise serializers.ValidationError("Coverage amount exceeds maximum limit")
        return value
    
    def validate(self, data):
        """Validate date relationships"""
        start_date = data.get('start_date')
        end_date = data.get('end_date')
        
        if start_date and end_date:
            if end_date <= start_date:
                raise serializers.ValidationError("End date must be after start date")
        
        return data


class ClaimSubmissionSerializer(serializers.Serializer):
    """Serializer for claim submission"""
    policy_id = serializers.UUIDField()
    claim_type = serializers.ChoiceField(choices=InsuranceClaim.CLAIM_TYPES)
    description = serializers.CharField(max_length=1000)
    estimated_loss = serializers.DecimalField(max_digits=12, decimal_places=2)
    incident_date = serializers.DateTimeField()
    incident_location = serializers.CharField(max_length=255, required=False, allow_blank=True)
    police_report_filed = serializers.BooleanField(default=False)
    police_report_number = serializers.CharField(max_length=50, required=False, allow_blank=True)
    
    def validate_policy_id(self, value):
        """Validate policy exists"""
        if not InsurancePolicy.objects.filter(id=value).exists():
            raise serializers.ValidationError("Policy not found")
        return value
    
    def validate_estimated_loss(self, value):
        """Validate estimated loss"""
        if value <= 0:
            raise serializers.ValidationError("Estimated loss must be positive")
        return value


class ClaimProcessingSerializer(serializers.Serializer):
    """Serializer for claim processing"""
    claim_id = serializers.UUIDField()
    approved_amount = serializers.DecimalField(max_digits=12, decimal_places=2, required=False, allow_null=True)
    status = serializers.ChoiceField(choices=InsuranceClaim.STATUS_CHOICES, default='approved')
    settlement_notes = serializers.CharField(max_length=1000, required=False, allow_blank=True)
    
    def validate_claim_id(self, value):
        """Validate claim exists"""
        if not InsuranceClaim.objects.filter(id=value).exists():
            raise serializers.ValidationError("Claim not found")
        return value
    
    def validate(self, data):
        """Validate approved amount for approved status"""
        status = data.get('status', 'approved')
        approved_amount = data.get('approved_amount')
        
        if status == 'approved' and not approved_amount:
            raise serializers.ValidationError("Approved amount is required for approved claims")
        
        if approved_amount and approved_amount <= 0:
            raise serializers.ValidationError("Approved amount must be positive")
        
        return data


class PolicyDetailsRequestSerializer(serializers.Serializer):
    """Serializer for policy details requests"""
    policy_id = serializers.UUIDField()
    
    def validate_policy_id(self, value):
        """Validate policy exists"""
        if not InsurancePolicy.objects.filter(id=value).exists():
            raise serializers.ValidationError("Policy not found")
        return value


class MerchantPoliciesRequestSerializer(serializers.Serializer):
    """Serializer for merchant policies requests"""
    merchant_id = serializers.UUIDField()
    
    def validate_merchant_id(self, value):
        """Validate merchant exists"""
        if not MerchantProfile.objects.filter(id=value).exists():
            raise serializers.ValidationError("Merchant not found")
        return value
