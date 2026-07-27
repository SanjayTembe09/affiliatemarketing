from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, EmailStr
import bcrypt
import jwt
import os
from database import get_db

router = APIRouter(prefix="/api/auth", tags=["Auth"])
JWT_SECRET = os.getenv("JWT_SECRET", "your_jwt_secret_key_here")

class RegisterSchema(BaseModel):
    name: str
    email: EmailStr
    password: str
    role: str
    twitter_handle: str = None

class LoginSchema(BaseModel):
    email: EmailStr
    password: str

@router.post("/register")
def register(user: RegisterSchema):
    conn = get_db()
    cursor = conn.cursor(dictionary=True)
    try:
        hashed = bcrypt.hashpw(user.password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        cursor.execute(
            'INSERT INTO users (name, email, password, role, twitter_handle) VALUES (%s, %s, %s, %s, %s)',
            (user.name, user.email, hashed, user.role, user.twitter_handle)
        )
        conn.commit()
        return {"message": "User registered successfully"}
    except Exception as err:
        raise HTTPException(status_code=400, detail=str(err))
    finally:
        cursor.close()
        conn.close()

@router.post("/login")
def login(credentials: LoginSchema):
    conn = get_db()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute('SELECT * FROM users WHERE email = %s', (credentials.email,))
        rows = cursor.fetchall()
        if not rows:
            raise HTTPException(status_code=404, detail="User not found")

        user = rows[0]
        valid = bcrypt.checkpw(credentials.password.encode('utf-8'), user['password'].encode('utf-8'))
        if not valid:
            raise HTTPException(status_code=401, detail="Wrong password")

        token = jwt.encode({"id": user['id'], "role": user['role']}, JWT_SECRET, algorithm="HS256")
        return {
            "token": token,
            "user": {"id": user['id'], "name": user['name'], "role": user['role']}
        }
    except HTTPException as he:
        raise he
    except Exception as err:
        raise HTTPException(status_code=500, detail=str(err))
    finally:
        cursor.close()
        conn.close()