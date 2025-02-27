from django.contrib.auth import get_user_model
from rest_framework.test import APITestCase
from rest_framework import status
from django.urls import reverse
from rest_framework_simplejwt.tokens import RefreshToken

User = get_user_model()

class AuthTests(APITestCase):

    def setUp(self):
        """Create a test user for authentication."""
        self.user = User.objects.create_user(username="testuser", password="testpass")
        self.login_url = reverse("login")
        self.logout_url = reverse("logout")

    def test_login_valid_credentials(self):
        """Ensure user can log in with valid credentials."""
        response = self.client.post(self.login_url, {"username": "testuser", "password": "testpass"})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("access", response.data)
        self.assertIn("refresh", response.data)

    def test_login_invalid_credentials(self):
        """Ensure invalid credentials are rejected."""
        response = self.client.post(self.login_url, {"username": "wronguser", "password": "wrongpass"})
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
        self.assertIn("error", response.data)

    def test_logout(self):
        """Ensure user can log out by blacklisting the token."""
        refresh = RefreshToken.for_user(self.user)
        response = self.client.post(self.logout_url, {"refresh": str(refresh)}, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)

