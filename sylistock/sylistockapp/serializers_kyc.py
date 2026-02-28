"""
KYC (Know Your Customer) serializers for API
"""
from rest_framework import serializers
from ..models_kyc import (KYCDocument, KYCVerification, BankAccount,
                           ComplianceCheck)
from ..models import MerchantProfile


class KYCDocumentSerializer(serializers.ModelSerializer):
    """Serializer for KYC documents"""
    document_type_display = serializers.CharField(
        source='get_document_type_display', read_only=True
    )
    verification_status_display = serializers.CharField(
        source='get_verification_status_display', read_only=True
    )
    is_expired = serializers.BooleanField(read_only=True)
    is_valid = serializers.BooleanField(read_only=True)

    class Meta:
        model = KYCDocument
        fields = [
            'id', 'verification', 'document_type', 'document_type_display',
            'file_name', 'file', 'file_size', 'mime_type', 'upload_date',
            'verification_status', 'verification_status_display',
            'verification_score', 'verification_notes', 'expiry_date',
            'is_expired', 'is_valid'
        ]
        read_only_fields = [
            'id', 'upload_date', 'verification_score', 'is_expired', 'is_valid'
        ]

    def validate_file_size(self, value):
        """Validate file size (max 10MB)"""
        max_size = 10 * 1024 * 1024  # 10MB
        if value.size > max_size:
            raise serializers.ValidationError(
                f"File size cannot exceed 10MB. Current size: "
                f"{value.size / 1024 / 1024:.2f}MB"
            )
        return value

    def validate_expiry_date(self, value):
        """Validate expiry date is not in the past"""
        from django.utils import timezone
        if value and value < timezone.now().date():
            raise serializers.ValidationError(
                "Expiry date cannot be in the past"
            )
        return value


class KYCVerificationSerializer(serializers.ModelSerializer):
    """Serializer for KYC verification"""
    merchant_name = serializers.CharField(
        source='merchant.business_name', read_only=True
    )
    verification_level_display = serializers.CharField(
        source='get_verification_level_display', read_only=True
    )
    status_display = serializers.CharField(
        source='get_status_display', read_only=True
    )
    reviewer_name = serializers.CharField(
        source='reviewer.get_full_name', read_only=True
    )
    completion_percentage = serializers.IntegerField(read_only=True)
    is_approved = serializers.BooleanField(read_only=True)
    is_expired = serializers.BooleanField(read_only=True)
    documents_count = serializers.SerializerMethodField()

    class Meta:
        model = KYCVerification
        fields = [
            'id', 'merchant', 'merchant_name', 'verification_level',
            'verification_level_display', 'status', 'status_display',
            'overall_score', 'submitted_at', 'reviewed_at', 'approved_at',
            'expires_at', 'reviewer', 'reviewer_name', 'review_notes',
            'completion_percentage', 'is_approved', 'is_expired',
            'documents_count'
        ]
        read_only_fields = [
            'id', 'submitted_at', 'reviewed_at', 'approved_at', 'reviewer',
            'completion_percentage', 'is_approved', 'is_expired'
        ]

    def get_documents_count(self, obj):
        """Get count of uploaded documents"""
        return obj.documents.count()

    def validate_expires_at(self, value):
        """Validate expiry date is after submission date"""
        if value and value <= obj.submitted_at.date():
            raise serializers.ValidationError(
                "Expiry date must be after submission date"
            )
        return value


class BankAccountSerializer(serializers.ModelSerializer):
    """Serializer for bank accounts"""
    account_type_display = serializers.CharField(
        source='get_account_type_display', read_only=True
    )
    verification_status_display = serializers.CharField(
        source='get_verification_status_display', read_only=True
    )
    masked_account_number = serializers.CharField(read_only=True)

    class Meta:
        model = BankAccount
        fields = [
            'id', 'verification', 'account_number', 'account_name',
            'bank_name', 'bank_code', 'branch_name', 'account_type',
            'account_type_display', 'verification_status',
            'verification_status_display', 'verification_score',
            'verification_notes', 'created_at', 'verified_at',
            'masked_account_number'
        ]
        read_only_fields = [
            'id', 'created_at', 'verified_at', 'masked_account_number'
        ]

    def validate_account_number(self, value):
        """Validate account number format"""
        if len(value) < 8:
            raise serializers.ValidationError(
                "Account number must be at least 8 digits"
            )
        return value

    def validate_account_name(self, value):
        """Validate account name matches account holder"""
        if not value.strip():
            raise serializers.ValidationError("Account name is required")
        return value.strip()


