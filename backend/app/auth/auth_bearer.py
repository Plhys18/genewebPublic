# from fastapi.security import OAuth2PasswordBearer
# from fastapi import Depends, HTTPException, status
# from app.auth.auth_handler import decode_access_token
#
# oauth2_scheme = OAuth2PasswordBearer(tokenUrl="api/auth/login")
#
# def get_current_user(token: str = Depends(oauth2_scheme)):
#     credentials_exception = HTTPException(
#         status_code=status.HTTP_401_UNAUTHORIZED,
#         detail="Could not validate credentials",
#         headers={"WWW-Authenticate": "Bearer"},
#     )
#     username = decode_access_token(token)
#     if username is None:
#         raise credentials_exception
#     return username
