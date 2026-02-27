"""
KYC (Know Your Customer) serializers for API
"""
from rest_framework import serializers
from ..models_kyc import KYCDocument, KYCVerification, BankAccount, ComplianceCheck
from ..models import MerchantProfile


class KYCDocumentSerializer(serializers.ModelSerializer):
    """Serializer for KYC documents"""
    
    class Meta:
        model = KYCDocument
        fields = [
            'id', 'merchant', 'document_type', 'document_number',
            'document_image', 'verification_status', 'verification_notes',
            'expiry_date', 'issued_date', 'created_at', 'updated_at',
            'verified_at', 'verified_by'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'verified_at', 'verified_by']
    
    def validate_document_type(self, value):
        """Validate document type"""
        valid_types = [choice[0] for choice in KYCDocument.DOCUMENT_TYPES]
        if value not in valid_types:
            raise serializers.ValidationError(f"Invalid document type. Must be one of: {valid_types}")
        return value
    
    def validate_expiry_date(self, value):
        """Validate expiry date is not in the past"""
        if value and value < serializers.DateField().to_internal_value('today'):
            raise serializers.ValidationError("Expiry date cannot be in the past")
        return value


class KYCVerificationSerializer(serializers.ModelSerializer):
    """Serializer for KYC verification"""
    documents = KYCDocumentSerializer(many=True, read_only=True, source='kyc_documents')
    required_documents = serializers.SerializerMethodField()
    is_approved = serializers.ReadOnlyField()
    
    class Meta:
        model = KYCVerification
        fields = [
            'id', 'merchant', 'verification_level', 'status', 'overall_score',
            'risk_assessment', 'compliance_notes', 'approved_at', 'approved_by',
            'expires_at', 'created_at', 'updated_at', 'documents', 'required_documents', 'is_approved'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'approved_at', 'approved_by']
    
    def get_required_documents(self, obj):
        """Get required documents based on verification level"""
        return obj.get_required_documents()


class BankAccountSerializer(serializers.ModelSerializer):
    """Serializer for bank accounts"""
    masked_account_number = serializers.ReadOnlyField()
    
    class Meta:
        model = BankAccount
        fields = [
            'id', 'merchant', 'bank_name', 'bank_code', 'account_number',
            'masked_account_number', 'account_name', 'account_type',
            'is_primary', 'is_verified', 'verification_date',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'verification_date', 'masked_account_number']
    
    def create(self, validated_data):
        """Handle setting primary account logic"""
        is_primary = validated_data.get('is_primary', False)
        merchant = validated_data['merchant']
        
        # If setting as primary, unset other primary accounts
        if is_primary:
            BankAccount.objects.filter(merchant=merchant, is_primary=True).update(is_primary=False)
        
        return super().create(validated_data)
    
    def validate_account_number(self, value):
        """Mask account number in response"""
        # This will be handled by the masked_account_number field
        return value


class ComplianceCheckSerializer(serializers.ModelSerializer):
    """Serializer for compliance checks"""
    
    class Meta:
        model = ComplianceCheck
        fields = [
            'id', 'merchant', 'check_type', 'status', 'check_result',
            'risk_score', 'recommendations', 'performed_at', 'next_check_due'
        ]
        read_only_fields = ['id', 'performed_at']


class KYCInitiateSerializer(serializers.Serializer):
    """Serializer for initiating KYC process"""
    merchant_id = serializers.UUIDField()
    verification_level = serializers.ChoiceField(
        choices=KYCVerification.VERIFICATION_LEVELS,
        default='basic'
    )
    
    def validate_merchant_id(self, value):
        """Validate merchant exists"""
        if not MerchantProfile.objects.filter(id=value).exists():
            raise serializers.ValidationError("Merchant not found")
        return value


class KYCDocumentUploadSerializer(serializers.Serializer):
    """Serializer for uploading KYC documents"""
    merchant_id = serializers.UUIDField()
    document_type = serializers.ChoiceField(choices=KYCDocument.DOCUMENT_TYPES)
    document_number = serializers.CharField(max_length=100, required=False, allow_blank=True)
    document_image = serializers.ImageField(required=False)
    expiry_date = serializers.DateField(required=False, allow_null=True)
    issued_date = serializers.DateField(required=False, allow_null=True)
    
    def validate_merchant_id(self, value):
        """Validate merchant exists"""
        if not MerchantProfile.objects.filter(id=value).exists():
            raise serializers.ValidationError("Merchant not found")
        return value


class BankAccountCreateSerializer(serializers.Serializer):
    """Serializer for creating bank accounts"""
    merchant_id = serializers.UUIDField()
    bank_name = serializers.CharField(max_length=100)
    bank_code = serializers.CharField(max_length=20)
    account_number = serializers.CharField(max_length=50)
    account_name = serializers.CharField(max_length=100)
    account_type = serializers.ChoiceField(
        choices=BankAccount.ACCOUNT_TYPES,
        default='business'
    )
    is_primary = serializers.BooleanField(default=False)
    
    def validate_merchant_id(self, value):
        """Validate merchant exists"""
        if not MerchantProfile.objects.filter(id=value).exists():
            raise serializers.ValidationError("Merchant not found")
        return value
    
    def validate_account_number(self, value):
        """Validate account number format"""
        if not value.isdigit():
            raise serializers.ValidationError("Account number must contain only digits")
        if len(value) < 8:
            raise serializers.ValidationError("Account number must be at least 8 digits")
        return value


class ComplianceCheckRequestSerializer(serializers.Serializer):
    """Serializer for compliance check requests"""
    merchant_id = serializers.UUIDField()
    
    def validate_merchant_id(self, value):
        """Validate merchant exists"""
        if not MerchantProfile.objects.filter(id=value).exists():
            raise serializers.ValidationError("Merchant not found")
        return value


class KYCEvaluationSerializer(serializers.Serializer):
    """Serializer for KYC evaluation requests"""
    merchant_id = serializers.UUIDField()
    
    def validate_merchant_id(self, value):
        """Validate merchant exists"""
        if not MerchantProfile.objects.filter(id=value).exists():
            raise serializers.ValidationError("Merchant not found")
        return value


class KYCStatusSerializer(serializers.Serializer):
    """Serializer for KYC status requests"""
    merchant_id = serializers.UUIDField()
    
    def validate_merchant_id(self, value):
        """Validate merchant exists"""
        if not MerchantProfile.objects.filter(id=value).exists():
            raise serializers.ValidationError("Merchant not found")
        return value
