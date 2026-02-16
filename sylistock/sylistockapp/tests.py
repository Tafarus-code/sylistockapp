from django.test import TestCase


class DummyTest(TestCase):
    """Dummy test to ensure pytest runs successfully."""

    def test_dummy_pass(self):
        """Simple test that always passes."""
        self.assertEqual(1 + 1, 2)

    def test_app_is_installed(self):
        """Verify the app is installed in Django."""
        from django.apps import apps
        self.assertTrue(apps.is_installed('sylistockapp'))

