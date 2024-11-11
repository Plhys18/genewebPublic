from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from app.auth.auth_handler import get_password_hash, verify_password, create_access_token
from app.auth.auth_bearer import get_current_user

router = APIRouter()

# In-memory user database (you can replace this with a real DB)
fake_users_db = {}

class User(BaseModel):
    username: str
    password: str

class UserInDB(User):
    hashed_password: str

class Token(BaseModel):
    access_token: str
    token_type: str

# User registration endpoint
@router.post("/register")
async def register_user(user: User):
    if user.username in fake_users_db:
        raise HTTPException(status_code=400, detail="Username already exists")

    hashed_password = get_password_hash(user.password)
    fake_users_db[user.username] = UserInDB(username=user.username, hashed_password=hashed_password)
    return {"message": "User registered successfully"}

# User login endpoint
@router.post("/login", response_model=Token)
async def login_user(user: User):
    db_user = fake_users_db.get(user.username)
    if not db_user or not verify_password(user.password, db_user.hashed_password):
        raise HTTPException(status_code=400, detail="Invalid credentials")

    access_token = create_access_token(data={"sub": user.username})
    return {"access_token": access_token, "token_type": "bearer"}

# Protected route that requires authentication
@router.get("/me")
async def read_users_me(current_user: str = Depends(get_current_user)):
    return {"username": current_user}
