from django.http import JsonResponse
from rest_framework.decorators import permission_classes, api_view
from rest_framework.permissions import IsAuthenticated

from my_analysis_project.lib.analysis.motif_presets import MotifPresets

@api_view(["GET"])
@permission_classes([IsAuthenticated])
def get_motifs(request):
    """Returns a list of predefined motifs (presets)."""

    motifs = MotifPresets.get_presets()
    motifs_data = [
        {"name": motif.name, "definitions": motif.definitions, "reverse_definitions": motif.reverse_definitions}
        for motif in motifs
    ]

    return JsonResponse({"motifs": motifs_data})
