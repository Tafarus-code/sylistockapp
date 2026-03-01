"""
Category CRUD views for inventory management.
"""
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from .models import Category, MerchantProfile


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_categories(request):
    """Get all categories for the logged-in merchant."""
    try:
        merchant = request.user.merchantprofile
        categories = Category.objects.filter(merchant=merchant)

        data = []
        for cat in categories:
            data.append({
                'id': cat.pk,
                'name': cat.name,
                'description': cat.description,
                'icon': cat.icon,
                'color': cat.color,
                'is_active': cat.is_active,
                'created_at': cat.created_at.isoformat(),
                'updated_at': cat.updated_at.isoformat(),
            })

        return Response({'categories': data})

    except MerchantProfile.DoesNotExist:
        return Response(
            {'error': 'Merchant profile not found'},
            status=status.HTTP_404_NOT_FOUND
        )


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_category(request):
    """Create a new category."""
    try:
        merchant = request.user.merchantprofile

        name = request.data.get('name', '').strip()
        if not name:
            return Response(
                {'error': 'Category name is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        description = request.data.get('description', '')
        icon = request.data.get('icon', 'category')
        color = request.data.get('color', '0xFF1976D2')
        is_active = request.data.get('is_active', True)

        # Check for duplicate name
        if Category.objects.filter(merchant=merchant, name=name).exists():
            return Response(
                {'error': f'Category "{name}" already exists'},
                status=status.HTTP_400_BAD_REQUEST
            )

        cat = Category.objects.create(
            merchant=merchant,
            name=name,
            description=description,
            icon=icon,
            color=str(color),
            is_active=is_active,
        )

        return Response({
            'id': cat.pk,
            'name': cat.name,
            'description': cat.description,
            'icon': cat.icon,
            'color': cat.color,
            'is_active': cat.is_active,
            'created_at': cat.created_at.isoformat(),
            'updated_at': cat.updated_at.isoformat(),
        }, status=status.HTTP_201_CREATED)

    except MerchantProfile.DoesNotExist:
        return Response(
            {'error': 'Merchant profile not found'},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['PUT', 'PATCH'])
@permission_classes([IsAuthenticated])
def update_category(request, category_id):
    """Update an existing category."""
    try:
        merchant = request.user.merchantprofile
        cat = Category.objects.get(pk=category_id, merchant=merchant)

        if 'name' in request.data:
            name = request.data['name'].strip()
            if not name:
                return Response(
                    {'error': 'Category name cannot be empty'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            # Check duplicate (excluding self)
            if Category.objects.filter(
                merchant=merchant, name=name
            ).exclude(pk=category_id).exists():
                return Response(
                    {'error': f'Category "{name}" already exists'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            cat.name = name

        if 'description' in request.data:
            cat.description = request.data['description']
        if 'icon' in request.data:
            cat.icon = request.data['icon']
        if 'color' in request.data:
            cat.color = str(request.data['color'])
        if 'is_active' in request.data:
            cat.is_active = request.data['is_active']

        cat.save()

        return Response({
            'id': cat.pk,
            'name': cat.name,
            'description': cat.description,
            'icon': cat.icon,
            'color': cat.color,
            'is_active': cat.is_active,
            'created_at': cat.created_at.isoformat(),
            'updated_at': cat.updated_at.isoformat(),
        })

    except Category.DoesNotExist:
        return Response(
            {'error': 'Category not found'},
            status=status.HTTP_404_NOT_FOUND
        )
    except MerchantProfile.DoesNotExist:
        return Response(
            {'error': 'Merchant profile not found'},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_category(request, category_id):
    """Delete a category."""
    try:
        merchant = request.user.merchantprofile
        cat = Category.objects.get(pk=category_id, merchant=merchant)
        cat.delete()
        return Response({'success': True, 'message': 'Category deleted'})

    except Category.DoesNotExist:
        return Response(
            {'error': 'Category not found'},
            status=status.HTTP_404_NOT_FOUND
        )
    except MerchantProfile.DoesNotExist:
        return Response(
            {'error': 'Merchant profile not found'},
            status=status.HTTP_404_NOT_FOUND
        )

