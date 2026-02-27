"""
KYC (Know Your Customer) Service for bank compliance
"""
import os
import json
import uuid
from datetime import datetime, timedelta
from django.utils import timezone
from django.conf import settings
from django.core.files.base import ContentFile
from django.contrib.auth.models import User
from ..models_kyc import KYCDocument, KYCVerification, BankAccount, ComplianceCheck
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
                'message': f'KYC process initiated for {verification_level} verification'
            }
            
        except MerchantProfile.DoesNotExist:
            return {
                'success': False,
                'error': 'Merchant not found'
            }
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }
    
    def upload_kyc_document(self, merchant_id, document_type, document_number=None, document_image=None, expiry_date=None, issued_date=None):
        """Upload KYC document for verification"""
        try:
            merchant = MerchantProfile.objects.get(id=merchant_id)
            
            # Create KYC document
            kyc_doc = KYCDocument.objects.create(
                merchant=merchant,
                document_type=document_type,
                document_number=document_number or '',
                document_image=document_image,
                expiry_date=expiry_date,
                issued_date=issued_date,
                verification_status='pending'
            )
            
            # Trigger automated verification if available
            if document_image:
                self._perform_automated_verification(kyc_doc)
            
            return {
                'success': True,
                'document_id': str(kyc_doc.id),
                'document_type': document_type,
                'verification_status': kyc_doc.verification_status,
                'message': 'Document uploaded successfully'
            }
            
        except MerchantProfile.DoesNotExist:
            return {
                'success': False,
                'error': 'Merchant not found'
            }
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }
    
    def _perform_automated_verification(self, kyc_document):
        """Perform automated document verification"""
        try:
            # Simulate automated verification (in production, integrate with actual verification APIs)
            verification_score = 85  # Simulated score
            
            if verification_score >= 80:
                kyc_document.verification_status = 'verified'
                kyc_document.verified_at = timezone.now()
                kyc_document.verification_notes = 'Automated verification passed'
            else:
                kyc_document.verification_status = 'pending'
                kyc_document.verification_notes = 'Manual review required'
            
            kyc_document.save()
            
        except Exception as e:
            kyc_document.verification_status = 'pending'
            kyc_document.verification_notes = f'Verification error: {str(e)}'
            kyc_document.save()
    
    def add_bank_account(self, merchant_id, bank_name, bank_code, account_number, account_name, account_type='business', is_primary=False):
        """Add bank account information for merchant"""
        try:
            merchant = MerchantProfile.objects.get(id=merchant_id)
            
            # If setting as primary, unset other primary accounts
            if is_primary:
                BankAccount.objects.filter(merchant=merchant, is_primary=True).update(is_primary=False)
            
            # Create bank account
            bank_account = BankAccount.objects.create(
                merchant=merchant,
                bank_name=bank_name,
                bank_code=bank_code,
                account_number=account_number,
                account_name=account_name,
                account_type=account_type,
                is_primary=is_primary
            )
            
            return {
                'success': True,
                'account_id': str(bank_account.id),
                'bank_name': bank_name,
                'account_number': account_number[-4:],  # Only show last 4 digits
                'is_primary': is_primary,
                'message': 'Bank account added successfully'
            }
            
        except MerchantProfile.DoesNotExist:
            return {
                'success': False,
                'error': 'Merchant not found'
            }
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }
    
    def perform_compliance_checks(self, merchant_id):
        """Perform all compliance checks for a merchant"""
        try:
            merchant = MerchantProfile.objects.get(id=merchant_id)
            results = {}
            
            # Perform different types of compliance checks
            check_types = ['sanctions', 'pep', 'aml', 'fraud', 'credit']
            
            for check_type in check_types:
                result = self._perform_single_compliance_check(merchant, check_type)
                results[check_type] = result
            
            # Calculate overall compliance score
            total_score = sum(check['risk_score'] for check in results.values())
            overall_score = total_score / len(check_types)
            
            return {
                'success': True,
                'compliance_checks': results,
                'overall_score': round(overall_score, 2),
                'message': 'Compliance checks completed'
            }
            
        except MerchantProfile.DoesNotExist:
            return {
                'success': False,
                'error': 'Merchant not found'
            }
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }
    
    def _perform_single_compliance_check(self, merchant, check_type):
        """Perform a single compliance check"""
        try:
            # Simulate compliance check (in production, integrate with actual compliance APIs)
            risk_scores = {
                'sanctions': 15,  # Low risk
                'pep': 25,        # Low-medium risk
                'aml': 20,        # Low risk
                'fraud': 30,      # Medium risk
                'credit': 35,     # Medium risk
            }
            
            base_score = risk_scores.get(check_type, 50)
            
            # Add some randomness for simulation
            import random
            final_score = base_score + random.randint(-10, 10)
            final_score = max(0, min(100, final_score))
            
            # Determine status based on score
            if final_score < 30:
                status = 'passed'
            elif final_score < 60:
                status = 'flagged'
            else:
                status = 'failed'
            
            # Create compliance check record
            compliance_check = ComplianceCheck.objects.create(
                merchant=merchant,
                check_type=check_type,
                status=status,
                risk_score=final_score,
                check_result={
                    'score': final_score,
                    'details': f'Automated {check_type} check completed',
                    'timestamp': timezone.now().isoformat()
                },
                next_check_due=timezone.now() + timedelta(days=30)
            )
            
            return {
                'check_id': str(compliance_check.id),
                'check_type': check_type,
                'status': status,
                'risk_score': final_score,
                'next_check_due': compliance_check.next_check_due.isoformat()
            }
            
        except Exception as e:
            return {
                'check_type': check_type,
                'status': 'failed',
                'error': str(e)
            }
    
    def evaluate_kyc_application(self, merchant_id):
        """Evaluate complete KYC application and determine approval status"""
        try:
            merchant = MerchantProfile.objects.get(id=merchant_id)
            kyc_verification = merchant.kyc_verification
            
            if not kyc_verification:
                return {
                    'success': False,
                    'error': 'KYC verification not found'
                }
            
            # Check document verification status
            required_documents = kyc_verification.get_required_documents()
            uploaded_documents = KYCDocument.objects.filter(
                merchant=merchant,
                document_type__in=required_documents,
                verification_status='verified'
            )
            
            document_score = (len(uploaded_documents) / len(required_documents)) * 100
            
            # Get compliance checks
            compliance_checks = ComplianceCheck.objects.filter(merchant=merchant)
            if compliance_checks.exists():
                compliance_score = sum(check.risk_score for check in compliance_checks) / len(compliance_checks)
            else:
                compliance_score = 50  # Default medium risk
            
            # Check bank account verification
            bank_accounts = BankAccount.objects.filter(merchant=merchant, is_verified=True)
            bank_score = 100 if bank_accounts.exists() else 50
            
            # Calculate overall score
            overall_score = (document_score * 0.4) + (compliance_score * 0.4) + (bank_score * 0.2)
            overall_score = round(overall_score, 2)
            
            # Determine status
            if overall_score >= self.verification_threshold:
                status = 'approved'
                kyc_verification.approved_at = timezone.now()
                kyc_verification.expires_at = timezone.now() + timedelta(days=365)
            else:
                status = 'rejected'
            
            kyc_verification.overall_score = overall_score
            kyc_verification.status = status
            kyc_verification.save()
            
            return {
                'success': True,
                'status': status,
                'overall_score': overall_score,
                'document_score': document_score,
                'compliance_score': compliance_score,
                'bank_score': bank_score,
                'threshold': self.verification_threshold,
                'message': f'KYC application {status} with score {overall_score}'
            }
            
        except MerchantProfile.DoesNotExist:
            return {
                'success': False,
                'error': 'Merchant not found'
            }
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }
    
    def get_kyc_status(self, merchant_id):
        """Get current KYC status for a merchant"""
        try:
            merchant = MerchantProfile.objects.get(id=merchant_id)
            kyc_verification = merchant.kyc_verification
            
            if not kyc_verification:
                return {
                    'success': False,
                    'error': 'KYC verification not found'
                }
            
            # Get documents
            documents = KYCDocument.objects.filter(merchant=merchant)
            document_status = {}
            for doc in documents:
                document_status[doc.document_type] = {
                    'status': doc.verification_status,
                    'uploaded_at': doc.created_at.isoformat(),
                    'verified_at': doc.verified_at.isoformat() if doc.verified_at else None
                }
            
            # Get compliance checks
            compliance_checks = ComplianceCheck.objects.filter(merchant=merchant)
            compliance_status = []
            for check in compliance_checks:
                compliance_status.append({
                    'type': check.check_type,
                    'status': check.status,
                    'risk_score': check.risk_score,
                    'performed_at': check.performed_at.isoformat()
                })
            
            # Get bank accounts
            bank_accounts = BankAccount.objects.filter(merchant=merchant)
            bank_status = []
            for account in bank_accounts:
                bank_status.append({
                    'bank_name': account.bank_name,
                    'account_number': account.account_number[-4:],
                    'is_primary': account.is_primary,
                    'is_verified': account.is_verified
                })
            
            return {
                'success': True,
                'kyc_id': str(kyc_verification.id),
                'verification_level': kyc_verification.verification_level,
                'status': kyc_verification.status,
                'overall_score': kyc_verification.overall_score,
                'approved_at': kyc_verification.approved_at.isoformat() if kyc_verification.approved_at else None,
                'expires_at': kyc_verification.expires_at.isoformat() if kyc_verification.expires_at else None,
                'documents': document_status,
                'compliance_checks': compliance_status,
                'bank_accounts': bank_status,
                'message': 'KYC status retrieved successfully'
            }
            
        except MerchantProfile.DoesNotExist:
            return {
                'success': False,
                'error': 'Merchant not found'
            }
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }
