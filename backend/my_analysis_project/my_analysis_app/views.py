# my_analysis_project/my_analysis_app/views.py

from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt

# Import code from your newly installed local package:
from analysis.analysis_series import AnalysisSeries
from genes.gene_list import GeneList
# etc.

@csrf_exempt
def run_analysis_view(request):
    if request.method == 'POST':
        # parse request data, e.g. motifs, min, max, etc.

        # Use your logic
        # e.g., create a GeneList, run an AnalysisSeries
        # distribution = some_function(...)

        return JsonResponse({"status": "ok", "message": "Analysis done"})
    else:
        return JsonResponse({"error": "Method not allowed"}, status=405)


def upload_fasta_view():
    return None