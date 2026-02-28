"""
Micro-Insurance Service for inventory protection
"""
from datetime import datetime, timedelta
from django.utils import timezone
from django.db import transaction
from ..models_insurance import (
    InsurancePolicy, InsuranceClaim, InsuranceRiskAssessment,
    InsuranceCoverage, InsurancePremium
)
from ..models import MerchantProfile


class InsuranceService:
    """Micro-Insurance service for inventory protection"""

    def __init__(self):
        self.base_premium_rate = 0.02  # 2% of coverage amount
        self.risk_multiplier = {
            'low': 1.0,
            'medium': 1.5,
            'high': 2.0,
            'very_high': 3.0,
        }

    def calculate_premium(self, merchant_id, policy_type, coverage_amount,
                          deductible_amount=0):
        """Calculate insurance premium based on risk assessment"""
        try:
            merchant = MerchantProfile.objects.get(id=merchant_id)

            # Get risk assessment
            risk_assessment = self._get_latest_risk_assessment(merchant_id)
            risk_level = (risk_assessment.risk_level if risk_assessment
                          else 'medium')
            risk_multiplier = self.risk_multiplier.get(risk_level, 1.5)

            # Calculate base premium
            base_premium = coverage_amount * self.base_premium_rate

            # Apply risk multiplier
            risk_adjusted_premium = base_premium * risk_multiplier

            # Apply deductible discount
            if deductible_amount > 0:
                # 1% of deductible
                deductible_discount = deductible_amount * 0.01
                final_premium = max(
                    risk_adjusted_premium - deductible_discount,
                    coverage_amount * 0.001
                )  # Min 0.1%
            else:
                final_premium = risk_adjusted_premium

            return {
                'success': True,
                'base_premium': float(base_premium),
                'risk_adjusted_premium': float(risk_adjusted_premium),
                'final_premium': float(final_premium),
                'risk_level': risk_level,
                'risk_multiplier': risk_multiplier,
            }

        except MerchantProfile.DoesNotExist:
            return {
                'success': False,
                'error': 'Merchant not found',
            }

    def assess_risk(self, merchant_id, policy_type):
        """Assess insurance risk for merchant"""
        try:
            merchant = MerchantProfile.objects.get(id=merchant_id)

            # Create or update risk assessment
            risk_assessment, created = (
                InsuranceRiskAssessment.objects.get_or_create(
                merchant=merchant,
                defaults={
                    'risk_level': 'medium',
                    'risk_score': 50,
                    'location_risk': 50,
                    'inventory_value': 0,
                    'security_measures': {},
                    'previous_claims': 0,
                }
            )

            if not created:
                # Update existing assessment
                risk_score = self._calculate_risk_score(merchant)
                risk_assessment.risk_score = risk_score
                risk_assessment.risk_level = self._get_risk_level(risk_score)
                risk_assessment.save()

            return {
                'success': True,
                'risk_level': risk_assessment.risk_level,
                'risk_score': risk_assessment.risk_score,
                'assessment_date': risk_assessment.assessment_date,
            }

        except MerchantProfile.DoesNotExist:
            return {
                'success': False,
                'error': 'Merchant not found',
            }

    def create_policy(self, merchant_id, policy_type, coverage_amount,
                      deductible_amount, premium_amount):
        """Create new insurance policy"""
        try:
            with transaction.atomic():
                merchant = MerchantProfile.objects.get(id=merchant_id)

                # Generate policy number
                policy_number = self._generate_policy_number()

                # Create policy
                policy = InsurancePolicy.objects.create(
                    merchant=merchant,
                    policy_number=policy_number,
                    policy_type=policy_type,
                    total_coverage_amount=coverage_amount,
                    deductible_amount=deductible_amount,
                    premium_amount=premium_amount,
                    start_date=timezone.now().date(),
                    end_date=timezone.now().date() + timedelta(days=365),
                )

                # Create premium schedule
                self._create_premium_schedule(policy)

                return {
                    'success': True,
                    'policy_id': str(policy.id),
                    'policy_number': policy.policy_number,
                    'status': policy.status,
                    'start_date': policy.start_date,
                    'end_date': policy.end_date,
                }

        except MerchantProfile.DoesNotExist:
            return {
                'success': False,
                'error': 'Merchant not found',
            }

    def submit_claim(self, policy_id, claim_type, description, estimated_loss,
                     incident_date=None, incident_location=None):
        """Submit insurance claim"""
        try:
            with transaction.atomic():
                policy = InsurancePolicy.objects.get(id=policy_id)

                # Validate policy is active
                if not policy.is_active():
                    return {
                        'success': False,
                        'error': 'Policy is not active',
                    }

                # Generate claim number
                claim_number = self._generate_claim_number()

                # Create claim
                claim = InsuranceClaim.objects.create(
                    policy=policy,
                    claim_number=claim_number,
                    claim_type=claim_type,
                    description=description,
                    estimated_loss=estimated_loss,
                    incident_date=incident_date or timezone.now(),
                    incident_location=incident_location or '',
                )

                return {
                    'success': True,
                    'claim_id': str(claim.id),
                    'claim_number': claim.claim_number,
                    'status': claim.status,
                }

        except InsurancePolicy.DoesNotExist:
            return {
                'success': False,
                'error': 'Policy not found',
            }

    def process_claim(self, claim_id, action, notes=''):
        """Process insurance claim"""
        try:
            with transaction.atomic():
                claim = InsuranceClaim.objects.get(id=claim_id)

                if action == 'approve':
                    # Auto-approve based on estimated loss and policy limits
                    approved_amount = min(claim.estimated_loss,
                                          claim.policy.total_coverage_amount)
                    claim.approved_amount = approved_amount
                    claim.status = 'approved'
                    claim.approved_at = timezone.now()

                elif action == 'reject':
                    claim.status = 'rejected'
                    claim.approved_amount = 0

                elif action == 'request_info':
                    claim.status = 'under_review'

                else:
                    return {
                        'success': False,
                        'error': 'Invalid action',
                    }

                claim.reviewed_at = timezone.now()
                claim.save()

                return {
                    'success': True,
                    'claim_status': claim.status,
                    'approved_amount': (float(claim.approved_amount)
                                         if claim.approved_amount else 0),
                }

        except InsuranceClaim.DoesNotExist:
            return {
                'success': False,
                'error': 'Claim not found',
            }

    def get_policy_details(self, policy_id):
        """Get policy details"""
        try:
            policy = InsurancePolicy.objects.get(id=policy_id)

            return {
                'success': True,
                'policy': {
                    'id': str(policy.id),
                    'policy_number': policy.policy_number,
                    'policy_type': policy.policy_type,
                    'status': policy.status,
                    'total_coverage_amount': float(
                        policy.total_coverage_amount),
                    'deductible_amount': float(policy.deductible_amount),
                    'premium_amount': float(policy.premium_amount),
                    'start_date': policy.start_date,
                    'end_date': policy.end_date,
                    'is_active': policy.is_active(),
                    'days_until_expiry': policy.days_until_expiry(),
                }
            }

        except InsurancePolicy.DoesNotExist:
            return {
                'success': False,
                'error': 'Policy not found',
            }

    def get_merchant_policies(self, merchant_id):
        """Get all policies for a merchant"""
        try:
            policies = InsurancePolicy.objects.filter(merchant_id=merchant_id)

            return {
                'success': True,
                'policies': [
                    {
                        'id': str(policy.id),
                        'policy_number': policy.policy_number,
                        'policy_type': policy.policy_type,
                        'status': policy.status,
                        'total_coverage_amount': float(
                        policy.total_coverage_amount),
                        'premium_amount': float(policy.premium_amount),
                        'is_active': policy.is_active(),
                        'days_until_expiry': policy.days_until_expiry(),
                    }
                    for policy in policies
                ]
            }

        except Exception:
            return {
                'success': False,
                'error': 'Failed to retrieve policies',
            }

    def get_policy_claims(self, policy_id):
        """Get all claims for a policy"""
        try:
            claims = InsuranceClaim.objects.filter(policy_id=policy_id)

            return {
                'success': True,
                'claims': [
                    {
                        'id': str(claim.id),
                        'claim_number': claim.claim_number,
                        'claim_type': claim.claim_type,
                        'status': claim.status,
                        'estimated_loss': float(claim.estimated_loss),
                        'approved_amount': (float(claim.approved_amount)
                                         if claim.approved_amount else 0),
                        'submitted_at': claim.submitted_at,
                        'incident_date': claim.incident_date,
                    }
                    for claim in claims
                ]
            }

        except Exception:
            return {
                'success': False,
                'error': 'Failed to retrieve claims',
            }

    def get_policy_premiums(self, policy_id):
        """Get all premiums for a policy"""
        try:
            premiums = InsurancePremium.objects.filter(policy_id=policy_id)

            return {
                'success': True,
                'premiums': [
                    {
                        'id': str(premium.id),
                        'premium_number': premium.premium_number,
                        'amount': float(premium.amount),
                        'due_date': premium.due_date,
                        'payment_status': premium.payment_status,
                        'paid_amount': (float(premium.paid_amount)
                                     if premium.paid_amount else 0),
                        'paid_date': premium.paid_date,
                    }
                    for premium in premiums
                ]
            }

        except Exception:
            return {
                'success': False,
                'error': 'Failed to retrieve premiums',
            }

    def get_merchant_risk_assessment(self, merchant_id):
        """Get latest risk assessment for merchant"""
        try:
            risk_assessment = self._get_latest_risk_assessment(merchant_id)

            if not risk_assessment:
                return {
                    'success': False,
                    'error': 'No risk assessment found',
                }

            return {
                'success': True,
                'risk_assessment': {
                    'id': str(risk_assessment.id),
                    'risk_level': risk_assessment.risk_level,
                    'risk_score': risk_assessment.risk_score,
                    'location_risk': risk_assessment.location_risk,
                    'inventory_value': float(risk_assessment.inventory_value),
                    'security_measures': risk_assessment.security_measures,
                    'previous_claims': risk_assessment.previous_claims,
                    'assessment_date': risk_assessment.assessment_date,
                    'next_assessment_due': risk_assessment.next_assessment_due,
                }
            }

        except Exception:
            return {
                'success': False,
                'error': 'Failed to retrieve risk assessment',
            }

    def _get_latest_risk_assessment(self, merchant_id):
        """Get the latest risk assessment for a merchant"""
        return InsuranceRiskAssessment.objects.filter(
            merchant_id=merchant_id
        ).order_by('-assessment_date').first()

    def _calculate_risk_score(self, merchant):
        """Calculate risk score based on merchant profile"""
        score = 50  # Base score

        # Business age factor
        days_since_creation = (
            timezone.now().date() - merchant.created_at.date()
        ).days
        if days_since_creation > 365:
            score -= 10
        elif days_since_creation < 30:
            score += 20

        # Location risk (simplified)
        score += 10  # Default location risk for Guinea

        return max(0, min(100, score))

    def _get_risk_level(self, score):
        """Get risk level based on score"""
        if score < 30:
            return 'low'
        elif score < 50:
            return 'medium'
        elif score < 70:
            return 'high'
        else:
            return 'very_high'

    def _generate_policy_number(self):
        """Generate unique policy number"""
        import random
        import string

        while True:
            prefix = 'POL'
            random_digits = ''.join(random.choices(string.digits, k=8))
            policy_number = f"{prefix}{random_digits}"

            if not InsurancePolicy.objects.filter(policy_number=policy_number).exists():
                return policy_number

    def _generate_claim_number(self):
        """Generate unique claim number"""
        import random
        import string

        while True:
            prefix = 'CLM'
            random_digits = ''.join(random.choices(string.digits, k=8))
            claim_number = f"{prefix}{random_digits}"

            if not InsuranceClaim.objects.filter(claim_number=claim_number).exists():
                return claim_number

    def _create_premium_schedule(self, policy):
        """Create premium payment schedule"""
        premium_amount = policy.premium_amount
        due_day = policy.start_date.day

        # Create monthly premiums for 1 year
        for month in range(12):
            due_date = policy.start_date.replace(day=due_day) + timedelta(days=30 * month)
            premium_number = f"{policy.policy_number}-PREM-{month + 1:02d}"

            InsurancePremium.objects.create(
                policy=policy,
                premium_number=premium_number,
                amount=premium_amount,
                due_date=due_date,
                payment_status='pending',
            )
