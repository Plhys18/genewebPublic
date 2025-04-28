import json
from functools import wraps

from django.http import JsonResponse
from drf_yasg import openapi
from drf_yasg.utils import swagger_auto_schema
from pandas import DataFrame
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from asgiref.sync import sync_to_async, async_to_sync
from analysis.models import AnalysisHistory
from analysis.utils.file_utils import find_fasta_file
from analysis.views.analysis_utils import process_analysis_results, save_analysis_history
from analysis.views.organism_views import check_organism_access
from lib.analysis.organism_presets import OrganismPresets
from lib.genes.gene_model import GeneModel, AnalysisOptions
from lib.genes.stage_selection import StageSelection, FilterStrategy, FilterSelection


def async_view(func):
    @wraps(func)
    def wrapper(request, *args, **kwargs):
        user = None
        if hasattr(request, 'user') and request.user is not None and hasattr(request.user, 'is_authenticated'):
            if request.user.is_authenticated:
                user = request.user

        request._user = user

        return async_to_sync(func)(request, *args, **kwargs)

    return wrapper

async def get_motifs_by_names(motif_names):
    """Get motifs by names in a database-safe way."""

    @sync_to_async
    def _get_motifs():
        from lib.analysis.motif_presets import MotifPresets
        all_motifs = MotifPresets.get_presets()
        return [m for m in all_motifs if m.name in motif_names]

    return await _get_motifs()


@swagger_auto_schema(
    method='post',
    operation_description="Run analysis with proper async handling.",
    request_body=openapi.Schema(
        type=openapi.TYPE_OBJECT,
        properties={
            "organism": openapi.Schema(type=openapi.TYPE_STRING),
            "motifs": openapi.Schema(type=openapi.TYPE_ARRAY, items=openapi.Items(type=openapi.TYPE_STRING)),
            "stages": openapi.Schema(type=openapi.TYPE_ARRAY, items=openapi.Items(type=openapi.TYPE_STRING)),
            "params": openapi.Schema(type=openapi.TYPE_OBJECT),
        },
        required=["organism", "motifs", "stages"],
    ),
    responses={
        200: "Analysis started",
        400: "Missing parameters",
        403: "Access denied",
        404: "Organism not found",
    },
)
@api_view(["POST"])
@async_view
async def run_analysis(request):
    try:
        data = request.data
        organism_name = data.get("organism")
        motifs = data.get("motifs", [])
        stages = data.get("stages", [])
        params = data.get("params", {})
        user = getattr(request, "_user", None)

        @sync_to_async(thread_sensitive=True)
        def _fetch_org():
            org = OrganismPresets.get_organism_by_name(organism_name)
            if not org:
                return None, "Organism not found"
            if not check_organism_access(user, org):
                return None, "Access denied"
            return org, None

        organism, error = await _fetch_org()
        if error:
            status = 403 if error == "Access denied" else 404
            return JsonResponse({"error": error}, status=status)

        real_motifs = await get_motifs_by_names(motifs)

        gene_model = GeneModel()
        gene_model.analysisOptions = AnalysisOptions.fromJson(params)
        gene_model.setMotifs(real_motifs)
        strategy_str = params.get("strategy", "top").lower()
        selection_str = params.get("selection", "percentile").lower()
        strategy = FilterStrategy.top if strategy_str == "top" else FilterStrategy.bottom
        selection = FilterSelection.percentile if selection_str == "percentile" else FilterSelection.fixed
        percentile = float(params.get("percentile", 0.9))
        count = int(params.get("count", 3200))
        gene_model.setStageSelection(StageSelection(
            selectedStages=stages,
            strategy=strategy,
            selection=selection,
            percentile=percentile,
            count=count,
        ))

        file_path = await sync_to_async(find_fasta_file, thread_sensitive=True)(organism.filename)
        if not file_path:
            return JsonResponse({"error": "Organism file not found"}, status=404)

        await gene_model.loadFastaFromFile(file_path, organism)
        success = await gene_model.analyze()
        if not success:
            return JsonResponse({"error": "Analysis failed"}, status=500)

        filtered_results = await process_analysis_results(gene_model, user)
        if user and user.is_authenticated:
            await save_analysis_history(
                user,
                organism.name,
                organism.filename,
                filtered_results,
                motifs,
                stages,
                params,
            )

        return JsonResponse({"message": "Analysis complete", "results": filtered_results}, status=200)

    except Exception as e:
        import traceback
        print(f"ERROR in run_analysis: {e}")
        traceback.print_exc()
        return JsonResponse({"error": str(e)}, status=500)

@swagger_auto_schema(
    method='get',
    operation_description="Retrieve a list of the user's past analyses.",
    responses={
        200: openapi.Response("Analysis history retrieved successfully"),
        403: "Access denied"
    }
)
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def get_analysis_history_list(request):
    """Returns a list of user's past analyses with minimal details."""
    user = request.user
    history = AnalysisHistory.objects.filter(user=user).order_by("-created_at")

    return JsonResponse({
        "history": [
            {
                "id": entry.id,
                "name": entry.name,
                "organism": entry.organism,
                "file_name": entry.organism_filename,
                "created_at": entry.created_at.strftime("%Y-%m-%d %H:%M:%S"),
                "motifs": entry.motifs,
                "stages": entry.stages
            } for entry in history
        ]
    })


@swagger_auto_schema(
    method='get',
    operation_description="Retrieve details of a specific analysis by ID.",
    responses={
        200: openapi.Response("Analysis details retrieved successfully"),
        403: "Access denied",
        404: "Analysis not found"
    }
)
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def get_analysis_details(request, analysis_id):
    """Returns detailed results for a specific analysis if the user owns it."""
    user = request.user
    
    try:
        analysis = AnalysisHistory.objects.get(id=analysis_id, user=user)
        
        result = {
            "id": analysis.id,
            "name": analysis.name,
            "organism": analysis.organism,
            "file_name": analysis.organism_filename,
            "created_at": analysis.created_at.strftime("%Y-%m-%d %H:%M:%S"),
            "motifs": analysis.motifs,
            "stages": analysis.stages,
            "filtered_results": analysis.filtered_results,
            "settings": analysis.settings
        }
        return JsonResponse(result)
    except AnalysisHistory.DoesNotExist:
        return JsonResponse({"error": "Analysis not found"}, status=404)

@swagger_auto_schema(
    method='get',
    operation_description="Export analysis results in the specified format (CSV, JSON).",
    manual_parameters=[
        openapi.Parameter(
            'format', openapi.IN_QUERY,
            description="Format of the exported results. Options: csv, json",
            type=openapi.TYPE_STRING,
            default="csv"
        )
    ],
    responses={
        200: openapi.Response("Analysis results exported successfully"),
        400: "Invalid format",
        404: "Analysis not found"
    }
)
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def export_analysis_results(request, analysis_id):
    format_type = request.GET.get("format", "csv")

    analysis = AnalysisHistory.objects.get(id=analysis_id, user=request.user)
    if not analysis.filtered_results:
        return JsonResponse({"error": "Analysis results not found"}, status=404)
    df = DataFrame(analysis.filtered_results)

    if format_type == "csv":
        response = JsonResponse({"data": df.to_csv(index=False)})
    elif format_type == "json":
        response = JsonResponse({"data": df.to_json(orient="records")})
    elif format_type == "xlsx":
        response = JsonResponse({"error": "Excel export not implemented yet"}, status=400)
    else:
        response = JsonResponse({"error": "Invalid format"}, status=400)

    return response
