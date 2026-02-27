"""
Micro-Insurance Service for inventory protection
"""
import os
import json
import uuid
from datetime import datetime, timedelta
from django.utils import timezone
from django.conf import settings
from django.db import transaction
from decimal import Decimal
from ..models_insurance import (
    InsurancePolicy, InsuranceClaim, InsuranceRiskAssessment, 
    InsuranceCoverage, InsurancePremium
)
from ..models import MerchantProfile


class InsuranceService:
    """Micro-Insurance service for inventory protection"""
    
    def __init__(self):
        self.base_premium_rates = {
            'basic': 0.02,      # 2% of coverage amount
            'standard': 0.025,  # 2.5% of coverage amount
            'premium': 0.03,    # 3% of coverage amount
            'comprehensive': 0.035  # 3.5% of coverage amount
        }
        
        self.deductible_percentages = {
            'basic': 0.10,      # 10% deductible
            'standard': 0.08,   # 8% deductible
            'premium': 0.05,    # 5% deductible
            'comprehensive': 0.03  # 3% deductible
        }
    
    def calculate_premium(self, merchant_id, coverage_amount, policy_type='basic', risk_score=50):
        """Calculate insurance premium based on coverage amount and risk"""
        try:
            merchant = MerchantProfile.objects.get(id=merchant_id)
            
            # Base premium rate
            base_rate = self.base_premium_rates.get(policy_type, 0.02)
            
            # Risk adjustment
            risk_multiplier = 1.0 + (risk_score - 50) / 100
            
            # Calculate premium
            base_premium = coverage_amount * base_rate
            adjusted_premium = base_premium * risk_multiplier
            
            # Calculate deductible
            deductible_percentage = self.deductible_percentages.get(policy_type, 0.10)
            deductible_amount = coverage_amount * deductible_percentage
            
            return {
                'success': True,
                'base_premium': float(base_premium),
                'adjusted_premium': float(adjusted_premium),
                'deductible_amount': float(deductible_amount),
                'deductible_percentage': float(deductible_percentage * 100),
                'risk_score': risk_score,
                'policy_type': policy_type,
                'coverage_amount': float(coverage_amount),
                'message': 'Premium calculated successfully'
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
    
    def assess_risk(self, merchant_id):
        """Perform risk assessment for a merchant"""
        try:
            merchant = MerchantProfile.objects.get(id=merchant_id)
            
            # Get existing risk assessment or create new one
            risk_assessment, created = InsuranceRiskAssessment.objects.get_or_create(
                merchant=merchant,
                defaults={
                    'risk_level': 'medium',
                    'risk_score': 50,
                }
            )
            
            # Calculate risk factors
            location_risk = self._assess_location_risk(merchant)
            inventory_risk = self._assess_inventory_risk(merchant)
            security_risk = self._assess_security_risk(merchant)
            claims_risk = self._assess_claims_history(merchant)
            
            # Calculate overall risk score
            overall_risk_score = (
                location_risk * 0.3 +
                inventory_risk * 0.3 +
                security_risk * 0.2 +
                claims_risk * 0.2
            )
            
            # Determine risk level
            if overall_risk_score < 30:
                risk_level = 'low'
            elif overall_risk_score < 60:
                risk_level = 'medium'
            elif overall_risk_score < 80:
                risk_level = 'high'
            else:
                risk_level = 'very_high'
            
            # Update risk assessment
            risk_assessment.risk_score = int(overall_risk_score)
            risk_assessment.risk_level = risk_level
            risk_assessment.location_risk = location_risk
            risk_assessment.next_assessment_due = timezone.now() + timedelta(days=90)
            risk_assessment.save()
            
            return {
                'success': True,
                'risk_score': risk_assessment.risk_score,
                'risk_level': risk_level,
                'location_risk': location_risk,
                'inventory_risk': inventory_risk,
                'security_risk': security_risk,
                'claims_risk': claims_risk,
                'next_assessment_due': risk_assessment.next_assessment_due.isoformat(),
                'message': 'Risk assessment completed'
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
    
    def _assess_location_risk(self, merchant):
        """Assess location-based risk"""
        # Simulate location risk assessment
        # In production, integrate with actual location risk APIs
        import random
        return random.randint(20, 80)
    
    def _assess_inventory_risk(self, merchant):
        """Assess inventory value risk"""
        try:
            # Get total inventory value
            from .models import InventoryItem
            total_value = sum(
                item.quantity * item.unit_price 
                for item in InventoryItem.objects.filter(merchant=merchant)
            )
            
            # Higher inventory value = higher risk
            if total_value > 100000:
                return 70
            elif total_value > 50000:
                return 50
            elif total_value > 10000:
                return 30
            else:
                return 20
                
        except:
            return 50  # Default medium risk
    
    def _assess_security_risk(self, merchant):
        """Assess security measures risk"""
        # Simulate security assessment
        # In production, check actual security measures
        import random
        return random.randint(15, 60)
    
    def _assess_claims_history(self, merchant):
        """Assess claims history risk"""
        try:
            # Check previous claims
            previous_claims = InsuranceClaim.objects.filter(
                policy__merchant=merchant
            ).count()
            
            # More claims = higher risk
            if previous_claims == 0:
                return 20  # Low risk
            elif previous_claims <= 2:
                return 40  # Medium risk
            elif previous_claims <= 5:
                return 60  # High risk
            else:
                return 80  # Very high risk
                
        except:
            return 50  # Default medium risk
    
    def create_insurance_policy(self, merchant_id, coverage_amount, policy_type='basic', start_date=None, end_date=None):
        """Create new insurance policy"""
        try:
            with transaction.atomic():
                merchant = MerchantProfile.objects.get(id=merchant_id)
                
                # Get risk assessment
                risk_assessment = self.assess_risk(merchant_id)
                if not risk_assessment['success']:
                    return risk_assessment
                
                # Calculate premium
                premium_calc = self.calculate_premium(
                    merchant_id, coverage_amount, policy_type, risk_assessment['risk_score']
                )
                if not premium_calc['success']:
                    return premium_calc
                
                # Set policy dates
                if not start_date:
                    start_date = timezone.now().date()
                if not end_date:
                    end_date = start_date + timedelta(days=365)
                
                # Generate policy number
                policy_number = f"POL-{timezone.now().year}-{str(uuid.uuid4())[:8].upper()}"
                
                # Create insurance policy
                policy = InsurancePolicy.objects.create(
                    merchant=merchant,
                    policy_number=policy_number,
                    policy_type=policy_type,
                    total_coverage_amount=coverage_amount,
                    deductible_amount=premium_calc['deductible_amount'],
                    premium_amount=premium_calc['adjusted_premium'],
                    start_date=start_date,
                    end_date=end_date,
                    next_premium_due=start_date + timedelta(days=30),
                    status='pending'
                )
                
                # Create premium schedule
                self._create_premium_schedule(policy)
                
                return {
                    'success': True,
                    'policy_id': str(policy.id),
                    'policy_number': policy_number,
                    'policy_type': policy_type,
                    'coverage_amount': float(coverage_amount),
                    'premium_amount': float(premium_calc['adjusted_premium']),
                    'deductible_amount': float(premium_calc['deductible_amount']),
                    'start_date': start_date.isoformat(),
                    'end_date': end_date.isoformat(),
                    'status': policy.status,
                    'message': 'Insurance policy created successfully'
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
    
    def _create_premium_schedule(self, policy):
        """Create premium payment schedule"""
        # Create monthly premiums for 1 year
        for i in range(12):
            due_date = policy.start_date + timedelta(days=30 * (i + 1))
            if due_date <= policy.end_date:
                InsurancePremium.objects.create(
                    policy=policy,
                    premium_number=f"{policy.policy_number}-{i+1:02d}",
                    amount=policy.premium_amount / 12,
                    due_date=due_date,
                    payment_status='pending'
                )
    
    def submit_claim(self, policy_id, claim_type, description, estimated_loss, incident_date, incident_location='', police_report_filed=False, police_report_number=''):
        """Submit insurance claim"""
        try:
            policy = InsurancePolicy.objects.get(id=policy_id)
            
            # Validate policy is active
            if not policy.is_active():
                return {
                    'success': False,
                    'error': 'Policy is not active'
                }
            
            # Generate claim number
            claim_number = f"CLM-{timezone.now().year}-{str(uuid.uuid4())[:8].upper()}"
            
            # Create claim
            claim = InsuranceClaim.objects.create(
                policy=policy,
                claim_number=claim_number,
                claim_type=claim_type,
                description=description,
                estimated_loss=estimated_loss,
                incident_date=incident_date,
                incident_location=incident_location,
                police_report_filed=police_report_filed,
                police_report_number=police_report_number,
                status='submitted'
            )
            
            return {
                'success': True,
                'claim_id': str(claim.id),
                'claim_number': claim_number,
                'claim_type': claim_type,
                'estimated_loss': float(estimated_loss),
                'status': claim.status,
                'submitted_at': claim.submitted_at.isoformat(),
                'message': 'Claim submitted successfully'
            }
            
        except InsurancePolicy.DoesNotExist:
            return {
                'success': False,
                'error': 'Policy not found'
            }
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }
    
    def process_claim(self, claim_id, approved_amount=None, status='approved', settlement_notes=''):
        """Process insurance claim"""
        try:
            claim = InsuranceClaim.objects.get(id=claim_id)
            
            if claim.status not in ['submitted', 'under_review']:
                return {
                    'success': False,
                    'error': f'Cannot process claim with status: {claim.status}'
                }
            
            # Update claim
            claim.status = status
            claim.reviewed_at = timezone.now()
            claim.settlement_notes = settlement_notes
            
            if status == 'approved' and approved_amount:
                claim.approved_amount = approved_amount
                claim.approved_at = timezone.now()
            elif status == 'rejected':
                claim.approved_amount = 0
            
            claim.save()
            
            return {
                'success': True,
                'claim_id': str(claim.id),
                'claim_number': claim.claim_number,
                'status': claim.status,
                'approved_amount': float(claim.approved_amount) if claim.approved_amount else None,
                'reviewed_at': claim.reviewed_at.isoformat(),
                'message': f'Claim {status} successfully'
            }
            
        except InsuranceClaim.DoesNotExist:
            return {
                'success': False,
                'error': 'Claim not found'
            }
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }
    
    def get_policy_details(self, policy_id):
        """Get insurance policy details"""
        try:
            policy = InsurancePolicy.objects.get(id=policy_id)
            
            # Get premiums
            premiums = InsurancePremium.objects.filter(policy=policy)
            premium_data = []
            for premium in premiums:
                premium_data.append({
                    'premium_number': premium.premium_number,
                    'amount': float(premium.amount),
                    'due_date': premium.due_date.isoformat(),
                    'payment_status': premium.payment_status,
                    'paid_date': premium.paid_date.isoformat() if premium.paid_date else None
                })
            
            # Get claims
            claims = InsuranceClaim.objects.filter(policy=policy)
            claim_data = []
            for claim in claims:
                claim_data.append({
                    'claim_id': str(claim.id),
                    'claim_number': claim.claim_number,
                    'claim_type': claim.claim_type,
                    'status': claim.status,
                    'estimated_loss': float(claim.estimated_loss),
                    'approved_amount': float(claim.approved_amount) if claim.approved_amount else None,
                    'submitted_at': claim.submitted_at.isoformat()
                })
            
            return {
                'success': True,
                'policy_id': str(policy.id),
                'policy_number': policy.policy_number,
                'policy_type': policy.policy_type,
                'status': policy.status,
                'coverage_amount': float(policy.total_coverage_amount),
                'deductible_amount': float(policy.deductible_amount),
                'premium_amount': float(policy.premium_amount),
                'start_date': policy.start_date.isoformat(),
                'end_date': policy.end_date.isoformat(),
                'is_active': policy.is_active(),
                'days_until_expiry': policy.days_until_expiry(),
                'premiums': premium_data,
                'claims': claim_data,
                'message': 'Policy details retrieved successfully'
            }
            
        except InsurancePolicy.DoesNotExist:
            return {
                'success': False,
                'error': 'Policy not found'
            }
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }
    
    def get_merchant_policies(self, merchant_id):
        """Get all insurance policies for a merchant"""
        try:
            merchant = MerchantProfile.objects.get(id=merchant_id)
            policies = InsurancePolicy.objects.filter(merchant=merchant)
            
            policy_data = []
            for policy in policies:
                policy_data.append({
                    'policy_id': str(policy.id),
                    'policy_number': policy.policy_number,
                    'policy_type': policy.policy_type,
                    'status': policy.status,
                    'coverage_amount': float(policy.total_coverage_amount),
                    'premium_amount': float(policy.premium_amount),
                    'start_date': policy.start_date.isoformat(),
                    'end_date': policy.end_date.isoformat(),
                    'is_active': policy.is_active(),
                    'days_until_expiry': policy.days_until_expiry()
                })
            
            return {
                'success': True,
                'policies': policy_data,
                'count': len(policy_data),
                'message': 'Merchant policies retrieved successfully'
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
