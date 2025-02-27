import json

from django.contrib.auth import logout, authenticate
from django.contrib.auth.decorators import login_required
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenRefreshView

from my_analysis_project.auth_app.models import AppUser, UserSelection
from my_analysis_project.lib.analysis.motif_presets import MotifPresets
from my_analysis_project.lib.analysis.organism_presets import OrganismPresets


@api_view(["POST"])
@permission_classes([AllowAny])
def login_view(request):
    username = request.data.get("username")
    password = request.data.get("password")

    if not username or not password:
        return Response({"error": "Username and password required"}, status=400)

    user = authenticate(username=username, password=password)

    if user:
        refresh = RefreshToken.for_user(user)
        return Response({
            "refresh": str(refresh),
            "access": str(refresh.access_token),
        })
    else:
        return Response({"error": "Invalid credentials"}, status=401)


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def logout_view(request):
    """Invalidate the refresh token (Blacklist it)"""
    try:
        refresh_token = request.data.get("refresh")
        token = RefreshToken(refresh_token)
        token.blacklist()  # 🚀 Blacklist the token
        return Response({"message": "Logged out successfully"}, status=200)
    except Exception as e:
        return Response({"error": str(e)}, status=400)

class refresh_token_view(TokenRefreshView):
    """Allows users to refresh JWT tokens"""
    pass

@login_required
def get_available_data(request):
    """Returns organisms, motifs, and stages for the user to choose from."""
    organisms = [
        {"name": org.name, "description": org.description}
        for org in OrganismPresets.k_organisms
    ]
    motifs = [
        {"name": motif.name, "definitions": motif.definitions}
        for motif in MotifPresets.get_presets()
    ]
    return JsonResponse({"organisms": organisms, "motifs": motifs})

@csrf_exempt
@login_required
def store_user_selection(request):
    """Stores the user's selected organism, motifs, and stages in the database."""
    try:
        data = json.loads(request.body)
        user = request.user

        organism = data.get("organism")
        motifs = data.get("motifs", [])
        stages = data.get("stages", [])

        if not organism:
            return JsonResponse({"error": "Missing organism"}, status=400)

        selection, created = UserSelection.objects.update_or_create(
            user=user,
            defaults={"organism": organism, "selected_motifs": motifs, "selected_stages": stages},
        )

        return JsonResponse({"message": "Selection saved successfully"})
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)