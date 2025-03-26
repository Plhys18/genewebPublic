# user_preferences.py

import json
from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status

from my_analysis_project.auth_app.models import UserColorPreference


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def get_user_preferences(request):
    user = request.user

    motif_preferences = UserColorPreference.objects.filter(
        user=user,
        preference_type='motif'
    ).values('name', 'color', 'stroke_width')

    stage_preferences = UserColorPreference.objects.filter(
        user=user,
        preference_type='stage'
    ).values('name', 'color', 'stroke_width')

    return Response({
        'motifs': list(motif_preferences),
        'stages': list(stage_preferences)
    })


@api_view(["POST"])
@permission_classes([IsAuthenticated])

def set_color_preference(request):
    user = request.user
    data = json.loads(request.body)

    preference_type = data.get('type')
    name = data.get('name')
    color = data.get('color')
    stroke_width = data.get('stroke_width', 4)

    if not all([preference_type, name, color]):
        return JsonResponse("Missing required fields", status.HTTP_400_BAD_REQUEST)

    if preference_type not in ['motif', 'stage']:
        return JsonResponse("Invalid preference type", status.HTTP_400_BAD_REQUEST)

    if not color.startswith('#') or len(color) not in [7, 9]:
        return JsonResponse("Invalid color format. Use #RRGGBB or #RRGGBBAA", status.HTTP_400_BAD_REQUEST)

    preference, created = UserColorPreference.objects.update_or_create(
        user=user,
        preference_type=preference_type,
        name=name,
        defaults={
            'color': color,
            'stroke_width': stroke_width
        }
    )

    return Response({
        'status': 'created' if created else 'updated',
        'preference': {
            'type': preference.preference_type,
            'name': preference.name,
            'color': preference.color,
            'stroke_width': preference.stroke_width
        }
    })


@api_view(["DELETE"])
@permission_classes([IsAuthenticated])

def delete_color_preference(request, preference_id):
    user = request.user

    try:
        preference = UserColorPreference.objects.get(id=preference_id, user=user)
        preference.delete()

        return Response({
            'status': 'deleted',
            'message': f"{preference.preference_type.capitalize()} color preference for '{preference.name}' has been deleted."
        })

    except UserColorPreference.DoesNotExist:
        return JsonResponse("Preference not found", status.HTTP_404_NOT_FOUND)


@api_view(["DELETE"])
@permission_classes([IsAuthenticated])

def reset_color_preferences(request):
    user = request.user
    preference_type = request.query_params.get('type')

    if preference_type and preference_type not in ['motif', 'stage']:
        return JsonResponse("Invalid preference type", status.HTTP_400_BAD_REQUEST)

    if preference_type:
        UserColorPreference.objects.filter(user=user, preference_type=preference_type).delete()
        message = f"All {preference_type} color preferences have been reset."
    else:
        UserColorPreference.objects.filter(user=user).delete()
        message = "All color preferences have been reset."

    return Response({
        'status': 'reset',
        'message': message
    })