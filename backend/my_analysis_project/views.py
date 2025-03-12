import os
from pathlib import Path
from typing import Optional

from django.http import JsonResponse

from my_analysis_project import settings


def find_fasta_file(organism_name: str) -> Optional[str]:
    """
    Searches for a matching .fasta file in the data directory.
    Returns the correct file name if found, otherwise None.
    """
    print(organism_name)
    data_dir = Path(settings.DATA_DIR)
    print(data_dir)
    for file in os.listdir(data_dir):
        if file.lower().startswith(organism_name.lower().replace(" ", "_")) and file.endswith(".fasta"):
            return str(data_dir / file)
    return None

def check_session(request):
    """Debugging endpoint to check if session data is stored."""
    return JsonResponse({
        "active_organism": request.session.get("active_organism"),
        "active_genelist": request.session.get("active_genelist"),
    })
