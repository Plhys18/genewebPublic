from aiofiles import os
from django.http import JsonResponse
from drf_yasg import openapi
from drf_yasg.utils import swagger_auto_schema
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated

from my_analysis_project.settings import BASE_DIR


@swagger_auto_schema(
    method='post',
    operation_description="Trigger the pipeline execution with required parameters.",
    request_body=openapi.Schema(
        type=openapi.TYPE_OBJECT,
        required=["directory", "organism_name"],
        properties={
            "directory": openapi.Schema(type=openapi.TYPE_STRING, description="Path to the directory containing input files."),
            "organism_name": openapi.Schema(type=openapi.TYPE_STRING, description="Organism folder name."),
            "with_tss": openapi.Schema(type=openapi.TYPE_BOOLEAN, description="Optional flag to include TSS processing", default=False),
        },
    ),
    responses={202: "Pipeline execution request accepted"},
)
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def run_pipeline_api(request):
    """
    API to trigger the analysis pipeline.
    """

    directory = request.data.get("directory")
    organism_name = request.data.get("organism_name")
    with_tss = request.data.get("with_tss", False)

    if not directory or not organism_name:
        return JsonResponse({"error": "Missing required parameters: 'directory' and 'organism_name'"}, status=400)

    if not os.path.exists(directory):
        return JsonResponse({"error": f"Directory '{directory}' not found"}, status=400)

    command = ["dart", "pipeline.dart", directory]
    if with_tss:
        command.append("--with-tss")

    # Placeholder response
    return JsonResponse({
        "message": "Pipeline execution request received.",
        "directory": directory,
        "organism_name": organism_name,
        "with_tss": with_tss,
        "command": " ".join(command),
    }, status=202)


from django.core.files.storage import default_storage
from django.core.files.base import ContentFile
from rest_framework.parsers import MultiPartParser

@swagger_auto_schema(
    method='post',
    operation_description="Upload input files for the pipeline (FASTA, GFF, TPM).",
    responses={
        201: openapi.Response("File uploaded successfully"),
        400: "No file provided"
    }
)
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def upload_pipeline_files(request):
    parser_classes = [MultiPartParser]

    if "file" not in request.FILES:
        return JsonResponse({"error": "No file provided"}, status=400)

    file = request.FILES["file"]
    file_path = f"pipeline_uploads/{file.name}"

    default_storage.save(file_path, ContentFile(file.read()))

    return JsonResponse({"message": "File uploaded successfully", "file_path": file_path}, status=201)

@swagger_auto_schema(
    method='get',
    operation_description="Retrieve logs from a specific pipeline execution.",
    responses={
        200: openapi.Response("Pipeline logs retrieved successfully"),
        404: "Logs not found"
    }
)
@api_view(["GET"])
def get_pipeline_logs(request, task_id):
    log_file = os.path.join(BASE_DIR, f"logs/pipeline_{task_id}.log")

    if not os.path.exists(log_file):
        return JsonResponse({"error": "Logs not found"}, status=404)

    with open(log_file, "r") as f:
        logs = f.readlines()

    return JsonResponse({"task_id": task_id, "logs": logs})