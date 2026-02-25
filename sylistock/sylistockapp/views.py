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
        # For demo, return some sample data
        # In real app, you'd query your actual inventory models
        sample_items = [
            {
                'id': 1,
                'barcode': '123456789',
                'name': 'Sample Product 1',
                'quantity': 10,
                'description': 'A sample product for testing',
                'price': '29.99',
                'created_at': '2023-01-01T00:00:00Z'
            },
            {
                'id': 2,
                'barcode': '987654321',
                'name': 'Sample Product 2',
                'quantity': 5,
                'description': 'Another sample product',
                'price': '19.99',
                'created_at': '2023-01-02T00:00:00Z'
            }
        ]
        return Response(sample_items)

    def post(self, request):
        serializer = InventoryItemSerializer(data=request.data)
        if serializer.is_valid():
            # For demo, just return the data with a new ID
            # In real app, you'd save to database
            response_data = serializer.validated_data
            response_data['id'] = 999  # Mock ID
            response_data['created_at'] = '2023-01-01T00:00:00Z'
            return Response(response_data, status=status.HTTP_201_CREATED)
        return Response(
            serializer.errors, status=status.HTTP_400_BAD_REQUEST
        )


class InventoryDetailView(APIView):
    """
    Retrieve, update or delete an inventory item
    """

    def get_object(self, pk):
        # For demo, return mock data
        # In real app, you'd get from database
        if pk == 1:
            return {
                'id': 1,
                'barcode': '123456789',
                'name': 'Sample Product 1',
                'quantity': 10,
                'description': 'A sample product for testing',
                'price': '29.99',
                'created_at': '2023-01-01T00:00:00Z'
            }
        return None

    def get(self, request, pk):
        item = self.get_object(pk)
        if item:
            return Response(item)
        return Response(
            {'error': 'Item not found'},
            status=status.HTTP_404_NOT_FOUND
        )

    def patch(self, request, pk):
        item = self.get_object(pk)
        if not item:
            return Response(
                {'error': 'Item not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        # Update fields
        for field, value in request.data.items():
            if field in ['barcode', 'name', 'quantity', 'description', 'price']:
                item[field] = value

        return Response(item)

    def delete(self, request, pk):
        item = self.get_object(pk)
        if not item:
            return Response({'error': 'Item not found'}, status=status.HTTP_404_NOT_FOUND)
        
        # In real app, you'd delete from database
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
