import json
from pathlib import Path
from django.http import JsonResponse
from rest_framework.response import Response

from my_analysis_project import settings
from my_analysis_project.auth_app.models import UserSelection
from my_analysis_project.lib.analysis.motif_presets import MotifPresets
from my_analysis_project.lib.analysis.organism_presets import OrganismPresets
from my_analysis_project.lib.genes.gene_list import GeneList
from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import api_view, permission_classes

def list_organisms(request):
    """Returns a list of predefined organisms from `OrganismPresets`."""
    organisms_data = [
        {
            "name": organism.name,
            "public": organism.public,
            "description": organism.description,
            "stages": [{"stage": stage.stage, "color": stage.color} for stage in organism.stages],
        }
        for organism in OrganismPresets.k_organisms
    ]
    return JsonResponse({"organisms": organisms_data})

@api_view(["POST"])
@permission_classes([IsAuthenticated])
def set_active_organism(request):
    try:
        data = json.loads(request.body)
        organism_name = data.get("organism")

        if not organism_name:
            return JsonResponse({"error": "Missing organism name"}, status=400)

        selection, created = UserSelection.objects.update_or_create(
            user=request.user,
            defaults={"organism": organism_name, "selected_motifs": [], "selected_stages": []},
        )

        return JsonResponse({"message": f"Active organism set to {organism_name}"}, status=200)

    except Exception as e:
        return JsonResponse({"error": f"Failed to set active organism: {str(e)}"}, status=500)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def get_active_organism(request):
    user = request.user
    print(f"🔹 Getting active organism for user: {user.username}")

    selection = UserSelection.objects.filter(user=user).first()
    if not selection:
        print("❌ No organism selection found for user!")
        return Response({"error": "No active organism set"}, status=404)

    print(f"✅ Found selection: {selection.organism}")

    # Find the organism in k_organisms
    organism = next((org for org in OrganismPresets.k_organisms if org.name == selection.organism), None)

    if not organism:
        print("❌ Organism not found in presets!")
        return Response({"error": "Organism not found"}, status=404)

    print(f"✅ Organism found: {organism.name}")

    response_data = {
        "organism": organism.name,
        "motifs": [{"name": m.name, "definitions": m.definitions} for m in MotifPresets.get_presets()],
        "stages": [{"stage": s.stage, "color": s.color} for s in organism.stages],
    }

    print(f"📤 Sending response: {response_data}")
    return Response(response_data)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def get_organism_details(request, name):
    """Fetches details about a specific organism."""
    try:
        file_path = Path(settings.DATA_DIR) / f"{name}.fasta"
        if not file_path.exists():
            return JsonResponse({"error": "Organism not found"}, status=404)

        gene_list = GeneList.load_from_file(str(file_path))

        return JsonResponse({
            "name": name,
            "gene_count": len(gene_list.genes),
            "stage_count": len(gene_list.stageKeys),
        })
    except Exception as e:
        return JsonResponse(
            {"error": str(e)}, status=500)
