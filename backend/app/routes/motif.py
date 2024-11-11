from flask import Blueprint, request, jsonify
from services.motif_service import validate_motif, calculate_reverse_complement

motif_bp = Blueprint('motif', __name__)

@motif_bp.route('/motifs/validate', methods=['POST'])
def validate():
    data = request.get_json()
    motif_definition = data.get('motif_definition', '')
    error = validate_motif(motif_definition)
    return jsonify({'error': error})

@motif_bp.route('/motifs/reverse_complement', methods=['POST'])
def reverse_complement():
    data = request.get_json()
    motif_definition = data.get('motif_definition', '')
    reverse_complement = calculate_reverse_complement(motif_definition)
    return jsonify({'reverse_complement': reverse_complement})
