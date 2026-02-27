"""
Insurance API views for micro-insurance services
"""
from rest_framework import status, permissions
from rest_framework.decorators import api_view, permission_classes, parser_classes
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from django.contrib.auth.decorators import login_required
from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_exempt
from .services.insurance_service import InsuranceService
from .models_insurance import InsurancePolicy, InsuranceClaim, InsuranceRiskAssessment, InsurancePremium
from .models import MerchantProfile


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def calculate_premium(request):
    """Calculate insurance premium"""
    try:
        merchant_id = request.data.get('merchant_id')
        coverage_amount = float(request.data.get('coverage_amount', 0))
        policy_type = request.data.get('policy_type', 'basic')
        risk_score = int(request.data.get('risk_score', 50))
        
        if not merchant_id or coverage_amount <= 0:
            return Response({
                'success': False,
                'error': 'Merchant ID and coverage amount are required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        insurance_service = InsuranceService()
        result = insurance_service.calculate_premium(merchant_id, coverage_amount, policy_type, risk_score)
        
        if result['success']:
            return Response(result, status=status.HTTP_200_OK)
        else:
            return Response(result, status=status.HTTP_400_BAD_REQUEST)
            
    except (ValueError, TypeError) as e:
        return Response({
            'success': False,
            'error': 'Invalid numeric values provided'
        }, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        return Response({
            'success': False,
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def assess_risk(request):
    """Perform risk assessment for insurance"""
    try:
        merchant_id = request.data.get('merchant_id')
        
        if not merchant_id:
            return Response({
                'success': False,
                'error': 'Merchant ID is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        insurance_service = InsuranceService()
        result = insurance_service.assess_risk(merchant_id)
        
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
def create_insurance_policy(request):
    """Create new insurance policy"""
    try:
        merchant_id = request.data.get('merchant_id')
        coverage_amount = float(request.data.get('coverage_amount', 0))
        policy_type = request.data.get('policy_type', 'basic')
        start_date = request.data.get('start_date')
        end_date = request.data.get('end_date')
        
        if not merchant_id or coverage_amount <= 0:
            return Response({
                'success': False,
                'error': 'Merchant ID and coverage amount are required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        insurance_service = InsuranceService()
        result = insurance_service.create_insurance_policy(
            merchant_id, coverage_amount, policy_type, start_date, end_date
        )
        
        if result['success']:
            return Response(result, status=status.HTTP_201_CREATED)
        else:
            return Response(result, status=status.HTTP_400_BAD_REQUEST)
            
    except (ValueError, TypeError) as e:
        return Response({
            'success': False,
            'error': 'Invalid numeric values provided'
        }, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        return Response({
            'success': False,
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def submit_claim(request):
    """Submit insurance claim"""
    try:
        policy_id = request.data.get('policy_id')
        claim_type = request.data.get('claim_type')
        description = request.data.get('description')
        estimated_loss = float(request.data.get('estimated_loss', 0))
        incident_date = request.data.get('incident_date')
        incident_location = request.data.get('incident_location', '')
        police_report_filed = request.data.get('police_report_filed', False)
        police_report_number = request.data.get('police_report_number', '')
        
        if not all([policy_id, claim_type, description, estimated_loss > 0, incident_date]):
            return Response({
                'success': False,
                'error': 'All required fields must be provided'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        insurance_service = InsuranceService()
        result = insurance_service.submit_claim(
            policy_id, claim_type, description, estimated_loss,
            incident_date, incident_location, police_report_filed, police_report_number
        )
        
        if result['success']:
            return Response(result, status=status.HTTP_201_CREATED)
        else:
            return Response(result, status=status.HTTP_400_BAD_REQUEST)
            
    except (ValueError, TypeError) as e:
        return Response({
            'success': False,
            'error': 'Invalid numeric values provided'
        }, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        return Response({
            'success': False,
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def process_claim(request):
    """Process insurance claim"""
    try:
        claim_id = request.data.get('claim_id')
        approved_amount = request.data.get('approved_amount')
        status = request.data.get('status', 'approved')
        settlement_notes = request.data.get('settlement_notes', '')
        
        if not claim_id:
            return Response({
                'success': False,
                'error': 'Claim ID is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Convert approved_amount to float if provided
        if approved_amount is not None:
            approved_amount = float(approved_amount)
        
        insurance_service = InsuranceService()
        result = insurance_service.process_claim(claim_id, approved_amount, status, settlement_notes)
        
        if result['success']:
            return Response(result, status=status.HTTP_200_OK)
        else:
            return Response(result, status=status.HTTP_400_BAD_REQUEST)
            
    except (ValueError, TypeError) as e:
        return Response({
            'success': False,
            'error': 'Invalid numeric values provided'
        }, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        return Response({
            'success': False,
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def get_policy_details(request):
    """Get insurance policy details"""
    try:
        policy_id = request.GET.get('policy_id')
        
        if not policy_id:
            return Response({
                'success': False,
                'error': 'Policy ID is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        insurance_service = InsuranceService()
        result = insurance_service.get_policy_details(policy_id)
        
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
def get_merchant_policies(request):
    """Get all insurance policies for a merchant"""
    try:
        merchant_id = request.GET.get('merchant_id')
        
        if not merchant_id:
            return Response({
                'success': False,
                'error': 'Merchant ID is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        insurance_service = InsuranceService()
        result = insurance_service.get_merchant_policies(merchant_id)
        
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
def get_policy_claims(request):
    """Get all claims for a policy"""
    try:
        policy_id = request.GET.get('policy_id')
        
        if not policy_id:
            return Response({
                'success': False,
                'error': 'Policy ID is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        policy = InsurancePolicy.objects.get(id=policy_id)
        claims = InsuranceClaim.objects.filter(policy=policy)
        
        claims_data = []
        for claim in claims:
            claims_data.append({
                'claim_id': str(claim.id),
                'claim_number': claim.claim_number,
                'claim_type': claim.claim_type,
                'status': claim.status,
                'description': claim.description,
                'estimated_loss': float(claim.estimated_loss),
                'approved_amount': float(claim.approved_amount) if claim.approved_amount else None,
                'incident_date': claim.incident_date.isoformat(),
                'incident_location': claim.incident_location,
                'police_report_filed': claim.police_report_filed,
                'police_report_number': claim.police_report_number,
                'submitted_at': claim.submitted_at.isoformat(),
                'reviewed_at': claim.reviewed_at.isoformat() if claim.reviewed_at else None,
                'approved_at': claim.approved_at.isoformat() if claim.approved_at else None,
                'paid_at': claim.paid_at.isoformat() if claim.paid_at else None,
                'settlement_notes': claim.settlement_notes
            })
        
        return Response({
            'success': True,
            'claims': claims_data,
            'count': len(claims_data),
            'policy_id': policy_id
        }, status=status.HTTP_200_OK)
        
    except InsurancePolicy.DoesNotExist:
        return Response({
            'success': False,
            'error': 'Policy not found'
        }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({
            'success': False,
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def get_policy_premiums(request):
    """Get premium schedule for a policy"""
    try:
        policy_id = request.GET.get('policy_id')
        
        if not policy_id:
            return Response({
                'success': False,
                'error': 'Policy ID is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        policy = InsurancePolicy.objects.get(id=policy_id)
        premiums = InsurancePremium.objects.filter(policy=policy)
        
        premiums_data = []
        for premium in premiums:
            premiums_data.append({
                'premium_id': str(premium.id),
                'premium_number': premium.premium_number,
                'amount': float(premium.amount),
                'due_date': premium.due_date.isoformat(),
                'payment_status': premium.payment_status,
                'paid_amount': float(premium.paid_amount) if premium.paid_amount else None,
                'paid_date': premium.paid_date.isoformat() if premium.paid_date else None,
                'payment_method': premium.payment_method,
                'payment_reference': premium.payment_reference
            })
        
        return Response({
            'success': True,
            'premiums': premiums_data,
            'count': len(premiums_data),
            'policy_id': policy_id
        }, status=status.HTTP_200_OK)
        
    except InsurancePolicy.DoesNotExist:
        return Response({
            'success': False,
            'error': 'Policy not found'
        }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({
            'success': False,
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def get_merchant_risk_assessment(request):
    """Get risk assessment for a merchant"""
    try:
        merchant_id = request.GET.get('merchant_id')
        
        if not merchant_id:
            return Response({
                'success': False,
                'error': 'Merchant ID is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        merchant = MerchantProfile.objects.get(id=merchant_id)
        risk_assessments = InsuranceRiskAssessment.objects.filter(merchant=merchant)
        
        if not risk_assessments.exists():
            # Perform new risk assessment
            insurance_service = InsuranceService()
            result = insurance_service.assess_risk(merchant_id)
            return Response(result, status=status.HTTP_200_OK)
        
        # Get latest assessment
        latest_assessment = risk_assessments.first()
        
        return Response({
            'success': True,
            'assessment_id': str(latest_assessment.id),
            'risk_level': latest_assessment.risk_level,
            'risk_score': latest_assessment.risk_score,
            'location_risk': latest_assessment.location_risk,
            'inventory_value': float(latest_assessment.inventory_value),
            'security_measures': latest_assessment.security_measures,
            'previous_claims': latest_assessment.previous_claims,
            'assessment_date': latest_assessment.assessment_date.isoformat(),
            'next_assessment_due': latest_assessment.next_assessment_due.isoformat() if latest_assessment.next_assessment_due else None,
            'assessment_notes': latest_assessment.assessment_notes
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
