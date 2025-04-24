import json
import re
import os
import logging

from lib.analysis.organism import Organism
from lib.analysis.stage_and_color import StageAndColor

logger = logging.getLogger(__name__)


class OrganismPresets:
    _data = None
    _arabidopsis_stages = None
    _organisms = None
    _loaded_from_file = False

    k_organisms = []

    @classmethod
    def _load_data(cls, force_reload=False):
        if cls._data is None or force_reload:
            dir_path = os.path.dirname(os.path.abspath(__file__))
            json_path = os.path.join(dir_path, 'organism_presets.json')

            logger.info(f"Attempting to load organism_presets.json from: {json_path}")
            print(f"Attempting to load organism_presets.json from: {json_path}")

            try:
                with open(json_path, 'r') as f:
                    cls._data = json.load(f)
                cls._loaded_from_file = True
                cls._arabidopsis_stages = None
                cls._organisms = None
                logger.info(f"Successfully loaded organism presets from {json_path}")
                print(f"Successfully loaded organism presets from {json_path}")
            except FileNotFoundError:
                error_msg = f"Could not find organism_presets.json at {json_path}"
                logger.error(error_msg)
                print(error_msg)
            except json.JSONDecodeError as e:
                error_msg = f"Invalid JSON in organism_presets.json: {str(e)}"
                logger.error(error_msg)
                print(error_msg)

    @classmethod
    def reload_data(cls):
        cls._load_data(force_reload=True)
        cls.k_organisms = cls._get_organisms()
        return cls._loaded_from_file

    @classmethod
    def _get_arabidopsis_stages(cls):
        if cls._arabidopsis_stages is None:
            cls._load_data()
            cls._arabidopsis_stages = []

            if not cls._data or "arabidopsis_stages" not in cls._data:
                logger.warning("No arabidopsis_stages data available")
                print("No arabidopsis_stages data available")
                return []

            for stage_data in cls._data["arabidopsis_stages"]:
                cls._arabidopsis_stages.append(StageAndColor(
                    stage_data["name"],
                    stage_data["color"],
                    is_checked_by_default=stage_data.get("is_checked_by_default", True)
                ))

        return cls._arabidopsis_stages

    @classmethod
    def _get_organisms(cls):
        if cls._organisms is None:
            cls._load_data()
            cls._organisms = []

            if not cls._data or "organisms" not in cls._data:
                logger.warning("No organisms data available")
                print("No organisms data available")
                return []

            for org_data in cls._data["organisms"]:
                if org_data.get("stages") == "arabidopsis_stages":
                    stages = cls._get_arabidopsis_stages()
                else:
                    stages = []
                    for stage_data in org_data.get("stages", []):
                        stages.append(StageAndColor(
                            stage_data["name"],
                            stage_data["color"],
                            is_checked_by_default=stage_data.get("is_checked_by_default", True)
                        ))

                cls._organisms.append(Organism(
                    public=org_data.get("public", False),
                    name=org_data["name"],
                    filename=org_data["filename"],
                    description=org_data.get("description", ""),
                    stages=stages,
                    take_first_transcript_only=org_data.get("take_first_transcript_only", True)
                ))

            logger.info(f"Loaded {len(cls._organisms)} organisms")
            print(f"Loaded {len(cls._organisms)} organisms")

        return cls._organisms

    @classmethod
    def get_organisms(cls):
        return cls._get_organisms()

    @classmethod
    def get_organism_by_name(cls, name):
        organisms = cls._get_organisms()
        return next((org for org in organisms if org.name == name), None)

    @classmethod
    def get_public_organisms(cls):
        organisms = cls._get_organisms()
        return [org for org in organisms if org.public]

    @staticmethod
    def organism_by_filename(filename: str) -> "Organism":
        for org in OrganismPresets._get_organisms():
            if org.filename and org.filename.startswith(filename):
                return org

        match = re.match(r"([A-Za-z0-9_]+).*", filename)
        if match:
            fallback_name = match.group(1).replace("_", " ")
        else:
            fallback_name = "Unknown organism"

        return Organism(
            name=fallback_name,
            filename=filename,
        )


try:
    OrganismPresets._get_organisms()
    OrganismPresets.k_organisms = OrganismPresets._organisms
except Exception as e:
    logger.error(f"Error initializing OrganismPresets: {str(e)}")
    print(f"Error initializing OrganismPresets: {str(e)}")