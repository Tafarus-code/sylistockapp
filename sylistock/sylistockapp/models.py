# Django models
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
    business_age = models.PositiveIntegerField(
        default=0, help_text="Business age in days"
    )
    alert_threshold = models.PositiveIntegerField(
        default=5, help_text="Low stock alert threshold"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.business_name

    def update_bankability_score(self):
        """Recalculate bankability score based on activity"""
        from decimal import Decimal
        score = Decimal('0')

        # KYC status (up to 30 points)
        try:
            kyc = self.kyc_verifications.order_by(
                '-submitted_at'
            ).first()
            if kyc and kyc.status == 'approved':
                score += Decimal('30')
            elif kyc and kyc.status == 'in_progress':
                score += Decimal('15')
        except Exception:
            pass

        # Inventory activity (up to 30 points)
        from django.utils import timezone
        from datetime import timedelta
        recent_logs = InventoryLog.objects.filter(
            merchant=self,
            timestamp__gte=timezone.now() - timedelta(days=30)
        ).count()
        if recent_logs >= 100:
            score += Decimal('30')
        elif recent_logs >= 50:
            score += Decimal('20')
        elif recent_logs >= 10:
            score += Decimal('10')

        # Business age (up to 20 points)
        if self.business_age > 365:
            score += Decimal('20')
        elif self.business_age > 180:
            score += Decimal('15')
        elif self.business_age > 30:
            score += Decimal('10')

        # Stock health (up to 20 points)
        total_items = self.stockitem_set.count()
        if total_items > 0:
            low_stock = self.stockitem_set.filter(
                quantity__lte=self.alert_threshold
            ).count()
            health_ratio = 1 - (low_stock / total_items)
            score += Decimal(str(round(health_ratio * 20, 2)))

        self.bankability_score = min(score, Decimal('100'))
        self.save(update_fields=['bankability_score'])


class Product(models.Model):
    """The 'Catalog' version of a product."""
    barcode = models.CharField(
        max_length=100, unique=True, db_index=True
    )
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    category = models.ForeignKey(
        'Category', on_delete=models.SET_NULL,
        null=True, blank=True, related_name='products'
    )

    def __str__(self):
        return f"{self.name} ({self.barcode})"


class Category(models.Model):
    """Product categories per merchant."""
    merchant = models.ForeignKey(
        MerchantProfile, on_delete=models.CASCADE, related_name='categories'
    )
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True, default='')
    icon = models.CharField(max_length=50, blank=True, default='category')
    color = models.CharField(max_length=10, blank=True, default='0xFF1976D2')
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name_plural = "Categories"
        unique_together = ('merchant', 'name')
        ordering = ['name']

    def __str__(self):
        return self.name


class StockItem(models.Model):
    """Physical inventory in a specific shop."""
    merchant = models.ForeignKey(MerchantProfile, on_delete=models.CASCADE)
    product = models.ForeignKey(Product, on_delete=models.CASCADE)
    quantity = models.PositiveIntegerField(default=0)
    cost_price = models.DecimalField(
        max_digits=12, decimal_places=2, default=0
    )  # Purchase price
    sale_price = models.DecimalField(
        max_digits=12, decimal_places=2, default=0
    )  # Tag price
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)


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
    action = models.CharField(max_length=3, choices=ACTION_TYPES)
    # e.g., +10 for stock in, -1 for sale
    quantity_changed = models.IntegerField()

    # CRITICAL FOR DATA QUALITY:
    source = models.CharField(max_length=10, choices=SCAN_SOURCES)
    device_id = models.CharField(
        max_length=255,
        help_text="Serial or UUID",
    )
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name_plural = "Inventory Logs"
