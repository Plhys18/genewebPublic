from django.apps import AppConfig
from pathlib import Path

from backend.my_analysis_project.analysis_app.persistentData import PersistentData


class AnalysisAppConfig(AppConfig):
    name = 'analysis_app'

    def ready(self):
        from django.conf import settings
        data_dir = settings.DATA_DIR
        fasta_path = data_dir / "organism1.fasta"
        gene_list = load_gene_list_from_file(str(fasta_path))
        PersistentData.gene_data = gene_list
        print("DEBUG: Preloaded gene data from", fasta_path)
