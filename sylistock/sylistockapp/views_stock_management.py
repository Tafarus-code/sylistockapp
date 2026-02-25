from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.db.models import Q
from .models import StockItem, MerchantProfile


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def search_items(request):
    """
    Search inventory items by barcode or name
    """
    try:
        merchant_profile = request.user.merchantprofile
        query = request.GET.get('q', '').strip()

        if not query:
            return Response(
                {'error': 'Search query is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        items = StockItem.objects.filter(
            merchant=merchant_profile
        ).filter(
            Q(product__barcode__icontains=query) |
            Q(product__name__icontains=query)
        ).select_related('product')[:20]

        results = []
        for item in items:
            results.append({
                'id': item.pk,
                'barcode': item.product.barcode,
                'name': item.product.name,
                'quantity': item.quantity,
                'price': item.sale_price,
                'last_updated': item.pk,  # Using pk as placeholder
            })

        return Response({
            'query': query,
            'results': results,
            'count': len(results),
        })

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


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_item_details(request, item_id):
    """
    Get detailed information about a specific item
    """
    try:
        merchant_profile = request.user.merchantprofile

        try:
            item = StockItem.objects.get(
                id=item_id,
                merchant=merchant_profile
            )
        except StockItem.DoesNotExist:
            return Response(
                {'error': 'Item not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        return Response({
            'id': item.pk,
            'barcode': item.product.barcode,
            'name': item.product.name,
            'quantity': item.quantity,
            'price': item.sale_price,
            'created_at': item.pk,  # Using pk as placeholder
            'updated_at': item.pk,  # Using pk as placeholder
        })

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


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def bulk_update_prices(request):
    """
    Update prices for multiple items
    """
    try:
        merchant_profile = request.user.merchantprofile
        price_updates = request.data.get('price_updates', [])

        if not price_updates:
            return Response(
                {'error': 'No price updates provided'},
                status=status.HTTP_400_BAD_REQUEST
            )

        updated_count = 0
        errors = []

        for idx, update in enumerate(price_updates):
            try:
                item_id = update.get('id')
                price = update.get('price')

                if not item_id or price is None:
                    errors.append(f'Update {idx}: Missing item ID or price')
                    continue

                try:
                    item = StockItem.objects.get(
                        id=item_id,
                        merchant=merchant_profile
                    )
                    item.sale_price = float(price)
                    item.save()
                    updated_count += 1

                except StockItem.DoesNotExist:
                    errors.append(f'Update {idx}: Item not found')
                except ValueError:
                    errors.append(f'Update {idx}: Invalid price')

            except Exception as e:
                errors.append(f'Update {idx}: {str(e)}')

        return Response({
            'updated': updated_count,
            'errors': errors,
            'total_updates': len(price_updates),
        })

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
