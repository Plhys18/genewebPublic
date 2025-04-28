import os
import logging
from typing import Optional

from django.conf import settings


def find_fasta_file(organism_filename: Optional[str]) -> Optional[str]:
    if not organism_filename:
        return None

    fasta_dir = settings.DATA_DIR
    if not fasta_dir.exists():
        return None

    candidates = [organism_filename]
    root, ext = os.path.splitext(organism_filename)

    if ext.lower() == '.zip':
        candidates.append(root)
    else:
        candidates.append(f"{organism_filename}.zip")

    for fname in candidates:
        path = fasta_dir / fname
        if path.exists():
            return str(path)

    return None
