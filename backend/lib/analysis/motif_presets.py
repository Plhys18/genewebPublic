import json
import logging
import settings
from lib.analysis.motif import Motif


logger = logging.getLogger(__name__)


class MotifPresets:
    _data = None
    _motifs = None
    _loaded_from_file = False

    @classmethod
    def _load_data(cls, force_reload=False):
        if cls._data is None or force_reload:
            json_path = settings.DATA_DIR / 'preset_handlers' / 'motif_presets.json'

            try:
                with open(json_path, 'r') as f:
                    cls._data = json.load(f)
                cls._loaded_from_file = True
                cls._motifs = None
            except FileNotFoundError:
                error_msg = f"Could not find organism_presets.json at {json_path}"

            except json.JSONDecodeError as e:
                error_msg = f"Invalid JSON in organism_presets.json: {str(e)}"

    @classmethod
    def reload_data(cls):
        cls._load_data(force_reload=True)
        return cls._loaded_from_file

    @classmethod
    def _get_motifs(cls):
        if cls._motifs is None:
            cls._load_data()
            cls._motifs = []

            if not cls._data or "motifs" not in cls._data:
                return []

            for motif_data in cls._data["motifs"]:
                cls._motifs.append(Motif(
                    name=motif_data["name"],
                    definitions=motif_data["definitions"],
                    public=motif_data.get("public", True)
                ))

            cls._motifs.sort(key=lambda m: m.name)

        return cls._motifs

    @classmethod
    def get_presets(cls):
        return cls._get_motifs()

    @classmethod
    def get_motifs_by_names(cls, motif_names):
        all_motifs = cls._get_motifs()
        return [m for m in all_motifs if m.name in motif_names]

    @classmethod
    def get_motif_by_name(cls, name):
        all_motifs = cls._get_motifs()
        return next((m for m in all_motifs if m.name == name), None)

    @classmethod
    def get_public_motifs(cls):
        all_motifs = cls._get_motifs()
        return [m for m in all_motifs if m.public]



MotifPresets._get_motifs()
