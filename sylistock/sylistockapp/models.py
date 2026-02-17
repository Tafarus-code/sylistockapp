from django.db import models
from django.contrib.auth import get_user_model

User = get_user_model()


class MerchantProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    business_name = models.CharField(max_length=255)
    location = models.CharField(max_length=255)  # e.g., "Madina Market"
    bankability_score = models.DecimalField(
        max_digits=5, decimal_places=2, default=0.0
    )


class Product(models.Model):
    """The 'Catalog' version of a product."""
    barcode = models.CharField(
        max_length=100, unique=True, db_index=True
    )
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True)

    def __str__(self):
        return f"{self.name} ({self.barcode})"


class StockItem(models.Model):
    """Physical inventory in a specific shop."""
    merchant = models.ForeignKey(MerchantProfile, on_delete=models.CASCADE)
    product = models.ForeignKey(Product, on_delete=models.CASCADE)
    quantity = models.PositiveIntegerField(default=0)
    cost_price = models.DecimalField(
        max_digits=12, decimal_places=2
    )  # Purchase price
    sale_price = models.DecimalField(
        max_digits=12, decimal_places=2
    )  # Tag price


class InventoryLog(models.Model):
    """The Audit Trail for Bankability."""
    SCAN_SOURCES = (
        ("ZEBRA", "Zebra Laser Scanner"),
        ("PHONE", "Mobile Camera Scan"),
        ("MANUAL", "Manual Entry"),
    )

    ACTION_TYPES = (
        ("IN", "Restock"),
        ("OUT", "Sale"),
        ("ADJ", "Adjustment (Damage/Lost)"),
    )

    merchant = models.ForeignKey(MerchantProfile, on_delete=models.CASCADE)
    product = models.ForeignKey(Product, on_delete=models.CASCADE)
    quantity_changed = models.IntegerField()  # e.g., +10 for stock in, -1 for sale
    action = models.CharField(max_length=3, choices=ACTION_TYPES)

    # CRITICAL FOR DATA QUALITY:
    source = models.CharField(max_length=10, choices=SCAN_SOURCES)
    device_id = models.CharField(
        max_length=255,
        help_text="Serial or UUID",
    )
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name_plural = "Inventory Logs"
