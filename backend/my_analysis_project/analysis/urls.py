from django.urls import path

from my_analysis_project.analysis.views.analysis_views import run_analysis, get_analysis_history_list, \
    get_analysis_details, cancel_analysis_view
from my_analysis_project.analysis.views.motif_views import get_motifs
from my_analysis_project.analysis.views.organism_views import list_organisms, set_active_organism, get_active_organism, \
    get_active_organism_source_gene_informations
from my_analysis_project.analysis.views.stage_views import get_active_stages

urlpatterns = [
    path('analyze/', run_analysis, name='run_analysis'),
    path('history/', get_analysis_history_list, name='analysis_history'),
    path('history/<int:analysis_id>/', get_analysis_details, name="get_analysis_details"),
    path('cancel/', cancel_analysis_view, name='cancel_analysis'),

    path('organisms/', list_organisms, name="list_organisms"),
    path('set_active_organism/', set_active_organism, name="set_active_organism"),
    path('get_active_organism/', get_active_organism, name="get_active_organism"),
    path('get_active_organism_source_gene_informations/', get_active_organism_source_gene_informations, name="get_active_organism_source_gene_informations"),

    path('motifs/', get_motifs, name="motifs"),
    path('stages/', get_active_stages, name="stages"),
]
