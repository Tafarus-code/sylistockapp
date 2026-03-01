from django.test import TestCase
from django.contrib.auth import get_user_model
from rest_framework.test import APITestCase, APIClient
from rest_framework import status
from .models import MerchantProfile, Product, StockItem, InventoryLog

User = get_user_model()


class ModelTests(TestCase):
    """Test model creation and methods"""

    def setUp(self):
        self.user = User.objects.create_user(
            username='testmerchant', password='testpass123'
        )
        self.merchant = MerchantProfile.objects.create(
            user=self.user,
            business_name='Test Shop',
            location='Madina Market',
        )
        self.product = Product.objects.create(
            barcode='1234567890',
            name='Test Product',
            description='A test product',
        )

    def test_merchant_profile_creation(self):
        self.assertEqual(str(self.merchant), 'Test Shop')
        self.assertEqual(self.merchant.bankability_score, 0.0)
        self.assertEqual(self.merchant.alert_threshold, 5)
        self.assertEqual(self.merchant.business_age, 0)

    def test_product_creation(self):
        self.assertEqual(
            str(self.product), 'Test Product (1234567890)'
        )

    def test_stock_item_creation(self):
        stock_item = StockItem.objects.create(
            merchant=self.merchant,
            product=self.product,
            quantity=10,
            cost_price=5.00,
            sale_price=9.99,
        )
        self.assertEqual(stock_item.quantity, 10)
        self.assertIsNotNone(stock_item.created_at)
        self.assertIsNotNone(stock_item.updated_at)

    def test_stock_item_default_prices(self):
        stock_item = StockItem.objects.create(
            merchant=self.merchant,
            product=self.product,
            quantity=5,
        )
        self.assertEqual(stock_item.cost_price, 0)
        self.assertEqual(stock_item.sale_price, 0)

    def test_inventory_log_creation(self):
        log = InventoryLog.objects.create(
            merchant=self.merchant,
            product=self.product,
            action='IN',
            quantity_changed=10,
            source='MANUAL',
            device_id='web',
        )
        self.assertEqual(log.action, 'IN')
        self.assertEqual(log.quantity_changed, 10)


class StockItemViewTests(APITestCase):
    """Test stock item API endpoints"""

    def setUp(self):
        self.user = User.objects.create_user(
            username='testmerchant', password='testpass123'
        )
        self.merchant = MerchantProfile.objects.create(
            user=self.user,
            business_name='Test Shop',
            location='Madina Market',
        )
        self.client = APIClient()
        self.client.force_authenticate(user=self.user)
        self.product = Product.objects.create(
            barcode='1234567890',
            name='Test Product',
        )

    def test_add_stock_item(self):
        response = self.client.post('/inventory/items/add/', {
            'barcode': '9999999999',
            'name': 'New Product',
            'quantity': 20,
            'price': 15.99,
        })
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['quantity'], 20)
        self.assertTrue(
            Product.objects.filter(barcode='9999999999').exists()
        )

    def test_add_stock_item_missing_fields(self):
        response = self.client.post('/inventory/items/add/', {
            'barcode': '',
            'name': '',
        })
        self.assertEqual(
            response.status_code, status.HTTP_400_BAD_REQUEST
        )

    def test_remove_stock_item(self):
        stock_item = StockItem.objects.create(
            merchant=self.merchant,
            product=self.product,
            quantity=10,
        )
        response = self.client.post(
            f'/inventory/items/remove/{stock_item.pk}/',
            {'quantity': 3}
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['remaining_quantity'], 7)

    def test_remove_insufficient_stock(self):
        stock_item = StockItem.objects.create(
            merchant=self.merchant,
            product=self.product,
            quantity=2,
        )
        response = self.client.post(
            f'/inventory/items/remove/{stock_item.pk}/',
            {'quantity': 5}
        )
        self.assertEqual(
            response.status_code, status.HTTP_400_BAD_REQUEST
        )

    def test_get_stock_items(self):
        StockItem.objects.create(
            merchant=self.merchant,
            product=self.product,
            quantity=10,
            sale_price=9.99,
        )
        response = self.client.get('/inventory/items/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['items']), 1)

    def test_search_items(self):
        StockItem.objects.create(
            merchant=self.merchant,
            product=self.product,
            quantity=10,
        )
        response = self.client.get(
            '/inventory/items/search/?q=Test'
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertGreaterEqual(response.data['count'], 1)


class AlertViewTests(APITestCase):
    """Test alert endpoints"""

    def setUp(self):
        self.user = User.objects.create_user(
            username='testmerchant', password='testpass123'
        )
        self.merchant = MerchantProfile.objects.create(
            user=self.user,
            business_name='Test Shop',
            location='Madina Market',
        )
        self.client = APIClient()
        self.client.force_authenticate(user=self.user)

    def test_low_stock_alerts(self):
        product = Product.objects.create(
            barcode='111', name='Low Stock Item'
        )
        StockItem.objects.create(
            merchant=self.merchant,
            product=product,
            quantity=2,
        )
        response = self.client.get(
            '/inventory/alerts/low-stock/?threshold=5'
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['count'], 1)

    def test_set_alert_threshold(self):
        response = self.client.post(
            '/inventory/alerts/threshold/',
            {'threshold': 10}
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.merchant.refresh_from_db()
        self.assertEqual(self.merchant.alert_threshold, 10)


class UnauthenticatedAccessTests(APITestCase):
    """Test that endpoints require authentication"""

    def test_stock_items_requires_auth(self):
        response = self.client.get('/inventory/items/')
        self.assertIn(
            response.status_code,
            [status.HTTP_401_UNAUTHORIZED,
             status.HTTP_403_FORBIDDEN],
        )

    def test_add_item_requires_auth(self):
        response = self.client.post('/inventory/items/add/', {})
        self.assertIn(
            response.status_code,
            [status.HTTP_401_UNAUTHORIZED,
             status.HTTP_403_FORBIDDEN],
        )
