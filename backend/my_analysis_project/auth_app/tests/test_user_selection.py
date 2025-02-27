import json

from django.contrib.auth import get_user_model
from rest_framework.test import APITestCase
from rest_framework import status
from django.urls import reverse
from rest_framework_simplejwt.tokens import RefreshToken
from my_analysis_project.auth_app.models import UserSelection

User = get_user_model()


class UserSelectionTests(APITestCase):

    def setUp(self):
        """Set up a test user and authentication."""
        self.user = User.objects.create_user(username="testuser", password="testpass")
        self.client.force_authenticate(user=self.user)

        self.set_organism_url = reverse("set_active_organism")
        self.get_organism_url = reverse("get_active_organism")

    def test_set_active_organism(self):
        """Ensure user can select an active organism."""
        response = self.client.post(self.set_organism_url, {"organism": "Zebrafish"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        selection = UserSelection.objects.get(user=self.user)
        self.assertEqual(selection.organism, "Zebrafish")

    def test_get_active_organism(self):
        """Ensure user can retrieve their selected organism."""
        UserSelection.objects.create(user=self.user, organism="Zebrafish")

        response = self.client.get(self.get_organism_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        # Use:
        response_json = json.loads(response.content)
        self.assertEqual(response_json["organism"], "Zebrafish")
