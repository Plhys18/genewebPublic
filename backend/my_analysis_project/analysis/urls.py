from django.urls import path

from my_analysis_project.analysis.views.analysis_views import run_analysis, get_analysis_history_list, \
    get_analysis_details, cancel_analysis_view
from my_analysis_project.analysis.views.organism_views import list_organisms, get_organism_details

urlpatterns = [
    path('analyze/', run_analysis, name='run_analysis'), # TODO change logic... this gets more information than it gets now
    path('history/', get_analysis_history_list, name='analysis_history'),
    path('history/<int:analysis_id>/', get_analysis_details, name="get_analysis_details"),
    path('cancel/', cancel_analysis_view, name='cancel_analysis'),

    path('organisms/', list_organisms, name="list_organisms"), #TODO keep, but change to what organism this user is allowed to see
                                                                     # either he site is public and he gets all or this user is logged in and he can see public + extra
    # path('set_active_organism/', set_active_organism, name="set_active_organism"), # TODO get rid of
    # path('get_active_organism/', get_active_organism, name="get_active_organism"), # TODO get rid of
    path('organism_details/', get_organism_details, name="get_organism_details"),
    # path('get_active_organism_source_gene_informations/', get_active_organism_source_gene_informations, name="get_active_organism_source_gene_informations"),
]

    # path('motifs/', get_motifs, name="motifs"),
    # path('stages/', get_active_stages, name="stages"),
