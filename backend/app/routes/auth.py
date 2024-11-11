from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from app.auth.auth_handler import get_password_hash, verify_password, create_access_token

router = APIRouter()

# Mock database of users
fake_users_db = {
    "testuser": {"username": "testuser", "hashed_password": get_password_hash("password123")}
}

class UserLogin(BaseModel):
    username: str
    password: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str

@router.post("/login", response_model=TokenResponse)
async def login(user: UserLogin):
    db_user = fake_users_db.get(user.username)
    if db_user is None or not verify_password(user.password, db_user["hashed_password"]):
        raise HTTPException(status_code=400, detail="Invalid credentials")

    access_token = create_access_token(data={"sub": user.username})
    return {"access_token": access_token, "token_type": "bearer"}
