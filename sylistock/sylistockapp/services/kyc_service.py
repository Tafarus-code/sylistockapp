"""
KYC (Know Your Customer) Service for bank compliance
"""
from django.core.files.base import ContentFile
from ..models_kyc import (
    KYCDocument, KYCVerification, BankAccount, ComplianceCheck
)
from ..models import MerchantProfile


class KYCService:
    """Know Your Customer service for bank compliance"""

    def __init__(self):
        self.verification_threshold = 70  # Minimum score for approval

    def initiate_kyc_process(self, merchant_id, verification_level='basic'):
        """Initiate KYC verification process for a merchant"""
        try:
            merchant = MerchantProfile.objects.get(id=merchant_id)

            # Create or update KYC verification
            kyc_verification, created = KYCVerification.objects.get_or_create(
                merchant=merchant,
                defaults={
                    'verification_level': verification_level,
                    'status': 'pending',
                    'overall_score': 0,
                }
            )

            if not created:
                kyc_verification.verification_level = verification_level
                kyc_verification.status = 'pending'
                kyc_verification.save()

            # Get required documents for this verification level
            required_documents = kyc_verification.get_required_documents()

            return {
                'success': True,
                'kyc_id': str(kyc_verification.id),
                'verification_level': verification_level,
                'status': kyc_verification.status,
                'required_documents': required_documents,
            }

        except MerchantProfile.DoesNotExist:
            return {
                'success': False,
                'error': 'Merchant not found',
            }

    def upload_document(self, kyc_id, document_type, file_data, file_name):
        """Upload and process KYC document"""
        try:
            kyc_verification = KYCVerification.objects.get(id=kyc_id)

            # Create KYC document record
            kyc_document = KYCDocument.objects.create(
                verification=kyc_verification,
                document_type=document_type,
                file_name=file_name,
                status='uploaded',
            )

            # Save file
            kyc_document.file.save(file_name, ContentFile(file_data))

            # Perform basic validation
            validation_result = self._validate_document(kyc_document)

            return {
                'success': True,
                'document_id': str(kyc_document.id),
                'validation_result': validation_result,
            }

        except KYCVerification.DoesNotExist:
            return {
                'success': False,
                'error': 'KYC verification not found',
            }

    def _validate_document(self, document):
        """Validate uploaded document"""
        validation_score = 0
        issues = []

        # Check file size
        if document.file.size > 10 * 1024 * 1024:  # 10MB limit
            issues.append('File size exceeds 10MB limit')
        else:
            validation_score += 20

        # Check file type
        allowed_types = ['image/jpeg', 'image/png', 'application/pdf']
        if document.file.content_type not in allowed_types:
            issues.append('Invalid file type')
        else:
            validation_score += 20

        # Check image quality for images
        if document.file.content_type.startswith('image/'):
            quality_score = self._check_image_quality(document.file)
            validation_score += quality_score
        else:
            validation_score += 30

        # Update document status
        document.validation_score = validation_score
        document.issues = issues
        document.status = 'validated' if validation_score >= 50 else 'rejected'
        document.save()

        return {
            'score': validation_score,
            'issues': issues,
            'status': document.status,
        }

    def _check_image_quality(self, file):
        """Check image quality and clarity"""
        # Basic image quality checks
        # This would typically use PIL or OpenCV for actual analysis
        # For now, return a default score
        return 30

    def verify_bank_account(self, kyc_id, account_number, bank_name,
                            account_type):
        """Verify bank account details"""
        try:
            kyc_verification = KYCVerification.objects.get(id=kyc_id)

            # Create bank account record
            bank_account = BankAccount.objects.create(
                verification=kyc_verification,
                account_number=account_number,
                bank_name=bank_name,
                account_type=account_type,
                status='pending',
            )

            # Perform bank verification
            verification_result = self._verify_bank_details(bank_account)

            return {
                'success': True,
                'account_id': str(bank_account.id),
                'verification_result': verification_result,
            }

        except KYCVerification.DoesNotExist:
            return {
                'success': False,
                'error': 'KYC verification not found',
            }

    def _verify_bank_details(self, bank_account):
        """Verify bank account details"""
        verification_score = 0
        issues = []

        # Check account number format
        if len(bank_account.account_number) < 8:
            issues.append('Account number too short')
        else:
            verification_score += 30

        # Check bank name validity
        if bank_account.bank_name.strip():
            verification_score += 20
        else:
            issues.append('Bank name is required')

        # Additional verification logic would go here
        # For now, return a default score
        verification_score += 50

        # Update bank account status
        bank_account.verification_score = verification_score
        bank_account.issues = issues
        bank_account.status = ('verified' if verification_score >= 70
                               else 'rejected')
        bank_account.save()

        return {
            'score': verification_score,
            'issues': issues,
            'status': bank_account.status,
        }

    def run_compliance_check(self, kyc_id):
        """Run comprehensive compliance check"""
        try:
            kyc_verification = KYCVerification.objects.get(id=kyc_id)

            # Create compliance check record
            compliance_check = ComplianceCheck.objects.create(
                verification=kyc_verification,
                status='in_progress',
            )

            # Perform various checks
            check_results = self._perform_compliance_checks(kyc_verification)

            # Calculate overall score
            overall_score = self._calculate_compliance_score(check_results)

            # Update compliance check
            compliance_check.overall_score = overall_score
            compliance_check.check_results = check_results
            compliance_check.status = 'completed'
            compliance_check.save()

            # Update KYC verification status
            kyc_verification.overall_score = overall_score
            kyc_verification.status = (
                'approved' if overall_score >= self.verification_threshold
                else 'rejected'
            )
            kyc_verification.save()

            return {
                'success': True,
                'overall_score': overall_score,
                'status': kyc_verification.status,
                'check_results': check_results,
            }

        except KYCVerification.DoesNotExist:
            return {
                'success': False,
                'error': 'KYC verification not found',
            }

    def _perform_compliance_checks(self, kyc_verification):
        """Perform various compliance checks"""
        check_results = {}

        # Document verification check
        document_score = self._check_document_completeness(kyc_verification)
        check_results['document_completeness'] = document_score

        # Bank account verification check
        bank_score = self._check_bank_verification(kyc_verification)
        check_results['bank_verification'] = bank_score

        # Risk assessment check
        risk_score = self._assess_risk_level(kyc_verification)
        check_results['risk_assessment'] = risk_score

        return check_results

    def _check_document_completeness(self, kyc_verification):
        """Check if all required documents are uploaded and valid"""
        documents = KYCDocument.objects.filter(verification=kyc_verification)
        required_docs = kyc_verification.get_required_documents()

        score = 0
        issues = []

        for doc_type in required_docs:
            doc = documents.filter(document_type=doc_type).first()
            if doc and doc.status == 'validated':
                score += 25
            else:
                issues.append(f'Missing or invalid {doc_type}')

        return {
            'score': score,
            'issues': issues,
            'max_score': len(required_docs) * 25,
        }

    def _check_bank_verification(self, kyc_verification):
        """Check bank account verification status"""
        bank_accounts = BankAccount.objects.filter(
            verification=kyc_verification)

        if bank_accounts.exists():
            account = bank_accounts.first()
            return {
                'score': account.verification_score,
                'issues': account.issues,
                'status': account.status,
            }
        else:
            return {
                'score': 0,
                'issues': ['No bank account provided'],
                'status': 'missing',
            }

    def _assess_risk_level(self, kyc_verification):
        """Assess risk level of the merchant"""
        # Basic risk assessment logic
        risk_score = 50  # Default medium risk

        # Adjust based on various factors
        if kyc_verification.merchant.business_age > 365:  # More than 1 year
            risk_score += 20

        # Additional risk assessment logic would go here
        # For now, return a default score

        return {
            'score': risk_score,
            'risk_level': 'medium' if risk_score < 70 else 'low',
        }

    def _calculate_compliance_score(self, check_results):
        """Calculate overall compliance score"""
        total_score = 0
        max_score = 0

        # Document completeness (40% weight)
        doc_score = check_results.get('document_completeness', {})
        doc_weight = 0.4
        total_score += doc_score.get('score', 0) * doc_weight
        max_score += 100 * doc_weight

        # Bank verification (30% weight)
        bank_score = check_results.get('bank_verification', {})
        bank_weight = 0.3
        total_score += bank_score.get('score', 0) * bank_weight
        max_score += 100 * bank_weight

        # Risk assessment (30% weight)
        risk_score = check_results.get('risk_assessment', {})
        risk_weight = 0.3
        total_score += risk_score.get('score', 0) * risk_weight
        max_score += 100 * risk_weight

        return int((total_score / max_score) * 100) if max_score > 0 else 0

    def get_kyc_status(self, kyc_id):
        """Get current KYC verification status"""
        try:
            kyc_verification = KYCVerification.objects.get(id=kyc_id)

            return {
                'success': True,
                'status': kyc_verification.status,
                'overall_score': kyc_verification.overall_score,
                'verification_level': kyc_verification.verification_level,
                'created_at': kyc_verification.created_at,
                'updated_at': kyc_verification.updated_at,
            }

        except KYCVerification.DoesNotExist:
            return {
                'success': False,
                'error': 'KYC verification not found',
            }

    def get_required_documents(self, verification_level):
        """Get required documents for verification level"""
        document_requirements = {
            'basic': ['identity_document', 'proof_of_address'],
            'standard': ['identity_document', 'proof_of_address',
                         'business_license'],
            'enhanced': [
                'identity_document', 'proof_of_address', 'business_license',
                'financial_statements', 'tax_clearance'
            ],
        }

        return document_requirements.get(verification_level, [])

    def expire_kyc_verification(self, kyc_id):
        """Expire KYC verification"""
        try:
            kyc_verification = KYCVerification.objects.get(id=kyc_id)
            kyc_verification.status = 'expired'
            kyc_verification.save()

            return {
                'success': True,
                'status': 'expired',
            }

        except KYCVerification.DoesNotExist:
            return {
                'success': False,
                'error': 'KYC verification not found',
            }

    def renew_kyc_verification(self, kyc_id, verification_level=None):
        """Renew KYC verification"""
        try:
            kyc_verification = KYCVerification.objects.get(id=kyc_id)

            # Create new verification record
            new_verification = KYCVerification.objects.create(
                merchant=kyc_verification.merchant,
                verification_level=(verification_level or
                                    kyc_verification.verification_level),
                status='pending',
                overall_score=0,
                previous_verification=kyc_verification,
            )

            return {
                'success': True,
                'new_kyc_id': str(new_verification.id),
                'verification_level': new_verification.verification_level,
                'status': new_verification.status,
            }

        except KYCVerification.DoesNotExist:
            return {
                'success': False,
                'error': 'KYC verification not found',
            }
