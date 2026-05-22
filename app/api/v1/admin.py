from fastapi import APIRouter, HTTPException, Query, status

from app.api.deps import AdminUser, DbSession
from app.core.security import hash_password
from app.repositories import users as user_repo
from app.schemas.common import ok
from app.schemas.users import AdminCreateUserRequest, KycUpdateRequest, UserStatusRequest, UserUpdateRequest


router = APIRouter(prefix="/admin")


@router.post("/users", status_code=status.HTTP_201_CREATED)
def create_user(payload: AdminCreateUserRequest, db: DbSession, _: AdminUser):
    user_id = user_repo.create_user(
        db,
        {
            "full_name": payload.full_name,
            "email": payload.email,
            "phone": payload.phone,
            "password_hash": hash_password(payload.password),
        },
    )
    return ok({"user_id": user_id})


@router.get("/users")
def list_users(db: DbSession, _: AdminUser, page: int = Query(1, ge=1), size: int = Query(10, ge=1, le=100)):
    return ok(user_repo.list_users(db, page, size))


@router.patch("/users/{user_id}")
def admin_update_user(user_id: int, payload: UserUpdateRequest, db: DbSession, _: AdminUser):
    user_repo.update_user(db, user_id, payload.model_dump(exclude_unset=True))
    return ok(message="User updated successfully")


@router.patch("/users/{user_id}/kyc")
def update_kyc(user_id: int, payload: KycUpdateRequest, db: DbSession, _: AdminUser):
    user_repo.update_user(db, user_id, {"kyc_status": payload.kyc_status})
    user = user_repo.get_user(db, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return ok({"user_id": user_id, "kyc_status": user["kyc_status"]}, "KYC updated successfully")


@router.patch("/users/{user_id}/status")
def update_user_status(user_id: int, payload: UserStatusRequest, db: DbSession, _: AdminUser):
    user_repo.update_user(db, user_id, {"is_active": int(payload.is_active)})
    return ok({"user_id": user_id, "is_active": payload.is_active}, "User status updated")
