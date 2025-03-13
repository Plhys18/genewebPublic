from concurrent.futures import ThreadPoolExecutor

from django.http import JsonResponse
from drf_yasg import openapi
from drf_yasg.utils import swagger_auto_schema
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from asgiref.sync import async_to_sync, sync_to_async

from my_analysis_project.lib.analysis.motif_presets import MotifPresets
from my_analysis_project.lib.analysis.organism_presets import OrganismPresets
from my_analysis_project.lib.genes.stage_selection import StageSelection, FilterStrategy, FilterSelection
from my_analysis_project.auth_app.models import AnalysisHistory
from my_analysis_project.lib.genes.gene_model import GeneModel, AnalysisOptions
from my_analysis_project.views import find_fasta_file


@swagger_auto_schema(
    method='post',
    operation_description="Start an analysis with provided organism, motifs, and stages.",
    request_body=openapi.Schema(
        type=openapi.TYPE_OBJECT,
        properties={
            'organism': openapi.Schema(type=openapi.TYPE_STRING),
            'motifs': openapi.Schema(type=openapi.TYPE_ARRAY, items=openapi.Items(type=openapi.TYPE_STRING)),
            'stages': openapi.Schema(type=openapi.TYPE_ARRAY, items=openapi.Items(type=openapi.TYPE_STRING)),
            'params': openapi.Schema(type=openapi.TYPE_OBJECT)
        },
        required=['organism', 'motifs', 'stages']
    ),
    responses={
        200: "Analysis started",
        400: "Missing parameters"
    }
)
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def run_analysis(request):
    """Runs an analysis and stores the results in the database."""
    return async_to_sync(_async_run_analysis)(request)  # Convert async to sync


async def _async_run_analysis(request):
    """
    Handles the async analysis workflow and stores results in the database.
    """
    try:
        user = request.user
        data = request.data
        print(f"🔍 DEBUG: Received request payload: {data}")

        organism_name = data.get("organism")
        motif_names = data.get("motifs", [])  # Get list of motif names
        stage_names = data.get("stages", [])  # Get list of stage names
        params = data.get("params", {})

        if not motif_names:
            print("❌ ERROR: No motifs provided!")
            return JsonResponse({"error": "No motifs provided"}, status=400)

        if not stage_names:
            print("❌ ERROR: No stages provided!")
            return JsonResponse({"error": "No stages provided"}, status=400)


        print(f"🔍 DEBUG: Extracted motif names: {motif_names}")
        print(f"🔍 DEBUG: Extracted stage names: {stage_names}")

        # ✅ Create GeneModel
        gene_model = GeneModel()
        assert params
        assert params
        gene_model.analysisOptions = AnalysisOptions.fromJson(params)
        print(f"✅ DEBUG: Created GeneModel")
        assert gene_model.analysisOptions
        real_motifs = [m for m in MotifPresets.get_presets() if m.name in motif_names]
        if not real_motifs:
            print("❌ ERROR: No valid motifs found in presets")
            return JsonResponse({"error": "No valid motifs found in presets"}, status=400)

        print(f"✅ DEBUG: Resolved motifs from presets: {real_motifs}")

        # ✅ Fetch Stages From Organism Presets (If Needed)
        organism = next((org for org in OrganismPresets.k_organisms if org.name == organism_name), None)
        if organism:
            available_stages = set(stage.stage for stage in organism.stages)
            selected_stages = [stage for stage in stage_names if stage in available_stages]
        else:
            selected_stages = stage_names

        if not selected_stages:
            print("❌ ERROR: No valid stages found")
            return JsonResponse({"error": "No valid stages found"}, status=400)

        print(f"✅ DEBUG: Final valid stages: {selected_stages}")

        stage_selection = StageSelection(
            selectedStages=selected_stages,
            strategy=FilterStrategy.top,
            selection=FilterSelection.percentile,
            percentile=0.9,
            count=3200
        )

        print(f"✅ DEBUG: Created StageSelection object: {stage_selection}")

        # ✅ Set motifs and stages in GeneModel
        gene_model.setMotifs(real_motifs)
        gene_model.setStageSelection(stage_selection)

        # ✅ Load the gene list
        file_path = find_fasta_file(organism_name)
        if not file_path:
            print("❌ ERROR: Organism file not found")
            return JsonResponse({"error": "Organism file not found"}, status=404)

        print(f"✅ Found FASTA file at: {file_path}")

        await gene_model.loadFastaFromFile(file_path, organism)
        print("✅ DEBUG: Loaded FASTA file into GeneModel")

        # ✅ Run the analysis
        success = await gene_model.analyze()
        if not success:
            print("❌ ERROR: Analysis failed")
            return JsonResponse({"error": "Analysis was cancelled or failed"}, status=500)

        # ✅ Process results
        filtered_results = process_analysis_results(gene_model)

        # ✅ Save full results, but return only filtered data
        await sync_to_async(save_analysis_history, thread_sensitive=True)(user, organism_name, filtered_results)

        print(f"✅ DEBUG: Analysis completed successfully, saved to DB")

        return JsonResponse({"message": "Analysis complete", "results": filtered_results}, status=200)

    except Exception as e:
        print(f"❌ ERROR: {str(e)}")  # Debugging error
        return JsonResponse({"error": str(e)}, status=500)


