"""
Insurance API views for micro-insurance services
"""
from rest_framework import status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from .services.insurance_service import InsuranceService


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def calculate_premium(request):
    """Calculate insurance premium"""
    try:
        merchant_id = request.data.get('merchant_id')
        policy_type = request.data.get('policy_type')
        coverage_amount = request.data.get('coverage_amount')
        deductible_amount = request.data.get('deductible_amount')

        if not all([merchant_id, policy_type, coverage_amount]):
            return Response({
                'error': 'Missing required fields',
                'required': ['merchant_id', 'policy_type', 'coverage_amount']
            }, status=status.HTTP_400_BAD_REQUEST)

        insurance_service = InsuranceService()
        result = insurance_service.calculate_premium(
            merchant_id, policy_type, coverage_amount, deductible_amount
        )

        return Response(result)

    except Exception as e:
        return Response({
            'error': str(e),
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def assess_risk(request):
    """Assess insurance risk"""
    try:
        merchant_id = request.data.get('merchant_id')
        policy_type = request.data.get('policy_type')

        if not all([merchant_id, policy_type]):
            return Response({
                'error': 'Missing required fields',
                'required': ['merchant_id', 'policy_type']
            }, status=status.HTTP_400_BAD_REQUEST)

        insurance_service = InsuranceService()
        result = insurance_service.assess_risk(merchant_id, policy_type)

        return Response(result)

    except Exception as e:
        return Response({
            'error': str(e),
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def create_insurance_policy(request):
    """Create insurance policy"""
    try:
        merchant_id = request.data.get('merchant_id')
        policy_type = request.data.get('policy_type')
        coverage_amount = request.data.get('coverage_amount')
        deductible_amount = request.data.get('deductible_amount')
        premium_amount = request.data.get('premium_amount')

        if not all([merchant_id, policy_type, coverage_amount]):
            return Response({
                'error': 'Missing required fields',
                'required': ['merchant_id', 'policy_type', 'coverage_amount']
            }, status=status.HTTP_400_BAD_REQUEST)

        insurance_service = InsuranceService()
        result = insurance_service.create_policy(
            merchant_id, policy_type, coverage_amount,
            deductible_amount, premium_amount
        )

        return Response(result)

    except Exception as e:
        return Response({
            'error': str(e),
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def submit_claim(request):
    """Submit insurance claim"""
    try:
        policy_id = request.data.get('policy_id')
        claim_type = request.data.get('claim_type')
        description = request.data.get('description')
        estimated_loss = request.data.get('estimated_loss')
        incident_date = request.data.get('incident_date')
        incident_location = request.data.get('incident_location')

        if not all([policy_id, claim_type, description, estimated_loss]):
            return Response({
                'error': 'Missing required fields',
                'required': ['policy_id', 'claim_type', 'description',
                           'estimated_loss']
                           }, status=status.HTTP_400_BAD_REQUEST)

        insurance_service = InsuranceService()
        result = insurance_service.submit_claim(
            policy_id, claim_type, description, estimated_loss,
            incident_date, incident_location
        )

        return Response(result)

    except Exception as e:
        return Response({
            'error': str(e),
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def process_claim(request):
    """Process insurance claim"""
    try:
        claim_id = request.data.get('claim_id')
        action = request.data.get('action')  # 'approve', 'reject',
                                           # 'request_info'
    # # notes = request.data.get('notes', '')        if not all([claim_id, action]):
            return Response({
                'error': 'Missing required fields',
                'required': ['claim_id', 'action']
            }, status=status.HTTP_400_BAD_REQUEST)

        insurance_service = InsuranceService()
        result = insurance_service.process_claim(claim_id, action, notes)

        return Response(result)

    except Exception as e:
        return Response({
            'error': str(e),
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def get_policy_details(request, policy_id):
    """Get insurance policy details"""
    try:
        insurance_service = InsuranceService()
        result = insurance_service.get_policy_details(policy_id)

        return Response(result)

    except Exception as e:
        return Response({
            'error': str(e),
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def get_merchant_policies(request, merchant_id):
    """Get merchant's insurance policies"""
    try:
        insurance_service = InsuranceService()
        result = insurance_service.get_merchant_policies(merchant_id)

        return Response(result)

    except Exception as e:
        return Response({
            'error': str(e),
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def get_policy_claims(request, policy_id):
    """Get policy claims"""
    try:
        insurance_service = InsuranceService()
        result = insurance_service.get_policy_claims(policy_id)

        return Response(result)

    except Exception as e:
        return Response({
            'error': str(e),
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def get_policy_premiums(request, policy_id):
    """Get policy premiums"""
    try:
        insurance_service = InsuranceService()
        result = insurance_service.get_policy_premiums(policy_id)

        return Response(result)

    except Exception as e:
        return Response({
            'error': str(e),
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def get_merchant_risk_assessment(request, merchant_id):
    """Get merchant risk assessment"""
    try:
        insurance_service = InsuranceService()
        result = insurance_service.get_merchant_risk_assessment(merchant_id)

        return Response(result)

    except Exception as e:
        return Response({
            'error': str(e),
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
