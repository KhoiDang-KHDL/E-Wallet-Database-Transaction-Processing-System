from fastapi import APIRouter, HTTPException, status

from app.api.deps import CurrentUser, DbSession
from app.core.config import settings
from app.core.security import create_access_token, hash_password, verify_password
from app.repositories import users as user_repo
from app.schemas.common import ok
from app.schemas.users import ChangePasswordRequest, ChangePinRequest, UserLoginRequest, UserRegisterRequest, UserUpdateRequest


router = APIRouter()


@router.post("/users/register", status_code=status.HTTP_201_CREATED)
def register(payload: UserRegisterRequest, db: DbSession):
    existing = user_repo.get_user_by_login(db, payload.email, payload.phone)
    if existing:
        raise HTTPException(status_code=409, detail="Email or phone already exists")

    user_id = user_repo.create_user(
        db,
        {
            "full_name": payload.full_name,
            "email": payload.email,
            "phone": payload.phone,
            "password_hash": hash_password(payload.password),
        },
    )
    return ok({"user_id": user_id}, "User registered successfully")


@router.post("/users/login")
def login(payload: UserLoginRequest, db: DbSession):
    user = user_repo.get_user_by_login(db, payload.email, payload.phone)
    if not user or not verify_password(payload.password, user["password_hash"]):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    if not bool(user.get("is_active", True)):
        raise HTTPException(status_code=403, detail="User is locked")

    role = "admin" if int(user["user_id"]) in settings.admin_ids else "user"
    token = create_access_token(str(user["user_id"]), {"role": role})
    return ok({"user_id": user["user_id"], "role": role, "token": token}, "Login successfully")


@router.get("/users/{user_id}")
def get_user(user_id: int, db: DbSession, current_user: CurrentUser):
    if current_user.get("role") != "admin" and int(current_user["sub"]) != user_id:
        raise HTTPException(status_code=403, detail="Cannot view another user")
    user = user_repo.get_user(db, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return ok(user)


@router.patch("/users/{user_id}")
def update_user(user_id: int, payload: UserUpdateRequest, db: DbSession, current_user: CurrentUser):
    if current_user.get("role") != "admin" and int(current_user["sub"]) != user_id:
        raise HTTPException(status_code=403, detail="Cannot update another user")
    user_repo.update_user(db, user_id, payload.model_dump(exclude_unset=True))
    return ok(message="User updated successfully")


@router.put("/users/change_password")
def change_password(payload: ChangePasswordRequest, db: DbSession, current_user: CurrentUser):
    if current_user.get("role") != "admin" and int(current_user["sub"]) != payload.user_id:
        raise HTTPException(status_code=403, detail="Cannot update another user")
    user = user_repo.get_user_with_auth(db, payload.user_id)
    if not user or not verify_password(payload.old_password, user["password_hash"]):
        raise HTTPException(status_code=400, detail="Old password is incorrect")
    user_repo.update_password_hash(db, payload.user_id, hash_password(payload.new_password))
    return ok(message="Password changed successfully")


@router.put("/users/change_pin")
def change_pin(payload: ChangePinRequest, db: DbSession, current_user: CurrentUser):
    if current_user.get("role") != "admin" and int(current_user["sub"]) != payload.user_id:
        raise HTTPException(status_code=403, detail="Cannot update another user")
    raise HTTPException(status_code=501, detail="Current database has no pin_hash column. Add this column before enabling PIN change.")
