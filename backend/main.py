from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routes import organism, user, auth
from app.config import settings

app = FastAPI()

# Allow CORS for frontend development
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,  # Make sure this includes your frontend URL
    allow_credentials=True,
    allow_methods=["*"],  # Allow all HTTP methods
    allow_headers=["*"],  # Allow all headers
)
# Include the modular routes for organism, user, and auth
app.include_router(organism.router, prefix="/api/organism")
app.include_router(user.router, prefix="/api/user")
app.include_router(auth.router, prefix="/api/auth")

@app.get("/")
async def root():
    return {"message": "Welcome to the Organism Processing API"}
