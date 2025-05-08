import json
import os
from typing import List

import settings
from analysis.models import OrganismAccess
from lib.analysis.organism import Organism
from lib.analysis.stage_and_color import StageAndColor


class OrganismPresets:
   _organisms: List[Organism] = []

   @classmethod
   def reload_data(cls):
       organisms_dir = os.path.join(settings.DATA_DIR, 'jsons')
       cls._organisms = []

       if not os.path.exists(organisms_dir):
           return False

       for filename in os.listdir(organisms_dir):
           if not filename.endswith('.json'):
               continue

           file_path = os.path.join(organisms_dir, filename)
           try:
               with open(file_path, 'r') as f:
                   org_data = json.load(f)

               stages = [
                   StageAndColor(sd["name"], sd["color"],
                                 is_checked_by_default=sd.get("is_checked_by_default", True))
                   for sd in org_data.get("stages", [])
               ]

               cls._organisms.append(Organism(
                   public=org_data.get("public", False),
                   name=org_data["name"],
                   filename=org_data["filename"],
                   description=org_data.get("description", ""),
                   stages=stages,
                   take_first_transcript_only=org_data.get("take_first_transcript_only", True)
               ))
           except:
               return False
       cls.k_organisms = cls._organisms
       return len(cls._organisms) > 0

   @classmethod
   def get_organisms(cls):
       if not cls._organisms:
           cls.reload_data()

       for organism in cls._organisms:
           any_access_records = OrganismAccess.objects.filter(
               organism_name=organism.filename
           ).exists()

           if any_access_records:
               public_access = OrganismAccess.objects.filter(
                   organism_name=organism.filename,
                   access_type='public'
               ).exists()
               organism.public = public_access

       return cls._organisms

   @classmethod
   def get_organism_by_name(cls, name):
       organisms = cls.get_organisms()
       return next((org for org in organisms if org.name == name), None)

   @classmethod
   def get_organism_by_filename(cls, filename):
       organisms = cls.get_organisms()
       return next((org for org in organisms if org.filename == filename), None)

   @classmethod
   def get_public_organisms(cls):
       organisms = cls.get_organisms()
       return [org for org in organisms if org.public]


try:
   OrganismPresets.reload_data()
except Exception:
   OrganismPresets._organisms = []
   OrganismPresets.k_organisms = []
