#my_analysis_project/analysis/urls.py
from django.urls import path

from analysis.views.analysis_views import run_analysis, get_analysis_history_list, \
    get_analysis_details
from analysis.views.organism_views import list_organisms, get_organism_details

urlpatterns = [
    path('analyze/', run_analysis, name='run_analysis'),
    
    path('history/', get_analysis_history_list, name='analysis_history'),
    path('history/<int:analysis_id>/', get_analysis_details, name="get_analysis_details"),

    path('organisms/', list_organisms, name="list_organisms"),
    path('organism_details/<str:file_name>/', get_organism_details, name="get_organism_details"),
]

    # path('motifs/', get_motifs, name="motifs"),
    # path('stages/', get_active_stages, name="stages"),
