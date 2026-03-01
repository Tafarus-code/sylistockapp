"""
Authentication views for user registration and login
"""
from django.contrib.auth import get_user_model, authenticate
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError
from rest_framework import status
from rest_framework.authtoken.models import Token
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response

User = get_user_model()


@api_view(['POST'])
@permission_classes([AllowAny])
def register(request):
    """Register a new user"""
    username = request.data.get('username', '').strip()
    password = request.data.get('password', '')
    email = request.data.get('email', '').strip()
    business_name = request.data.get('business_name', '').strip()
    location = request.data.get('location', '').strip()

    if not all([username, password, business_name]):
        return Response({
            'error': 'Missing required fields',
            'required': [
                'username', 'password', 'business_name',
            ],
        }, status=status.HTTP_400_BAD_REQUEST)

    if User.objects.filter(username=username).exists():
        return Response({
            'error': 'Username already exists',
        }, status=status.HTTP_400_BAD_REQUEST)

    # Validate password strength
    try:
        validate_password(password)
    except DjangoValidationError as e:
        return Response({
            'error': 'Password too weak',
            'details': list(e.messages),
        }, status=status.HTTP_400_BAD_REQUEST)

    user = User.objects.create_user(
        username=username,
        password=password,
        email=email,
    )

    # Create merchant profile
    from .models import MerchantProfile
    merchant_profile = MerchantProfile.objects.create(
        user=user,
        business_name=business_name,
        location=location,
    )

    token, _ = Token.objects.get_or_create(user=user)

    return Response({
        'success': True,
        'token': token.key,
        'user': {
            'id': user.pk,
            'username': user.username,
            'email': user.email,
            'business_name': business_name,
            'merchant_id': merchant_profile.pk,
        },
    }, status=status.HTTP_201_CREATED)


@api_view(['POST'])
@permission_classes([AllowAny])
def login(request):
    """Login and get auth token"""
    username = request.data.get('username', '')
    password = request.data.get('password', '')

    if not username or not password:
        return Response({
            'error': 'Username and password are required',
        }, status=status.HTTP_400_BAD_REQUEST)

    user = authenticate(username=username, password=password)

    if not user:
        return Response({
            'error': 'Invalid credentials',
        }, status=status.HTTP_401_UNAUTHORIZED)

    token, _ = Token.objects.get_or_create(user=user)

    merchant_name = ''
    merchant_id = None
    if hasattr(user, 'merchantprofile'):
        merchant_name = user.merchantprofile.business_name
        merchant_id = user.merchantprofile.pk

    return Response({
        'success': True,
        'token': token.key,
        'user': {
            'id': user.pk,
            'username': user.username,
            'email': user.email,
            'business_name': merchant_name,
            'merchant_id': merchant_id,
        },
    })


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def logout(request):
    """Logout and delete auth token"""
    try:
        request.user.auth_token.delete()
    except Exception:
        pass

    return Response({
        'success': True,
        'message': 'Logged out successfully',
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def profile(request):
    """Get current user profile"""
    user = request.user
    merchant_data = {}

    if hasattr(user, 'merchantprofile'):
        mp = user.merchantprofile
        merchant_data = {
            'id': mp.pk,
            'business_name': mp.business_name,
            'location': mp.location,
            'bankability_score': float(mp.bankability_score),
            'business_age': mp.business_age,
            'alert_threshold': mp.alert_threshold,
        }

    return Response({
        'id': user.pk,
        'username': user.username,
        'email': user.email,
        'merchant': merchant_data,
    })
