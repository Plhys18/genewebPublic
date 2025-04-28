#my_analysis_project/analysis/urls.py
from django.urls import path

from analysis.views.analysis_views import run_analysis, get_analysis_history_list, \
    get_analysis_details
from analysis.views.organism_views import list_organisms, get_organism_details
from analysis.views.pipeline_views import run_pipeline_api

urlpatterns = [
    path('analyze/', run_analysis, name='run_analysis'), # TODO change logic... this gets more information than it gets now
    path('history/', get_analysis_history_list, name='analysis_history'),
    path('history/<int:analysis_id>/', get_analysis_details, name="get_analysis_details"),

    path('organisms/', list_organisms, name="list_organisms"), #TODO keep, but change to what organism this user is allowed to see
                                                                 # either he site is public and he gets all or this user is logged in and he can see public + extra
    path('pipeline/', run_pipeline_api, name='run_pipeline_api'),
    path('organism_details/<str:file_name>/', get_organism_details, name="get_organism_details"),
]

    # path('motifs/', get_motifs, name="motifs"),
    # path('stages/', get_active_stages, name="stages"),
