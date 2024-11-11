import re

from backend.app.routes.motif import reverse_complement


def validate_motif(motif_definition):
    if not motif_definition:
        return 'Definition cannot be empty'
    for definition in motif_definition:
        if not re.match(r"^[AGCTURYNWSMKBHDV]+$", definition):
            return 'Motif definition contains invalid characters'
    return None

def calculate_reverse_complement(motif_definition):
    return reverse_complement(motif_definition)
