import json

from django.contrib.auth import get_user_model
from rest_framework.test import APITestCase
from rest_framework import status
from django.urls import reverse
from my_analysis_project.auth_app.models import UserSelection, AnalysisHistory

User = get_user_model()

class AnalysisTests(APITestCase):

    def setUp(self):
        """Set up test user, authentication, and selection."""
        self.user = User.objects.create_user(username="testuser", password="testpass")
        self.client.force_authenticate(user=self.user)

        # Create selection
        UserSelection.objects.create(user=self.user, organism="Zebrafish", selected_motifs=["motif1"], selected_stages=["stage1"])

        self.run_analysis_url = reverse("run_analysis")


        self.history_url = reverse("analysis_history")

    def test_run_analysis(self):
        """Ensure user can run an analysis."""
        response = self.client.post(
            self.run_analysis_url,
            {
                "organism": "Zebrafish",
                "motif": {"name": "motif1", "definitions": ["ATG"]},
                "min": -1000,
                "max": 1000,
                "interval": 30,
                "alignMarker": None,
                "color": "#FF0000",
                "stroke": 4,
            },
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)

        analysis_entry = AnalysisHistory.objects.filter(user=self.user).first()
        self.assertIsNotNone(analysis_entry)
        self.assertEqual(analysis_entry.name, "Analysis for Zebrafish")

    def test_get_analysis_history(self):
        """Ensure user can retrieve analysis history."""
        AnalysisHistory.objects.create(user=self.user, name="Test Analysis", results={"some": "data"})

        response = self.client.get(self.history_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        response_json = json.loads(response.content)  # Convert response content to JSON
        self.assertEqual(len(response_json["history"]), 1)
        response_json = json.loads(response.content)
        self.assertEqual(response_json["history"][0]["name"], "Test Analysis")


