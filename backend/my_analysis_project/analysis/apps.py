# from django.apps import AppConfig
#
# from my_analysis_project.analysis.persistentData import PersistentData
# from my_analysis_project.lib.genes.gene_list import GeneList
# from my_analysis_project.settings import DATA_DIR
#
#
# class AnalysisAppConfig(AppConfig):
#     name = 'analysis'
#
#     def ready(self):
#         data_dir = DATA_DIR
#         try:
#             gene_list = GeneList.load_from_file(str(fasta_file))
#             PersistentData.gene_data = gene_list
#             print("DEBUG: Loaded gene data from", fasta_file)
#         except Exception as e:
#             print("ERROR: Failed to load gene data:", e)
#
#         # Similarly, if you need to preload motifs:
#         try:
#             # For example, load presets:
#             motifs = Motif.load_presets()  # Replace with your method
#             PersistentData.motifs = motifs
#             print("DEBUG: Loaded motifs")
#         except Exception as e:
#             print("ERROR: Failed to load motifs:", e)
#         from django.conf import settings
#         data_dir = settings.DATA_DIR
#         fasta_path = data_dir / "organism1.fasta"
#         gene_list = load_gene_list_from_file(str(fasta_path))
#         PersistentData.gene_data = gene_list
#         print("DEBUG: Preloaded gene data from", fasta_path)
