import json

from django.http import JsonResponse
from drf_yasg import openapi
from drf_yasg.utils import swagger_auto_schema
from rest_framework.decorators import api_view

# from my_analysis_project.auth_app.models import UserSelection
from my_analysis_project.lib.analysis.motif_presets import MotifPresets
from my_analysis_project.lib.analysis.organism_presets import OrganismPresets
from my_analysis_project.lib.genes.gene_list import GeneList
from my_analysis_project.lib.genes.gene_model import GeneModel
from my_analysis_project.views import find_fasta_file


@swagger_auto_schema(
    method='get',
    operation_description="Returns a list of predefined organisms.",
    responses={
        200: openapi.Response("Organisms List", openapi.Schema(
            type=openapi.TYPE_OBJECT,
            properties={
                "organisms": openapi.Schema(
                    type=openapi.TYPE_ARRAY,
                    items=openapi.Items(type=openapi.TYPE_OBJECT, properties={
                        "name": openapi.Schema(type=openapi.TYPE_STRING),
                        "description": openapi.Schema(type=openapi.TYPE_STRING),
                        "stages": openapi.Schema(type=openapi.TYPE_ARRAY, items=openapi.Items(type=openapi.TYPE_OBJECT))
                    })
                )
            }
        ))
    }
)
@api_view(["GET"])
def list_organisms(request):
    """Returns a list of predefined organisms.
    - Public users get only public organisms.
    - Logged-in users get public + private ones.
    """
    user = request.user if request.user.is_authenticated else None

    organisms_data = [
        {
            "name": organism.name,
            "public": organism.public,
            "description": organism.description,
            "stages": [{"stage": stage.stage, "color": stage.color} for stage in organism.stages],
        }
        for organism in OrganismPresets.k_organisms
        if organism.public or user  # Show all organisms if logged in, else only public ones
        #TODO this would be place to filter it by user and his group, TBD later
    ]

    return JsonResponse({"organisms": organisms_data})


@swagger_auto_schema(
    method='post',
    operation_description="Fetches stages and motifs for a given organism.",
    request_body=openapi.Schema(
        type=openapi.TYPE_OBJECT,
        properties={
            "organism": openapi.Schema(type=openapi.TYPE_STRING)
        },
        required=["organism"]
    ),
    responses={
        200: "Organism details",
        403: "Access denied",
        404: "Organism not found"
    }
)

@api_view(["POST"])
def get_organism_details(request):
    """
    Returns motifs, stages, and gene details for a requested organism.
    - Public users can access only public organisms.
    - Logged-in users can access both public & private organisms.
    """
    try:
        data = json.loads(request.body)
        organism_name = data.get("organism")

        organism = next((org for org in OrganismPresets.k_organisms if org.name == organism_name), None)

        user = request.user if request.user.is_authenticated else None
        motifs_data = [
            {"name": motif.name, "definitions": motif.definitions}
            for motif in MotifPresets.get_presets()
        ]

        file_path = find_fasta_file(organism_name)
        if not file_path:
            return JsonResponse({"error": "Organism file not found"}, status=404)

        gene_list = GeneList.load_from_file(str(file_path))
        stages_data = {stage.stage: {"stage": stage.stage, "color": stage.color} for stage in organism.stages}

        detected_stages = set(gene_list.stageKeys)
        for stage in detected_stages:
            if stage not in stages_data:
                stages_data[stage] = {"stage": stage, "color": GeneModel.randomColorOf(stage)}

        stages_data = list(stages_data.values())

        organism_and_stages = f"{organism_name} {'+'.join(gene_list.stageKeys)}"
        # unique_marker_names = sorted(set(
        #     marker for gene in gene_list.genes for marker in gene.markers.keys()
        # ))

        return JsonResponse({
            "organism": organism.name,
            "motifs": motifs_data,
           "genes_length": len(gene_list.genes),
            "genes_keys_length": len(gene_list.stageKeys),
            "default_selected_stage_keys": gene_list.defaultSelectedStageKeys,
            "organism_and_stages": organism_and_stages,
            "stages_keys": gene_list.stageKeys,
            "colors": gene_list.colors,
            "error_count": len(gene_list.errors),
            "stages": list(stages_data),
            "markers": sorted(set(marker for gene in gene_list.genes for marker in gene.markers.keys())),
        })

    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)