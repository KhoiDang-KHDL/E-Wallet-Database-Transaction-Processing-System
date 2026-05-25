import oracledb
from fastapi import Depends, HTTPException, Request, status
from fastapi.security import HTTPAuthorizationCredentials

from app.core.security import bearer_scheme, decode_access_token
from app.db import get_connection
from app.db_utils import fetch_one, translate_oracle_error


def get_current_user_id(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
) -> int:
    return decode_access_token(credentials)


def get_current_active_user(
    request: Request,
    user_id: int = Depends(get_current_user_id),
    connection: oracledb.Connection = Depends(get_connection),
) -> dict:
    del request
    with connection.cursor() as cursor:
        try:
            user = fetch_one(
                cursor,
                """
                SELECT user_id, full_name, email, phone, is_active
                FROM users
                WHERE user_id = :user_id
                """,
                {"user_id": user_id},
            )
        except oracledb.Error as exc:
            raise translate_oracle_error(exc) from exc

    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")
    if user["is_active"] != 1:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Account is inactive")
    return user
