import logging
from typing import Optional

from fastapi import APIRouter, HTTPException
from app.models.organism_model import OrganismRequest
from app.services.organism_service import OrganismService

router = APIRouter()


@router.post("/process")
async def process_organism(request: OrganismRequest):
    logging.info(f"Received request: {request.json()}")
    filename = request.filename
    if not filename:
        raise HTTPException(status_code=400, detail="Filename is required")

    try:
        result = await OrganismService.download_and_process_organism(filename)
        return {"message": "Processing complete", "result": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing file: {str(e)}")

@router.get("/get/species")
async def get_species(name: Optional[str] = None):
    logging.info(f"Backend received request to get species: {name}")
    if name:
        names_list = [name]
    else:
        names_list = OrganismService.get_species()
    return DatabaseServices.getSpecies(names_list)