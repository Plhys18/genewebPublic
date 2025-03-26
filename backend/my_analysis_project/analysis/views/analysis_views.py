import json

from asgiref.sync import async_to_sync, sync_to_async
from django.http import JsonResponse
from drf_yasg import openapi
from drf_yasg.utils import swagger_auto_schema
from pandas import DataFrame
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated

from my_analysis_project.analysis.models import AnalysisHistory
from my_analysis_project.analysis.utils.file_utils import find_fasta_file
from my_analysis_project.analysis.views.analysis_utils import save_analysis_history, process_analysis_results
from my_analysis_project.lib.analysis.motif_presets import MotifPresets
from my_analysis_project.lib.analysis.organism_presets import OrganismPresets
from my_analysis_project.lib.genes.gene_model import GeneModel, AnalysisOptions
from my_analysis_project.lib.genes.stage_selection import StageSelection, FilterStrategy, FilterSelection


@swagger_auto_schema(
    method='post',
    operation_description=
    """
#### **Example Request from Frontend**
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
def run_analysis(request):
    """Runs an analysis and stores the results in the database."""
    return async_to_sync(_async_run_analysis)(request)


async def _async_run_analysis(request):
    """
    Handles the async analysis workflow and stores results in the database.
    """
    try:
        user = request.user if request.user.is_authenticated else None
        data = json.loads(request.body)

        organism_name = data.get("organism")
        selected_motifs_names = data.get("motifs", [])
        selected_stage_names = data.get("stages", [])
        params = data.get("params", {})

        if not organism_name:
            return JsonResponse({"error": "Missing organism name"}, status=400)
        if not selected_motifs_names:
            return JsonResponse({"error": "No motifs provided"}, status=400)
        if not selected_stage_names:
            return JsonResponse({"error": "No stages provided"}, status=400)
        #TODO sanitize users input or we can end up in jail
        organism = next((org for org in OrganismPresets.k_organisms if org.name == organism_name), None)
        if not organism:
            return JsonResponse({"error": "Organism not found"}, status=404)

        # ✅ Check Access Permissions
        # if not organism.public and not user:
        #     return JsonResponse({"error": "Access denied"}, status=403)

        real_motifs = [m for m in MotifPresets.get_presets() if m.name in selected_motifs_names]
        if not real_motifs:
            return JsonResponse({"error": "No valid motifs found in presets"}, status=400)
        # TODO here after the loading of organisms motifs etc, we need

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

        file_path = find_fasta_file(organism_name)
        if not file_path:
            return JsonResponse({"error": "Organism file not found"}, status=404)

        await gene_model.loadFastaFromFile(file_path, organism)

        success = await gene_model.analyze()
        if not success:
            return JsonResponse({"error": "Analysis was cancelled or failed"}, status=500)

        filtered_results = await process_analysis_results(gene_model, user)
        await save_analysis_history(user, organism_name, filtered_results, selected_motifs_names, selected_stage_names, params)
        return JsonResponse({"message": "Analysis complete", "results": filtered_results}, status=200)

    except Exception as e:
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
            "created_at": analysis.created_at.strftime("%Y-%m-%d %H:%M:%S"),
            "filtered_results": analysis.filtered_results
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

    analysis = AnalysisHistory.get_latest_by(id=analysis_id, user=request.user)
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