from django.test import TestCase


class DummyTest(TestCase):
    """Dummy test to ensure pytest runs successfully."""

    def test_dummy_pass(self):
        """Simple test that always passes."""
        self.assertEqual(1 + 1, 2)
