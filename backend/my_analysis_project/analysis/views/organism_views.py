import json
from django.http import JsonResponse
from drf_yasg import openapi
from drf_yasg.utils import swagger_auto_schema
from rest_framework.decorators import api_view

from my_analysis_project.auth_app.models import UserColorPreference
from my_analysis_project.lib.analysis.motif_presets import MotifPresets
from my_analysis_project.lib.analysis.organism import Organism
from my_analysis_project.lib.analysis.organism_presets import OrganismPresets
from my_analysis_project.lib.analysis.stage_and_color import StageAndColor
from my_analysis_project.lib.genes.gene_list import GeneList
from my_analysis_project.lib.genes.gene_model import GeneModel
from my_analysis_project.analysis.models import OrganismAccess
from my_analysis_project.analysis.utils.file_utils import find_fasta_file


@swagger_auto_schema(
    method='get',
    operation_description="Returns a list of predefined organisms with access control.",
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
    user = request.user if request.user.is_authenticated else None
    all_organisms = OrganismPresets.k_organisms
    accessible_organisms = []

    for organism in all_organisms:
        has_access = False

        if organism.public:
            has_access = True
        elif user:
            user_access = OrganismAccess.objects.filter(
                organism_name=organism.name,
                access_type='user',
                user=user
            ).exists()

            if user_access:
                has_access = True
            else:
                user_groups = user.groups.all()
                group_access = OrganismAccess.objects.filter(
                    organism_name=organism.name,
                    access_type='group',
                    group__in=[g.id for g in user_groups]
                ).exists()

                if group_access:
                    has_access = True

        if has_access:
            if user:
                stage_preferences = {
                    pref.name: pref for pref in UserColorPreference.objects.filter(
                        user=user,
                        preference_type='stage'
                    )
                }

                modified_stages = []
                for stage in organism.stages:
                    if stage.stage in stage_preferences:
                        pref = stage_preferences[stage.stage]
                        modified_stage = StageAndColor(
                            stage.stage,
                            color=pref.color,
                            stroke=pref.stroke_width,
                            is_checked_by_default=stage.is_checked_by_default
                        )
                        modified_stages.append(modified_stage)
                    else:
                        modified_stages.append(stage)


                modified_organism = Organism(
                    name=organism.name,
                    filename=organism.filename,
                    description=organism.description,
                    public=organism.public,
                    take_first_transcript_only=organism.take_first_transcript_only,
                    stages=modified_stages
                )

                accessible_organisms.append(modified_organism)
            else:
                accessible_organisms.append(organism)

    organisms_data = [
        {
            "name": organism.name,
            "public": organism.public,
            "description": organism.description,
            "stages": [{"stage": stage.stage, "color": stage.color} for stage in organism.stages],
        }
        for organism in accessible_organisms
    ]

    return JsonResponse({"organisms": organisms_data})


@swagger_auto_schema(
    method='post',
    operation_description="Fetches stages and motifs for a given organism with access control.",
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
    try:
        data = json.loads(request.body)
        organism_name = data.get("organism")

        if not organism_name:
            return JsonResponse("Missing organism name", status=400)

        organism = next((org for org in OrganismPresets.k_organisms if org.name == organism_name), None)
        if not organism:
            return JsonResponse("Organism not found", status=404)

        user = request.user if request.user.is_authenticated else None
        has_access = False

        if organism.public:
            print("Organism is public" + organism.name + " " + str(organism.public))
            has_access = True

        elif user:
            user_access = OrganismAccess.objects.filter(
                organism_name=organism.name,
                access_type='user',
                user=user
            ).exists()

            if user_access:
                has_access = True
            else:
                user_groups = user.groups.all()
                group_access = OrganismAccess.objects.filter(
                    organism_name=organism.name,
                    access_type='group',
                    group__in=[g.id for g in user_groups]
                ).exists()

                if group_access:
                    has_access = True

        if not has_access:
            return JsonResponse({"error": "no access to this organism"}, status=500)

        motifs_data = []
        has_access = False
        #TODO do the same public check for motifs, i guess do it before the motifs preference. since its copy paste, maybe get it into new function.
        if user:
            motif_preferences = {
                pref.name: pref for pref in UserColorPreference.objects.filter(
                    user=user,
                    preference_type='motif'
                )
            }

            for motif in MotifPresets.get_presets():
                motif_data = {
                    "name": motif.name,
                    "definitions": motif.definitions
                }

                if motif.name in motif_preferences:
                    pref = motif_preferences[motif.name]
                    motif_data["color"] = pref.color
                    motif_data["stroke_width"] = pref.stroke_width

                motifs_data.append(motif_data)
        else:
            motifs_data = [
                {"name": motif.name, "definitions": motif.definitions}
                for motif in MotifPresets.get_presets()
            ]

        file_path = find_fasta_file(organism_name)
        if not file_path:
            return JsonResponse({"error":"Organism file not found"}, status=404)

        gene_list = GeneList.load_from_file(str(file_path))

        stages_data = {}
        for stage in organism.stages:
            stages_data[stage.stage] = {"stage": stage.stage, "color": stage.color}

            if user:
                try:
                    pref = UserColorPreference.objects.get(
                        user=user,
                        preference_type='stage',
                        name=stage.stage
                    )
                    stages_data[stage.stage]["color"] = pref.color
                    stages_data[stage.stage]["stroke"] = pref.stroke_width
                except UserColorPreference.DoesNotExist:
                    pass

        detected_stages = set(gene_list.stageKeys)
        for stage in detected_stages:
            if stage not in stages_data:
                color = GeneModel.randomColorOf(stage)
                stages_data[stage] = {"stage": stage, "color": color}

                if user:
                    try:
                        pref = UserColorPreference.objects.get(
                            user=user,
                            preference_type='stage',
                            name=stage
                        )
                        stages_data[stage]["color"] = pref.color
                        stages_data[stage]["stroke"] = pref.stroke_width
                    except UserColorPreference.DoesNotExist:
                        pass

        stages_list = list(stages_data.values())
        organism_and_stages = f"{organism_name} {'+'.join(gene_list.stageKeys)}"

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
            "stages": stages_list,
            "markers": sorted(set(marker for gene in gene_list.genes for marker in gene.markers.keys())),
        })

    except Exception as e:
        return JsonResponse({"error":"str(e)"}, status=500)