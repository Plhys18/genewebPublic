from django.urls import path
from .views import run_analysis_view

urlpatterns = [
    path('run/', run_analysis_view, name='run_analysis'),
    # path('upload_fasta/', upload_fasta_view, name='upload_fasta'),
]
