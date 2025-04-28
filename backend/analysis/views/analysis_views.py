import json
from functools import wraps

from django.http import JsonResponse
from drf_yasg import openapi
from drf_yasg.utils import swagger_auto_schema
from pandas import DataFrame
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from asgiref.sync import sync_to_async

from analysis.models import AnalysisHistory
from analysis.utils.file_utils import find_fasta_file, logger
from analysis.views.analysis_utils import process_analysis_results, save_analysis_history
from analysis.views.organism_views import check_organism_access
from lib.genes.gene_model import GeneModel, AnalysisOptions
from lib.genes.stage_selection import StageSelection, FilterStrategy, FilterSelection


def async_view(func):
    """
    Decorator to handle async views safely by running them in thread pool executors,
    without synchronization issues.
    """
    import asyncio
    from concurrent.futures import ThreadPoolExecutor
    executor = ThreadPoolExecutor(max_workers=4)

    @wraps(func)
    def wrapper(request, *args, **kwargs):
        import nest_asyncio
        nest_asyncio.apply()

        event_loop = asyncio.new_event_loop()
        asyncio.set_event_loop(event_loop)

        try:
            future = asyncio.ensure_future(func(request, *args, **kwargs), loop=event_loop)
            result = event_loop.run_until_complete(future)
            return result
        finally:
            event_loop.close()

    return wrapper


async def get_organism_by_name(organism_name):
    """Get organism by name in a database-safe way."""

    @sync_to_async
    def _get_organism():
        from lib.analysis.organism_presets import OrganismPresets
        organisms = OrganismPresets.get_organisms()
        return next((o for o in organisms if o.name == organism_name), None)

    return await _get_organism()


async def get_motifs_by_names(motif_names):
    """Get motifs by names in a database-safe way."""

    @sync_to_async
    def _get_motifs():
        from lib.analysis.motif_presets import MotifPresets
        all_motifs = MotifPresets.get_presets()
        return [m for m in all_motifs if m.name in motif_names]

    return await _get_motifs()


async def check_organism_access_async(user, organism):
    """Async wrapper for the check_organism_access function."""

    @sync_to_async
    def _check_access():
        return check_organism_access(user, organism)

    return await _check_access()


@swagger_auto_schema(
    method='post',
    operation_description=
    """
**Example Request from Frontend**
```json
{
    "organism": "ExampleOrganism",
    "motifs": ["Motif1", "Motif2"],
    "stages": ["Stage1", "Stage2"],
    "params": {
        "strategy": "top",
        "selection": "percentile",
        "percentile": 0.9,
        "count": 3200
    }
}   
    """,
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
    """Runs an analysis and stores the results in the database with proper async handling."""
    try:
        user = request.user if request.user.is_authenticated else None
        data = json.loads(request.body)

        organism_name = data.get("organism")
        if not organism_name:
            return JsonResponse({"error": "Missing organism name"}, status=400)

        organism = await get_organism_by_name(organism_name)
        if not organism:
            return JsonResponse({"error": "Organism not found"}, status=404)

        selected_motifs_names = data.get("motifs", [])
        selected_stage_names = data.get("stages", [])
        params = data.get("params", {})

        if not selected_motifs_names:
            return JsonResponse({"error": "No motifs provided"}, status=400)
        if not selected_stage_names:
            return JsonResponse({"error": "No stages provided"}, status=400)

        has_access = await check_organism_access_async(user, organism)
        if not has_access:
            return JsonResponse({"error": "Access denied"}, status=403)

        real_motifs = await get_motifs_by_names(selected_motifs_names)
        if not real_motifs:
            return JsonResponse({"error": "No valid motifs found in presets"}, status=400)

        strategy_str = params.get("strategy", "top")
        selection_str = params.get("selection", "percentile")
        percentile = float(params.get("percentile", 0.9))
        count = int(params.get("count", 3200))

        strategy = FilterStrategy.top if strategy_str == "top" else FilterStrategy.bottom
        selection = FilterSelection.percentile if selection_str == "percentile" else FilterSelection.fixed

        gene_model = GeneModel()
        gene_model.analysisOptions = AnalysisOptions.fromJson(params)

        stage_selection = StageSelection(
            selectedStages=selected_stage_names,
            strategy=strategy,
            selection=selection,
            percentile=percentile,
            count=count,
        )

        gene_model.setMotifs(real_motifs)
        gene_model.setStageSelection(stage_selection)

        # Use async-safe file path finding
        file_path = await sync_to_async(find_fasta_file)(organism.filename)
        if not file_path:
            return JsonResponse({"error": "Organism file not found"}, status=404)

        # These are truly async operations
        await gene_model.loadFastaFromFile(file_path, organism)
        success = await gene_model.analyze()

        if not success:
            return JsonResponse({"error": "Analysis was cancelled or failed"}, status=500)

        filtered_results = await process_analysis_results(gene_model, user)
        await save_analysis_history(user, organism.name, organism.filename, filtered_results,
                                    selected_motifs_names, selected_stage_names, params)

        return JsonResponse({"message": "Analysis complete", "results": filtered_results}, status=200)

    except Exception as e:
        logger.exception(f"Error during analysis: {e}")
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
