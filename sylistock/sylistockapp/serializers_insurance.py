"""
Insurance serializers for API
"""
from rest_framework import serializers
from .models_insurance import (
    InsurancePolicy, InsuranceClaim, InsuranceRiskAssessment,
    InsuranceCoverage, InsurancePremium
)


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
        read_only_fields = ['id', 'created_at', 'updated_at']

    def validate_end_date(self, value):
        """Ensure end date is after start date"""
        start_date = self.initial_data.get('start_date')
        if start_date and value <= start_date:
            raise serializers.ValidationError(
                "End date must be after start date"
            )
        return value


class InsuranceClaimSerializer(serializers.ModelSerializer):
    """Serializer for insurance claims"""
    policy_details = InsurancePolicySerializer(
        source='policy', read_only=True
    )

    class Meta:
        model = InsuranceClaim
        fields = [
            'id', 'policy', 'policy_details', 'claim_number', 'claim_type',
            'status', 'description', 'estimated_loss', 'approved_amount',
            'incident_date', 'incident_location', 'police_report_filed',
            'police_report_number', 'incident_photos', 'supporting_documents',
            'submitted_at', 'reviewed_at', 'approved_at', 'paid_at',
            'reviewed_by', 'settlement_notes', 'payment_reference'
        ]
        read_only_fields = [
            'id', 'claim_number', 'submitted_at', 'reviewed_at',
            'approved_at', 'paid_at', 'reviewed_by'
        ]

    def validate_estimated_loss(self, value):
        """Ensure estimated loss is positive"""
        if value <= 0:
            raise serializers.ValidationError(
                "Estimated loss must be a positive number"
            )
        return value


class InsuranceRiskAssessmentSerializer(serializers.ModelSerializer):
    """Serializer for insurance risk assessments"""
    merchant_name = serializers.CharField(
        source='merchant.business_name', read_only=True
    )

    class Meta:
        model = InsuranceRiskAssessment
        fields = [
            'id', 'merchant', 'merchant_name', 'risk_level', 'risk_score',
            'location_risk', 'inventory_value', 'security_measures',
            'previous_claims', 'assessment_date', 'next_assessment_due',
            'assessment_notes'
        ]
        read_only_fields = ['id', 'assessment_date']

    def validate_risk_score(self, value):
        """Ensure risk score is between 0 and 100"""
        if not 0 <= value <= 100:
            raise serializers.ValidationError(
                "Risk score must be between 0 and 100"
            )
        return value


class InsuranceCoverageSerializer(serializers.ModelSerializer):
    """Serializer for insurance coverage options"""
    policy_type_display = serializers.CharField(
        source='get_policy_type_display', read_only=True
    )
    coverage_type_display = serializers.CharField(
        source='get_coverage_type_display', read_only=True
    )

    class Meta:
        model = InsuranceCoverage
        fields = [
            'id', 'policy_type', 'policy_type_display', 'coverage_type',
            'coverage_type_display', 'is_included', 'coverage_limit',
            'deductible_percentage'
        ]
        read_only_fields = ['id']


class InsurancePremiumSerializer(serializers.ModelSerializer):
    """Serializer for insurance premiums"""
    policy_number = serializers.CharField(
        source='policy.policy_number', read_only=True
    )
    payment_status_display = serializers.CharField(
        source='get_payment_status_display', read_only=True
    )

    class Meta:
        model = InsurancePremium
        fields = [
            'id', 'policy', 'policy_number', 'premium_number', 'amount',
            'due_date', 'payment_status', 'payment_status_display',
            'paid_amount', 'paid_date', 'payment_method',
            'payment_reference', 'created_at', 'updated_at'
        ]
        read_only_fields = [
            'id', 'premium_number', 'created_at', 'updated_at'
        ]

    def validate_amount(self, value):
        """Ensure premium amount is positive"""
        if value <= 0:
            raise serializers.ValidationError(
                "Premium amount must be a positive number"
            )
        return value


class CreateInsurancePolicySerializer(serializers.ModelSerializer):
    """Serializer for creating insurance policies"""
    class Meta:
        model = InsurancePolicy
        fields = [
            'merchant', 'policy_type', 'total_coverage_amount',
            'deductible_amount', 'premium_amount', 'start_date',
            'end_date'
        ]

    def validate(self, data):
        """Validate policy data"""
        start_date = data.get('start_date')
        end_date = data.get('end_date')
        coverage_amount = data.get('total_coverage_amount')
        deductible_amount = data.get('deductible_amount')

        if start_date and end_date and end_date <= start_date:
            raise serializers.ValidationError({
                'end_date': "End date must be after start date"
            })

        if (coverage_amount and deductible_amount and
                deductible_amount >= coverage_amount):
            raise serializers.ValidationError({
                'deductible_amount': (
                    "Deductible cannot be greater than or equal to "
                    "coverage amount"
                )
            })

        return data


class CreateInsuranceClaimSerializer(serializers.ModelSerializer):
    """Serializer for creating insurance claims"""
    class Meta:
        model = InsuranceClaim
        fields = [
            'policy', 'claim_type', 'description', 'estimated_loss',
            'incident_date', 'incident_location', 'police_report_filed',
            'police_report_number'
        ]

    def validate(self, data):
        """Validate claim data"""
        policy = data.get('policy')
        estimated_loss = data.get('estimated_loss')

        if policy and estimated_loss:
            if estimated_loss > policy.total_coverage_amount:
                raise serializers.ValidationError({
                    'estimated_loss': (
                        "Estimated loss cannot exceed policy coverage amount"
                    )
                })

        return data


class UpdateInsuranceClaimStatusSerializer(serializers.Serializer):
    """Serializer for updating claim status"""
    action = serializers.ChoiceField(
        choices=['approve', 'reject', 'request_info'],
        required=True
    )
    approved_amount = serializers.DecimalField(
        max_digits=12, decimal_places=2, required=False
    )
    notes = serializers.CharField(required=False, allow_blank=True)

    def validate(self, data):
        """Validate status update data"""
        action = data.get('action')
        approved_amount = data.get('approved_amount')

        if action == 'approve' and not approved_amount:
            raise serializers.ValidationError({
                'approved_amount': (
                    "Approved amount is required when approving a claim"
                )
            })

        if action == 'approve' and approved_amount <= 0:
            raise serializers.ValidationError({
                'approved_amount': "Approved amount must be positive"
            })

        return data
