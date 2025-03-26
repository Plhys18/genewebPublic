import os
import logging
from pathlib import Path
from typing import Optional

from django.conf import settings

logger = logging.getLogger(__name__)


def find_fasta_file(organism_name: str) -> Optional[str]:
    """
    Searches for a matching .fasta file in the data directory.

    Args:
        organism_name: The name of the organism to search for

    Returns:
        The full path to the matching file if found, otherwise None
    """
    if not organism_name:
        logger.warning("Empty organism name provided")
        return None

    data_dir = Path(settings.DATA_DIR)
    if not data_dir.exists():
        logger.error(f"Data directory does not exist: {data_dir}")
        return None

    # Create a standardized search term
    search_term = organism_name.lower().replace(" ", "_")
    logger.debug(f"Searching for FASTA file matching: {search_term}")

    try:
        for file in os.listdir(data_dir):
            if file.lower().startswith(search_term) and file.endswith(".fasta"):
                file_path = data_dir / file
                logger.info(f"Found matching FASTA file: {file_path}")
                return str(file_path)

        logger.warning(f"No matching FASTA file found for organism: {organism_name}")
        return None
    except Exception as e:
        logger.exception(f"Error searching for FASTA file: {e}")
        return None