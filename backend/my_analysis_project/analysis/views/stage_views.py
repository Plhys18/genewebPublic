# from django.http import JsonResponse
# from rest_framework.decorators import permission_classes, api_view
# from rest_framework.permissions import IsAuthenticated
#
# from my_analysis_project.auth_app.models import UserSelection
# from my_analysis_project.lib.analysis.organism_presets import OrganismPresets
#
#
# @api_view(["GET"])
# @permission_classes([IsAuthenticated])
# def get_active_stages(request):
#     """Fetches stages for the currently active organism from the database."""
#     user_selection = UserSelection.objects.filter(user=request.user).first()
#
#     if not user_selection:
#         return JsonResponse({"error": "No active organism selected"}, status=400)
#
#     return JsonResponse({
#         "stages": [{"stage": stage} for stage in user_selection.selected_stages]
#     })
#