def process_single_analysis(analysis):
    return {
        "name": analysis.name,
        "color": analysis.color,
        "stroke": analysis.stroke,
        "distribution": {
            "min": analysis.distribution.min,
            "max": analysis.distribution.max,
            "bucket_size": analysis.distribution.bucket_size,
            "name": analysis.distribution.name,
            "color": analysis.distribution.color,
            "align_marker": analysis.distribution.align_marker,
            "total_count": analysis.distribution.totalCount,
            "total_genes_count": analysis.distribution.totalGenesCount,
            "total_genes_with_motif_count": analysis.distribution.totalGenesWithMotifCount,
            "data_points": [
                {
                    "min": dp.min,
                    "max": dp.max,
                    "count": dp.count,
                    "percent": dp.percent,
                    "genes_count": dp.genesCount,
                    "genes_percent": dp.genes_percent
                }
                for dp in analysis.distribution.dataPoints
            ] if analysis.distribution.dataPoints else []
        },
    }


def process_analysis_results(gene_model):
    with ThreadPoolExecutor() as executor:
        filtered_results = list(executor.map(process_single_analysis, gene_model.analyses))

    return filtered_results

def save_analysis_history(user, organism_name, filtered_results):
    """
    Saves the analysis history to the database in a synchronous manner.
    """
    try:
        AnalysisHistory.objects.create(
            user=user,
            name=f"Analysis for {organism_name}",
            filtered_results=filtered_results
        )
        print(f"✅ DEBUG: Successfully saved analysis history for {user.username}")
    except Exception as e:
        print(f"❌ ERROR saving analysis history: {str(e)}")


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def cancel_analysis_view(request):
    """Cancels an ongoing analysis for the logged-in user"""
    return JsonResponse({"message": "Your analysis has been cancelled"}, status=200)

@swagger_auto_schema(
    method='get',
    operation_description="Get user's analysis history.",
    responses={
        200: "History retrieved successfully",
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
                "id": entry.id,  # Unique identifier for fetching full details later
                "name": entry.name,
                "created_at": entry.created_at.strftime("%Y-%m-%d %H:%M:%S"),
            } for entry in history
        ]
    })
@swagger_auto_schema(
    method='get',
    operation_description="Get user's analysis history (metadata only).",
    responses={
        200: "History retrieved successfully",
    }
)
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def get_analysis_history_list(request):
    """Returns a list of user's past analyses with metadata only."""
    user = request.user
    history = AnalysisHistory.objects.filter(user=user).order_by("-created_at")

    return JsonResponse({
        "history": [
            {
                "id": entry.id,
                "name": entry.name,
                "created_at": entry.created_at.strftime("%Y-%m-%d %H:%M:%S"),
            } for entry in history
        ]
    })

@swagger_auto_schema(
    method='get',
    operation_description="Get details of a specific analysis if it belongs to the user.",
    responses={
        200: "Analysis details retrieved successfully",
        404: "Analysis not found"
    }
)
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def get_analysis_details(request, analysis_id):
    """Returns detailed results for a specific analysis if the user owns it."""
    try:
        analysis = AnalysisHistory.objects.get(id=analysis_id, user=request.user)
        return JsonResponse({
            "id": analysis.id,
            "name": analysis.name,
            "created_at": analysis.created_at.strftime("%Y-%m-%d %H:%M:%S"),
            "filtered_results": analysis.filtered_results
        })
    except AnalysisHistory.DoesNotExist:
        return JsonResponse({"error": "Analysis not found"}, status=404)
