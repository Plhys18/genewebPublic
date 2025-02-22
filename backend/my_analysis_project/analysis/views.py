import json

from django.http import HttpResponseNotAllowed, JsonResponse
from django.views.decorators.csrf import csrf_exempt

from analysis_app.persistentData import PersistentData
from lib.analysis.analysis_result import AnalysisResult



@csrf_exempt
def run_analysis_view(request):
    if request.method != 'POST':
        return HttpResponseNotAllowed(['POST'], 'Only POST is allowed')

    try:
        params = json.loads(request.body)
    except json.JSONDecodeError:
        return JsonResponse({'error': 'Invalid JSON'}, status=400)

    try:
        analysis_name = params.get('name')
        min_val = int(params.get('min'))
        max_val = int(params.get('max'))
        bucket_size = int(params.get('interval'))
        align_marker = params.get('alignMarker')
        color = params.get('color')
        stroke = int(params.get('stroke'))
        motif_json = params.get('motif')
        if not motif_json:
            raise ValueError("Motif parameter is missing.")

        motif = Motif.fromJson(motif_json)
    except Exception as e:
        return JsonResponse({'error': f'Invalid analysis parameters: {str(e)}'}, status=400)

    # Retrieve gene data from persistent storage (preloaded at startup)
    gene_list = PersistentData.gene_data
    if gene_list is None:
        return JsonResponse({'error': 'Gene data not loaded on server'}, status=500)

    # Run the analysis using your library logic
    try:
        analysis_series = AnalysisSeries.run(
            gene_list=gene_list,
            no_overlaps=True,
            motif=motif,
            name=analysis_name,
            color=color,  # color is expected to be a string here, e.g., "#RRGGBB"
            min=min_val,
            max=max_val,
            bucket_size=bucket_size,
            align_marker=align_marker,
            stroke=stroke,
            visible=True,
        )
    except Exception as e:
        return JsonResponse({'error': f'Error during analysis: {str(e)}'}, status=500)

    # Return the analysis result as JSON
    return JsonResponse(analysis_series.toJson())
