from django.db import transaction
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from .models import (
    Product,
    StockItem,
    InventoryLog,
    MerchantProfile,
)


class ProcessScanView(APIView):
    """
    Process barcode scan from Zebra scanner or phone camera.
    This is the core bankability-critical endpoint.
    """

    def post(self, request):
        barcode = request.data.get("barcode")
        action = request.data.get("action")  # 'IN' or 'OUT'
        source = request.data.get("source")  # 'ZEBRA' or 'PHONE'
        device_id = request.data.get("device_id")
        merchant_user = request.user

        try:
            with transaction.atomic():
                product = Product.objects.get(barcode=barcode)
                merchant = MerchantProfile.objects.get(
                    user=merchant_user
                )

                # LOCK the row to prevent double-counting
                stock_item, created = (
                    StockItem.objects.select_for_update()
                    .get_or_create(
                        merchant=merchant,
                        product=product,
                        defaults={
                            "cost_price": 0,
                            "sale_price": 0,
                        },
                    )
                )

                qty_change = 1 if action == "IN" else -1
                stock_item.quantity += qty_change

                if stock_item.quantity < 0:
                    return Response(
                        {"error": "Insufficient stock"},
                        status=status.HTTP_400_BAD_REQUEST,
                    )

                stock_item.save()

                InventoryLog.objects.create(
                    merchant=merchant,
                    product=product,
                    quantity_changed=qty_change,
                    action=action,
                    source=source,
                    device_id=device_id,
                )

            # Update bankability score after scan
            merchant.update_bankability_score()

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
        except MerchantProfile.DoesNotExist:
            return Response(
                {"error": "Merchant profile not found"},
                status=status.HTTP_404_NOT_FOUND,
            )
        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )
