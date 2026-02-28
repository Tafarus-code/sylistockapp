from django.db import transaction
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import serializers
from .models import (
    Product,
    StockItem,
    InventoryLog,
    MerchantProfile,
)


# Simple serializer for inventory items
class InventoryItemSerializer(serializers.Serializer):
    id = serializers.IntegerField(read_only=True)
    barcode = serializers.CharField(max_length=100)
    name = serializers.CharField(max_length=200)
    quantity = serializers.IntegerField()
    description = serializers.CharField(required=False, allow_blank=True)
    price = serializers.DecimalField(
        max_digits=10, decimal_places=2, required=False
    )
    created_at = serializers.DateTimeField(read_only=True)


class InventoryListView(APIView):
    """
    List all inventory items or create a new inventory item
    """

    def get(self, request):
        merchant = getattr(request.user, 'merchantprofile', None)
        if not merchant:
            return Response(
                {'error': 'Merchant profile not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        items = StockItem.objects.filter(
            merchant=merchant
        ).select_related('product')

        items_data = []
        for item in items:
            items_data.append({
                'id': item.pk,
                'barcode': item.product.barcode,
                'name': item.product.name,
                'quantity': item.quantity,
                'description': item.product.description,
                'price': str(item.sale_price),
                'created_at': item.created_at,
            })
        return Response(items_data)

    def post(self, request):
        serializer = InventoryItemSerializer(data=request.data)
        if serializer.is_valid():
            data = serializer.validated_data
            merchant = getattr(request.user, 'merchantprofile', None)
            if not merchant:
                return Response(
                    {'error': 'Merchant profile not found'},
                    status=status.HTTP_404_NOT_FOUND
                )

            with transaction.atomic():
                product, _ = Product.objects.get_or_create(
                    barcode=data['barcode'],
                    defaults={
                        'name': data['name'],
                        'description': data.get('description', ''),
                    }
                )
                stock_item = StockItem.objects.create(
                    merchant=merchant,
                    product=product,
                    quantity=data.get('quantity', 0),
                    sale_price=data.get('price', 0),
                )

            return Response({
                'id': stock_item.pk,
                'barcode': product.barcode,
                'name': product.name,
                'quantity': stock_item.quantity,
                'price': str(stock_item.sale_price),
                'created_at': stock_item.created_at,
            }, status=status.HTTP_201_CREATED)
        return Response(
            serializer.errors, status=status.HTTP_400_BAD_REQUEST
        )


class InventoryDetailView(APIView):
    """
    Retrieve, update or delete an inventory item
    """

    def get_object(self, pk, user):
        merchant = getattr(user, 'merchantprofile', None)
        if not merchant:
            return None
        try:
            return StockItem.objects.select_related('product').get(
                pk=pk, merchant=merchant
            )
        except StockItem.DoesNotExist:
            return None

    def get(self, request, pk):
        item = self.get_object(pk, request.user)
        if item:
            return Response({
                'id': item.pk,
                'barcode': item.product.barcode,
                'name': item.product.name,
                'quantity': item.quantity,
                'description': item.product.description,
                'price': str(item.sale_price),
                'created_at': item.created_at,
            })
        return Response(
            {'error': 'Item not found'},
            status=status.HTTP_404_NOT_FOUND
        )

    def patch(self, request, pk):
        item = self.get_object(pk, request.user)
        if not item:
            return Response(
                {'error': 'Item not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        if 'quantity' in request.data:
            item.quantity = int(request.data['quantity'])
        if 'price' in request.data:
            item.sale_price = request.data['price']
        if 'name' in request.data:
            item.product.name = request.data['name']
            item.product.save()
        item.save()

        return Response({
            'id': item.pk,
            'barcode': item.product.barcode,
            'name': item.product.name,
            'quantity': item.quantity,
            'price': str(item.sale_price),
        })

    def delete(self, request, pk):
        item = self.get_object(pk, request.user)
        if not item:
            return Response(
                {'error': 'Item not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        item.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class ProcessScanView(APIView):

    def post(self, request):
        barcode = request.data.get("barcode")
        action = request.data.get("action")  # 'IN' or 'OUT'
        source = request.data.get("source")  # 'ZEBRA' or 'PHONE'
        device_id = request.data.get("device_id")
        merchant_user = request.user  # Assumes authentication is set up

        try:
            # 1. Start an atomic transaction
            with transaction.atomic():
                # 2. Get the product (or return 404 if not in catalog)
                product = Product.objects.get(barcode=barcode)

                # 3. Get the merchant's profile
                merchant = MerchantProfile.objects.get(user=merchant_user)

                # 4. LOCK the StockItem row to prevent double-counting.
                # This is critical for bankable data integrity.
                stock_item, created = (
                    StockItem.objects.select_for_update().get_or_create(
                        merchant=merchant,
                        product=product,
                        defaults={
                            "cost_price": 0,
                            "sale_price": 0,
                        },
                    )
                )

                # 5. Update the quantity
                qty_change = 1 if action == "IN" else -1
                stock_item.quantity += qty_change

                if stock_item.quantity < 0:
                    return Response(
                        {"error": "Insufficient stock"},
                        status=status.HTTP_400_BAD_REQUEST,
                    )

                stock_item.save()

                # 6. Log the movement with the hardware source
                InventoryLog.objects.create(
                    merchant=merchant,
                    product=product,
                    quantity_changed=qty_change,
                    action=action,
                    source=source,
                    device_id=device_id,
                )

            return Response(
                {
                    "message": "Scan processed",
                    "new_quantity": stock_item.quantity,
                    "product": product.name,
                },
                status=status.HTTP_200_OK,
            )

        except Product.DoesNotExist:
            return Response(
                {"error": "Product not found"},
                status=status.HTTP_404_NOT_FOUND,
            )
        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )
