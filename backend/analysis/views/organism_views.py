from typing import Optional

from django.http import JsonResponse
from drf_yasg import openapi
from drf_yasg.utils import swagger_auto_schema
from rest_framework.decorators import api_view

from auth_app.models import UserColorPreference
from lib.analysis.motif_presets import MotifPresets
from lib.analysis.organism import Organism
from lib.analysis.organism_presets import OrganismPresets
from lib.analysis.stage_and_color import StageAndColor
from lib.genes.gene_list import GeneList
from lib.genes.gene_model import GeneModel
from analysis.models import OrganismAccess, MotifAccess
from analysis.utils.file_utils import find_fasta_file


def check_organism_access(user, organism):
    if organism.public:
        return True

    if not user or not user.is_authenticated:
        return False

    user_access = OrganismAccess.objects.filter(
        organism_name=organism.filename,
        access_type='user',
        user=user
    ).exists()

    if user_access:
        return True

    if user.groups.exists():
        user_groups = user.groups.all()
        group_access = OrganismAccess.objects.filter(
            organism_name=organism.filename,
            access_type='group',
            group__in=user_groups
        ).exists()
        return group_access

    return False

def check_motif_access(user, motif):
    """
    Check if a user has access to a specific motif.

    Args:
        user: The user to check access for (can be None for anonymous users)
        motif: The motif object to check access for

    Returns:
        bool: True if user has access, False otherwise
    """
    if not hasattr(motif, 'public') or motif.public:
        return True

    if not user:
        return False

    user_access = MotifAccess.objects.filter(
        motif_name=motif.name,
        access_type='user',
        user=user
    ).exists()

    if user_access:
        return True

    user_groups = user.groups.all()
    group_access = MotifAccess.objects.filter(
        motif_name=motif.name,
        access_type='group',
        group__in=[g.id for g in user_groups]
    ).exists()

    return group_access


def apply_user_preferences(user, organism):
    """
    Apply user color preferences to organism stages.

    Args:
        user: The authenticated user
        organism: The organism object to modify

    Returns:
        Organism: A new organism object with user preferences applied
    """
    if not user:
        return organism

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

    return Organism(
        name=organism.name,
        filename=organism.filename,
        description=organism.description,
        public=organism.public,
        take_first_transcript_only=organism.take_first_transcript_only,
        stages=modified_stages
    )


def prepare_stage_data(organism, gene_list, user=None):
    """
    Prepare stage data with user preferences applied.

    Args:
        organism: The organism object
        gene_list: The gene list data
        user: The authenticated user (optional)

    Returns:
        list: Processed stage data
    """
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

    return list(stages_data.values())


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
    best_organisms = {}
    for organism in OrganismPresets.get_organisms():
        if check_organism_access(user, organism):
            current_best = best_organisms.get(organism.name)

            if current_best is None or (organism.public and not current_best.public):
                modified_organism = apply_user_preferences(user, organism)
                best_organisms[organism.name] = modified_organism

    organisms_data = [
        {
            "name": org.name,
            "public": org.public,
            "filename": org.filename,
            "description": org.description,
            "stages": [{"stage": s.stage, "color": s.color} for s in org.stages],
        }
        for org in best_organisms.values()
    ]
    return JsonResponse({"organisms": organisms_data})



@swagger_auto_schema(
    method='get',
    operation_description="Fetches stages and motifs for a given organism with access control.",
    responses={
        200: "Organism details",
        403: "Access denied",
        404: "Organism not found"
    }
)
@api_view(["GET"])
def get_organism_details(request, file_name):
    try:
        user = request.user if request.user.is_authenticated else None
        if not file_name:
            return JsonResponse({"error": "Missing organism name"}, status=400)
        candidates = [o for o in OrganismPresets.get_organisms() if o.filename == file_name]
        if not candidates:
            return JsonResponse({"error": "Organism not found"}, status=404)
        candidates.sort(key=lambda o: not o.public)
        accessible_organism: Optional[Organism] = None
        for org in candidates:
            if check_organism_access(user, org):
                accessible_organism = org
                break

        if not accessible_organism:
            return JsonResponse({"error": "No access to this organism"}, status=403)

        organism = accessible_organism

        all_motifs = MotifPresets.get_presets()
        accessible_motifs = [motif for motif in all_motifs if check_motif_access(user, motif)]

        motifs_data = []
        if user:
            motif_preferences = {
                pref.name: pref for pref in UserColorPreference.objects.filter(
                    user=user,
                    preference_type='motif'
                )
            }

            for motif in accessible_motifs:
                motif_data = {
                    "name": motif.name,
                    "definitions": motif.definitions,
                    "public": not hasattr(motif, 'public') or motif.public
                }

                if motif.name in motif_preferences:
                    pref = motif_preferences[motif.name]
                    motif_data["color"] = pref.color
                    motif_data["stroke_width"] = pref.stroke_width

                motifs_data.append(motif_data)
        else:
            motifs_data = [
                {
                    "name": motif.name,
                    "definitions": motif.definitions,
                    "public": not hasattr(motif, 'public') or motif.public
                }
                for motif in accessible_motifs
            ]

        file_path = find_fasta_file(organism.filename)
        if not file_path:
            return JsonResponse({"error": "Organism file not found"}, status=404)

        gene_list = GeneList.load_from_file(str(file_path))
        stages_list = prepare_stage_data(organism, gene_list, user)
        organism_and_stages = f"{organism.name} {'+'.join(gene_list.stageKeys)}"
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
        return JsonResponse({"error": str(e)}, status=500)
