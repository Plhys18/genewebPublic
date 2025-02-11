# import json
# from django.http import JsonResponse, HttpResponseNotAllowed
# from django.views.decorators.csrf import csrf_exempt
#
# # Suppose you have your Python analysis logic in a file `analysis_logic.py`
# from analysis_logic import run_motif_analysis
#
# @csrf_exempt
# def upload_fasta_and_analyze(request):
#     """
#     A minimal endpoint that:
#       1) Accepts a POST request with a file in `request.FILES`.
#       2) Optionally reads additional form fields (like min, max, motif, etc.).
#       3) Runs your Python analysis logic.
#       4) Returns a JSON response with results.
#     """
#     if request.method != 'POST':
#         return HttpResponseNotAllowed(['POST'], 'Only POST is allowed')
#
#     # 1) Get file from the request
#     if 'fasta_file' not in request.FILES:
#         return JsonResponse({'error': 'No FASTA file uploaded'}, status=400)
#
#     fasta_file = request.FILES['fasta_file']
#     fasta_content = fasta_file.read()  # in memory
#
#     # 2) Optionally parse parameters from request.POST
#     # e.g. min_pos, max_pos, motif
#     # If you sent them as JSON instead of form-data, you'd parse request.body
#
#     min_pos = request.POST.get('min', -1000)
#     max_pos = request.POST.get('max', 1000)
#     motif = request.POST.get('motif', 'ACGTG')
#
#     # Convert to correct types if needed
#     try:
#         min_pos = int(min_pos)
#         max_pos = int(max_pos)
#     except ValueError:
#         return JsonResponse({'error': 'Invalid min or max'}, status=400)
#
#     # 3) Call your analysis code.
#     #    Suppose you have a function run_motif_analysis that returns a dictionary
#     #    with results (like distribution, errors, etc.)
#     #
#     # results = run_motif_analysis(
#     #     fasta_bytes=fasta_content,
#     #     min_pos=min_pos,
#     #     max_pos=max_pos,
#     #     motif=motif
#     # )
#     #
#     # For demonstration, let’s just return a dummy result:
#     results = {
#         "status": "OK",
#         "min_pos": min_pos,
#         "max_pos": max_pos,
#         "motif": motif,
#         "fasta_size": len(fasta_content),
#         "message": "Analysis complete"
#     }
#
#     # 4) Return JSON to the client
#     return JsonResponse(results)
# # my_big_project/backend/django_proj/analysis_app/views.py
# import json
# from django.http import JsonResponse
# from django.views.decorators.csrf import csrf_exempt
#
# from genes.gene_list import GeneList
# @csrf_exempt
# def run_analysis_view(request):
#     """
#     A simple endpoint that:
#       - receives POST data (file or JSON body)
#       - uses your library code
#       - returns JSON with results
#     """
#     if request.method == 'POST':
#         # parse request.FILES or request.body
#         # run your analysis:
#         # e.g. create GeneList, run an AnalysisSeries
#
#         result_data = {
#             "status": "ok",
#             "message": "analysis complete"
#             # maybe distribution data, gene counts, etc.
#         }
#         return JsonResponse(result_data)
#     else:
#         return JsonResponse({"error": "Method not allowed"}, status=405)
