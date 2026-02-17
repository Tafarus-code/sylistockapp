from rest_framework import serializers
from .models import Product, StockItem, InventoryLog


class ProductSerializer(serializers.ModelSerializer):

    class Meta:
        model = Product
        fields = ["barcode", "name", "description"]


class StockItemSerializer(serializers.ModelSerializer):
    # Nested serializer to show product details in the inventory list
    product = ProductSerializer(read_only=True)

    class Meta:
        model = StockItem
        fields = ["product", "quantity", "cost_price", "sale_price"]


class ScanSerializer(serializers.Serializer):
    """
    A custom serializer for processing scans.

    This does not map to a single model directly because a scan
    can trigger multiple changes across models.
    """
    barcode = serializers.CharField(max_length=100)
    action = serializers.ChoiceField(choices=["IN", "OUT"])
    source = serializers.ChoiceField(choices=["ZEBRA", "PHONE"])
    device_id = serializers.CharField(max_length=255)

    def validate_barcode(self, value):
        # Ensure the product exists in our global catalog before allowing a scan
        if not Product.objects.filter(barcode=value).exists():
            raise serializers.ValidationError(
                "Product barcode not recognized in catalog."
            )
        return value


class InventoryLogSerializer(serializers.ModelSerializer):
    product_name = serializers.ReadOnlyField(source="product.name")

    class Meta:
        model = InventoryLog
        fields = [
            "id",
            "product_name",
            "quantity_changed",
            "action",
            "source",
            "timestamp",
        ]

