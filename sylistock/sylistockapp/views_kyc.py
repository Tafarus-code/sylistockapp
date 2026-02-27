"""
KYC (Know Your Customer) API views for bank compliance
"""
from rest_framework import status, permissions
from rest_framework.decorators import api_view, permission_classes, parser_classes
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from django.contrib.auth.decorators import login_required
from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_exempt
from .services.kyc_service import KYCService
from .models_kyc import KYCDocument, KYCVerification, BankAccount, ComplianceCheck
from .models import MerchantProfile


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def initiate_kyc(request):
    """Initiate KYC verification process"""
    try:
        merchant_id = request.data.get('merchant_id')
        verification_level = request.data.get('verification_level', 'basic')
        
        if not merchant_id:
            return Response({
                'success': False,
                'error': 'Merchant ID is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        kyc_service = KYCService()
        result = kyc_service.initiate_kyc_process(merchant_id, verification_level)
        
        if result['success']:
            return Response(result, status=status.HTTP_201_CREATED)
        else:
            return Response(result, status=status.HTTP_400_BAD_REQUEST)
            
    except Exception as e:
        return Response({
            'success': False,
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
@parser_classes([MultiPartParser, FormParser])
def upload_kyc_document(request):
    """Upload KYC document for verification"""
    try:
        merchant_id = request.data.get('merchant_id')
        document_type = request.data.get('document_type')
        document_number = request.data.get('document_number', '')
        document_image = request.FILES.get('document_image')
        expiry_date = request.data.get('expiry_date')
        issued_date = request.data.get('issued_date')
        
        if not all([merchant_id, document_type]):
            return Response({
                'success': False,
                'error': 'Merchant ID and document type are required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        kyc_service = KYCService()
        result = kyc_service.upload_kyc_document(
            merchant_id=merchant_id,
            document_type=document_type,
            document_number=document_number,
            document_image=document_image,
            expiry_date=expiry_date,
            issued_date=issued_date
        )
        
        if result['success']:
            return Response(result, status=status.HTTP_201_CREATED)
        else:
            return Response(result, status=status.HTTP_400_BAD_REQUEST)
            
    except Exception as e:
        return Response({
            'success': False,
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def add_bank_account(request):
    """Add bank account information for merchant"""
    try:
        merchant_id = request.data.get('merchant_id')
        bank_name = request.data.get('bank_name')
        bank_code = request.data.get('bank_code')
        account_number = request.data.get('account_number')
        account_name = request.data.get('account_name')
        account_type = request.data.get('account_type', 'business')
        is_primary = request.data.get('is_primary', False)
        
        if not all([merchant_id, bank_name, bank_code, account_number, account_name]):
            return Response({
                'success': False,
                'error': 'All bank account fields are required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        kyc_service = KYCService()
        result = kyc_service.add_bank_account(
            merchant_id=merchant_id,
            bank_name=bank_name,
            bank_code=bank_code,
            account_number=account_number,
            account_name=account_name,
            account_type=account_type,
            is_primary=is_primary
        )
        
        if result['success']:
            return Response(result, status=status.HTTP_201_CREATED)
        else:
            return Response(result, status=status.HTTP_400_BAD_REQUEST)
            
    except Exception as e:
        return Response({
            'success': False,
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def perform_compliance_checks(request):
    """Perform compliance checks for a merchant"""
    try:
        merchant_id = request.data.get('merchant_id')
        
        if not merchant_id:
            return Response({
                'success': False,
                'error': 'Merchant ID is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        kyc_service = KYCService()
        result = kyc_service.perform_compliance_checks(merchant_id)
        
        if result['success']:
            return Response(result, status=status.HTTP_200_OK)
        else:
            return Response(result, status=status.HTTP_400_BAD_REQUEST)
            
    except Exception as e:
        return Response({
            'success': False,
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def evaluate_kyc_application(request):
    """Evaluate complete KYC application"""
    try:
        merchant_id = request.data.get('merchant_id')
        
        if not merchant_id:
            return Response({
                'success': False,
                'error': 'Merchant ID is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        kyc_service = KYCService()
        result = kyc_service.evaluate_kyc_application(merchant_id)
        
        if result['success']:
            return Response(result, status=status.HTTP_200_OK)
        else:
            return Response(result, status=status.HTTP_400_BAD_REQUEST)
            
    except Exception as e:
        return Response({
            'success': False,
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def get_kyc_status(request):
    """Get current KYC status for a merchant"""
    try:
        merchant_id = request.GET.get('merchant_id')
        
        if not merchant_id:
            return Response({
                'success': False,
                'error': 'Merchant ID is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        kyc_service = KYCService()
        result = kyc_service.get_kyc_status(merchant_id)
        
        if result['success']:
            return Response(result, status=status.HTTP_200_OK)
        else:
            return Response(result, status=status.HTTP_404_NOT_FOUND)
            
    except Exception as e:
        return Response({
            'success': False,
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def get_kyc_documents(request):
    """Get all KYC documents for a merchant"""
    try:
        merchant_id = request.GET.get('merchant_id')
        
        if not merchant_id:
            return Response({
                'success': False,
                'error': 'Merchant ID is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        merchant = MerchantProfile.objects.get(id=merchant_id)
        documents = KYCDocument.objects.filter(merchant=merchant)
        
        documents_data = []
        for doc in documents:
            documents_data.append({
                'id': str(doc.id),
                'document_type': doc.document_type,
                'document_number': doc.document_number,
                'verification_status': doc.verification_status,
                'verification_notes': doc.verification_notes,
                'expiry_date': doc.expiry_date.isoformat() if doc.expiry_date else None,
                'issued_date': doc.issued_date.isoformat() if doc.issued_date else None,
                'created_at': doc.created_at.isoformat(),
                'verified_at': doc.verified_at.isoformat() if doc.verified_at else None,
                'document_image_url': doc.document_image.url if doc.document_image else None
            })
        
        return Response({
            'success': True,
            'documents': documents_data,
            'count': len(documents_data)
        }, status=status.HTTP_200_OK)
        
    except MerchantProfile.DoesNotExist:
        return Response({
            'success': False,
            'error': 'Merchant not found'
        }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({
            'success': False,
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def get_bank_accounts(request):
    """Get all bank accounts for a merchant"""
    try:
        merchant_id = request.GET.get('merchant_id')
        
        if not merchant_id:
            return Response({
                'success': False,
                'error': 'Merchant ID is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        merchant = MerchantProfile.objects.get(id=merchant_id)
        accounts = BankAccount.objects.filter(merchant=merchant)
        
        accounts_data = []
        for account in accounts:
            accounts_data.append({
                'id': str(account.id),
                'bank_name': account.bank_name,
                'bank_code': account.bank_code,
                'account_number': account.account_number[-4:],  # Only show last 4 digits
                'account_name': account.account_name,
                'account_type': account.account_type,
                'is_primary': account.is_primary,
                'is_verified': account.is_verified,
                'verification_date': account.verification_date.isoformat() if account.verification_date else None,
                'created_at': account.created_at.isoformat()
            })
        
        return Response({
            'success': True,
            'accounts': accounts_data,
            'count': len(accounts_data)
        }, status=status.HTTP_200_OK)
        
    except MerchantProfile.DoesNotExist:
        return Response({
            'success': False,
            'error': 'Merchant not found'
        }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({
            'success': False,
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def get_compliance_checks(request):
    """Get compliance checks for a merchant"""
    try:
        merchant_id = request.GET.get('merchant_id')
        
        if not merchant_id:
            return Response({
                'success': False,
                'error': 'Merchant ID is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        merchant = MerchantProfile.objects.get(id=merchant_id)
        checks = ComplianceCheck.objects.filter(merchant=merchant)
        
        checks_data = []
        for check in checks:
            checks_data.append({
                'id': str(check.id),
                'check_type': check.check_type,
                'status': check.status,
                'risk_score': check.risk_score,
                'check_result': check.check_result,
                'recommendations': check.recommendations,
                'performed_at': check.performed_at.isoformat(),
                'next_check_due': check.next_check_due.isoformat() if check.next_check_due else None
            })
        
        return Response({
            'success': True,
            'compliance_checks': checks_data,
            'count': len(checks_data)
        }, status=status.HTTP_200_OK)
        
    except MerchantProfile.DoesNotExist:
        return Response({
            'success': False,
            'error': 'Merchant not found'
        }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({
            'success': False,
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
