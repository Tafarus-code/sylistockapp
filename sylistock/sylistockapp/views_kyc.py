"""
KYC (Know Your Customer) API views for bank compliance
"""
from rest_framework import status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from .services.kyc_service import KYCService


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def initiate_kyc(request):
    """Initiate KYC verification process"""
    try:
        merchant_id = request.data.get('merchant_id')
        verification_level = request.data.get('verification_level', 'basic')

        if not merchant_id:
            return Response({
                'error': 'merchant_id is required',
            }, status=status.HTTP_400_BAD_REQUEST)

        kyc_service = KYCService()
        result = kyc_service.initiate_kyc_process(merchant_id,
                                                     verification_level)
    merchant_id = request.data.get('merchant_id')

    except Exception as e:
        return Response({
            'error': str(e),
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def upload_kyc_document(request):
    """Upload KYC document"""
    try:
        kyc_id = request.data.get('kyc_id')
        document_type = request.data.get('document_type')
        file_data = request.FILES.get('file')

        if not all([kyc_id, document_type, file_data]):
            return Response({
                'error': 'Missing required fields',
                'required': ['kyc_id', 'document_type', 'file']
            }, status=status.HTTP_400_BAD_REQUEST)

        kyc_service = KYCService()
        result = kyc_service.upload_document(kyc_id, document_type,
                                                 file_data.read(),
                                                 file_data.name)
                                                         return Response(result)

    except Exception as e:
        return Response({
            'error': str(e),
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def add_bank_account(request):
    """Add bank account for KYC"""
    try:
        kyc_id = request.data.get('kyc_id')
        account_number = request.data.get('account_number')
        bank_name = request.data.get('bank_name')
        account_type = request.data.get('account_type')

        if not all([kyc_id, account_number, bank_name, account_type]):
            return Response({
                'error': 'Missing required fields',
                'required': ['kyc_id', 'account_number', 'bank_name',
                           'account_type']
                           }, status=status.HTTP_400_BAD_REQUEST)

        kyc_service = KYCService()
        result = kyc_service.verify_bank_account(kyc_id, account_number,
                                                  bank_name, account_type)
                                                          return Response(result)

    except Exception as e:
        return Response({
            'error': str(e),
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def perform_compliance_checks(request):
    """Perform comprehensive compliance checks"""
    try:
        kyc_id = request.data.get('kyc_id')

        if not kyc_id:
            return Response({
                'error': 'kyc_id is required',
            }, status=status.HTTP_400_BAD_REQUEST)

        kyc_service = KYCService()
        result = kyc_service.run_compliance_check(kyc_id)

        return Response(result)

    except Exception as e:
        return Response({
            'error': str(e),
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def evaluate_kyc_application(request):
    """Evaluate KYC application"""
    try:
        kyc_id = request.data.get('kyc_id')

        if not kyc_id:
            return Response({
                'error': 'kyc_id is required',
            }, status=status.HTTP_400_BAD_REQUEST)

        kyc_service = KYCService()
        result = kyc_service.run_compliance_check(kyc_id)

        return Response(result)

    except Exception as e:
        return Response({
            'error': str(e),
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def get_kyc_status(request, kyc_id):
    """Get KYC verification status"""
    try:
        kyc_service = KYCService()
        result = kyc_service.get_kyc_status(kyc_id)

        return Response(result)

    except Exception as e:
        return Response({
            'error': str(e),
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def get_kyc_documents(request, kyc_id):
    """Get KYC documents"""
    try:
        kyc_service = KYCService()
        result = kyc_service.get_kyc_documents(kyc_id)

        return Response(result)

    except Exception as e:
        return Response({
            'error': str(e),
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def get_bank_accounts(request, kyc_id):
    """Get bank accounts"""
    try:
        kyc_service = KYCService()
        result = kyc_service.get_bank_accounts(kyc_id)

        return Response(result)

    except Exception as e:
        return Response({
            'error': str(e),
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def get_compliance_checks(request, kyc_id):
    """Get compliance checks"""
    try:
        kyc_service = KYCService()
        result = kyc_service.get_compliance_checks(kyc_id)

        return Response(result)

    except Exception as e:
        return Response({
            'error': str(e),
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def expire_kyc_verification(request):
    """Expire KYC verification"""
    try:
        kyc_id = request.data.get('kyc_id')

        if not kyc_id:
            return Response({
                'error': 'kyc_id is required',
            }, status=status.HTTP_400_BAD_REQUEST)

        kyc_service = KYCService()
        result = kyc_service.expire_kyc_verification(kyc_id)

        return Response(result)

    except Exception as e:
        return Response({
            'error': str(e),
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def renew_kyc_verification(request):
    """Renew KYC verification"""
    try:
        kyc_id = request.data.get('kyc_id')
        verification_level = request.data.get('verification_level')

        if not kyc_id:
            return Response({
                'error': 'kyc_id is required',
            }, status=status.HTTP_400_BAD_REQUEST)

        kyc_service = KYCService()
        result = kyc_service.renew_kyc_verification(kyc_id,
                                                       verification_level)
                                                               return Response(result)

    except Exception as e:
        return Response({
            'error': str(e),
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
