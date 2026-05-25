import oracledb
from fastapi import APIRouter, Depends, Request, status

from app.core.security import create_access_token, hash_password, verify_password
from app.db import get_connection
from app.db_utils import fetch_one, translate_oracle_error
from app.dependencies import get_current_active_user
from app.schemas import LoginRequest, RegisterRequest, TokenResponse

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", status_code=status.HTTP_201_CREATED)
def register(payload: RegisterRequest, connection: oracledb.Connection = Depends(get_connection)) -> dict:
    password_hash = hash_password(payload.password)
    with connection.cursor() as cursor:
        try:
            cursor.callproc(
                "proc_create_user_with_wallet",
                [
                    payload.full_name,
                    str(payload.email),
                    payload.phone,
                    password_hash,
                    payload.pin_code,
                    payload.currency.upper(),
                ],
            )
        except oracledb.Error as exc:
            raise translate_oracle_error(exc) from exc

    return {"message": "User registered successfully"}


@router.post("/login", response_model=TokenResponse)
def login(
    payload: LoginRequest,
    request: Request,
    connection: oracledb.Connection = Depends(get_connection),
) -> TokenResponse:
    with connection.cursor() as cursor:
        try:
            user = fetch_one(
                cursor,
                """
                SELECT user_id, password_hash, is_active
                FROM users
                WHERE phone = :phone
                """,
                {"phone": payload.phone},
            )
            if user is None or user["is_active"] != 1 or not verify_password(payload.password, user["password_hash"]):
                raise ValueError

            cursor.callproc(
                "pr_create_login_session",
                [
                    user["user_id"],
                    payload.device_info or request.headers.get("user-agent", "unknown")[:255],
                    request.client.host if request.client else None,
                ],
            )
        except ValueError:
            from fastapi import HTTPException

            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid phone or password") from None
        except oracledb.Error as exc:
            raise translate_oracle_error(exc) from exc

    token = create_access_token(subject=user["user_id"])
    return TokenResponse(access_token=token)


@router.post("/logout")
def logout(
    current_user: dict = Depends(get_current_active_user),
    connection: oracledb.Connection = Depends(get_connection),
) -> dict:
    with connection.cursor() as cursor:
        try:
            cursor.execute(
                """
                UPDATE login_sessions
                SET is_active = 0
                WHERE user_id = :user_id AND is_active = 1
                """,
                {"user_id": current_user["user_id"]},
            )
            connection.commit()
        except oracledb.Error as exc:
            connection.rollback()
            raise translate_oracle_error(exc) from exc

    return {"message": "Logged out successfully. Please discard the access token on the client."}
