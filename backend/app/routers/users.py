import oracledb
from fastapi import APIRouter, Depends, HTTPException, status

from app.core.security import hash_password, verify_password
from app.db import get_connection
from app.db_utils import fetch_one, translate_oracle_error
from app.dependencies import get_current_active_user
from app.schemas import ChangePasswordRequest, ChangePinRequest, UpdateProfileRequest, UserProfile

router = APIRouter(prefix="/me", tags=["me"])


@router.get("", response_model=UserProfile)
def get_my_profile(
    current_user: dict = Depends(get_current_active_user),
    connection: oracledb.Connection = Depends(get_connection),
) -> dict:
    with connection.cursor() as cursor:
        try:
            profile = fetch_one(
                cursor,
                """
                SELECT user_id,
                       full_name,
                       email,
                       phone,
                       kyc_status,
                       TO_CHAR(created_at, 'YYYY-MM-DD HH24:MI:SS') AS created_at,
                       TO_CHAR(updated_at, 'YYYY-MM-DD HH24:MI:SS') AS updated_at
                FROM users
                WHERE user_id = :user_id
                """,
                {"user_id": current_user["user_id"]},
            )
        except oracledb.Error as exc:
            raise translate_oracle_error(exc) from exc
    return profile


@router.put("")
def update_my_profile(
    payload: UpdateProfileRequest,
    current_user: dict = Depends(get_current_active_user),
    connection: oracledb.Connection = Depends(get_connection),
) -> dict:
    if payload.full_name is None and payload.email is None and payload.phone is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="At least one profile field must be provided",
        )

    with connection.cursor() as cursor:
        try:
            existing = fetch_one(
                cursor,
                """
                SELECT full_name, email, phone
                FROM users
                WHERE user_id = :user_id
                """,
                {"user_id": current_user["user_id"]},
            )
            if existing is None:
                raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

            cursor.callproc(
                "proc_update_user_info",
                [
                    current_user["user_id"],
                    payload.full_name if payload.full_name is not None else existing["full_name"],
                    str(payload.email) if payload.email is not None else existing["email"],
                    payload.phone if payload.phone is not None else existing["phone"],
                ],
            )
        except oracledb.Error as exc:
            raise translate_oracle_error(exc) from exc
    return {"message": "Profile updated successfully"}


@router.put("/password")
def change_my_password(
    payload: ChangePasswordRequest,
    current_user: dict = Depends(get_current_active_user),
    connection: oracledb.Connection = Depends(get_connection),
) -> dict:
    with connection.cursor() as cursor:
        try:
            row = fetch_one(
                cursor,
                "SELECT password_hash FROM users WHERE user_id = :user_id",
                {"user_id": current_user["user_id"]},
            )
            if row is None or not verify_password(payload.current_password, row["password_hash"]):
                from fastapi import HTTPException, status

                raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Current password is incorrect")

            cursor.callproc(
                "proc_change_user_password",
                [current_user["user_id"], hash_password(payload.new_password)],
            )
        except oracledb.Error as exc:
            raise translate_oracle_error(exc) from exc
    return {"message": "Password changed successfully"}


@router.put("/pin")
def change_my_pin(
    payload: ChangePinRequest,
    current_user: dict = Depends(get_current_active_user),
    connection: oracledb.Connection = Depends(get_connection),
) -> dict:
    if payload.current_pin_code == payload.new_pin_code:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="New PIN must be different from current PIN",
        )

    with connection.cursor() as cursor:
        try:
            cursor.callproc(
                "pr_update_pin_code",
                [current_user["user_id"], payload.current_pin_code, payload.new_pin_code],
            )
        except oracledb.Error as exc:
            raise translate_oracle_error(exc) from exc
    return {"message": "PIN changed successfully"}