class ComplianceCheckSerializer(serializers.ModelSerializer):
    """Serializer for compliance checks"""
    check_type_display = serializers.CharField(
        source='get_check_type_display', read_only=True
    )
    result_display = serializers.CharField(
        source='get_result_display', read_only=True
    )
    percentage_score = serializers.IntegerField(read_only=True)
    checked_by_name = serializers.CharField(
        source='checked_by.get_full_name', read_only=True
    )

    class Meta:
        model = ComplianceCheck
        fields = [
            'id', 'verification', 'check_type', 'check_type_display',
            'result', 'result_display', 'score', 'max_score',
            'percentage_score', 'details', 'checked_at', 'checked_by',
            'checked_by_name'
        ]
        read_only_fields = [
            'id', 'checked_at', 'checked_by', 'percentage_score'
        ]

    def validate_score(self, value):
        """Ensure score is within valid range"""
        if not 0 <= value <= self.max_score:
            raise serializers.ValidationError(
                f"Score must be between 0 and {self.max_score}"
            )
        return value


class CreateKYCVerificationSerializer(serializers.ModelSerializer):
    """Serializer for creating KYC verification"""
    class Meta:
        model = KYCVerification
        fields = ['merchant', 'verification_level']

    def validate_merchant(self, value):
        """Validate merchant exists and has no active KYC"""
        existing_kyc = KYCVerification.objects.filter(
            merchant=value, status='approved'
        ).first()

        if existing_kyc and not existing_kyc.is_expired():
            raise serializers.ValidationError(
                "Merchant already has an active KYC verification"
            )

        return value


class UploadDocumentSerializer(serializers.ModelSerializer):
    """Serializer for uploading KYC documents"""
    class Meta:
        model = KYCDocument
        fields = [
            'verification', 'document_type', 'file', 'expiry_date',
            'verification_notes'
        ]

    def validate_file(self, value):
        """Validate uploaded file"""
        # File size validation
        max_size = 10 * 1024 * 1024  # 10MB
        if value.size > max_size:
            raise serializers.ValidationError(
                f"File size cannot exceed 10MB. Current size: "
                f"{value.size / 1024 / 1024:.2f}MB"
            )

        # File type validation
        allowed_types = ['image/jpeg', 'image/png', 'application/pdf']
        if value.content_type not in allowed_types:
            raise serializers.ValidationError(
                "Only JPEG, PNG, and PDF files are allowed"
            )

        return value


class AddBankAccountSerializer(serializers.ModelSerializer):
    """Serializer for adding bank accounts"""
    class Meta:
        model = BankAccount
        fields = [
            'account_number', 'account_name', 'bank_name', 'bank_code',
            'branch_name', 'account_type'
        ]

    def validate_account_number(self, value):
        """Validate account number format"""
        if not value.isdigit():
            raise serializers.ValidationError(
                "Account number must contain only digits"
            )

        if len(value) < 8:
            raise serializers.ValidationError(
                "Account number must be at least 8 digits"
            )

        return value

    def validate_account_name(self, value):
        """Validate account name"""
        if not value.strip():
            raise serializers.ValidationError("Account name is required")
        return value.strip()


class UpdateKYCStatusSerializer(serializers.Serializer):
    """Serializer for updating KYC status"""
    status = serializers.ChoiceField(
        choices=KYCVerification.STATUS_CHOICES,
        required=True
    )
    overall_score = serializers.IntegerField(
        required=False, min_value=0, max_value=100
    )
    review_notes = serializers.CharField(
        required=False, allow_blank=True, max_length=1000
    )
    expires_at = serializers.DateTimeField(
        required=False, allow_null=True
    )

    def validate_status(self, value):
        """Validate status transition"""
        if value == 'approved' and self.overall_score < 70:
            raise serializers.ValidationError(
                "Overall score must be at least 70 for approval"
            )
        return value
