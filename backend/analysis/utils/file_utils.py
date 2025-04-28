import os
import logging
from pathlib import Path
from typing import Optional

from django.conf import settings

logger = logging.getLogger(__name__)


def find_fasta_file(organism_filename):
    if not organism_filename:
        return None

    fasta_dir = settings.DATA_DIR / 'fasta_files'
    if not fasta_dir.exists():
        return None

    file_path = fasta_dir / organism_filename

    if file_path.exists():
        return str(file_path)

    return None