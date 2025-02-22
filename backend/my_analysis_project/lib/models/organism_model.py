from pydantic import BaseModel

class OrganismRequest(BaseModel):
    filename: str

