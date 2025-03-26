from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status

from my_analysis_project.analysis.models import AnalysisHistory


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def get_user_profile(request):
    """Returns the user's profile information."""
    user = request.user

    # Get analysis history count
    analysis_count = AnalysisHistory.objects.filter(user=user).count()

    # Get user's groups
    user_groups = [group.name for group in user.groups.all()]

    return Response({
        'username': user.username,
        'email': user.email,
        'first_name': user.first_name,
        'last_name': user.last_name,
        'date_joined': user.date_joined,
        'group': user_groups[0] if user_groups else None,
        'groups': user_groups,
        'analysis_count': analysis_count,
    })


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def get_analysis_settings(request, analysis_id):
    """Returns the settings of a specific analysis."""
    user = request.user

    try:
        analysis = AnalysisHistory.objects.get(id=analysis_id, user=user)

        return Response({
            'id': analysis.id,
            'name': analysis.name,
            'organism': analysis.organism,
            'motifs': analysis.motifs,
            'stages': analysis.stages,
            'options': analysis.settings,
        })

    except AnalysisHistory.DoesNotExist:
        return Response(
            {"error": "Analysis not found"},
            status=status.HTTP_404_NOT_FOUND
        )