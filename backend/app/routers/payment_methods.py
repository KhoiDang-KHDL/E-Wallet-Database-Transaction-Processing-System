import oracledb
from fastapi import APIRouter, Depends, HTTPException, status

from app.db import get_connection
from app.db_utils import fetch_all, fetch_one, raise_not_found, translate_oracle_error
from app.dependencies import get_current_active_user
from app.schemas import PaymentMethodCreateRequest

router = APIRouter(prefix="/payment-methods", tags=["payment-methods"])


def get_user_wallet(cursor: oracledb.Cursor, user_id: int) -> dict:
    wallet = fetch_one(
        cursor,
        """
        SELECT wallet_id, wallet_status
        FROM wallets
        WHERE user_id = :user_id
        """,
        {"user_id": user_id},
    )
    if wallet is None:
        raise_not_found("Wallet not found")
    if wallet["wallet_status"] != "ACTIVE":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Wallet is not ACTIVE")
    return wallet


@router.post("", status_code=status.HTTP_201_CREATED)
def add_payment_method(
    payload: PaymentMethodCreateRequest,
    current_user: dict = Depends(get_current_active_user),
    connection: oracledb.Connection = Depends(get_connection),
) -> dict:
    is_default = 1 if payload.is_default else 0
    with connection.cursor() as cursor:
        try:
            get_user_wallet(cursor, current_user["user_id"])
            if is_default:
                cursor.execute(
                    """
                    UPDATE payment_methods
                    SET is_default = 0
                    WHERE user_id = :user_id AND is_default = 1
                    """,
                    {"user_id": current_user["user_id"]},
                )
            cursor.execute(
                """
                INSERT INTO payment_methods (
                    user_id, method_type, provider_name, masked_number,
                    is_default, is_verified, is_active
                )
                VALUES (
                    :user_id, :method_type, :provider_name, :masked_number,
                    :is_default, 1, 1
                )
                """,
                {
                    "user_id": current_user["user_id"],
                    "method_type": payload.method_type,
                    "provider_name": payload.provider_name,
                    "masked_number": payload.masked_number,
                    "is_default": is_default,
                },
            )
            connection.commit()
        except oracledb.Error as exc:
            connection.rollback()
            raise translate_oracle_error(exc) from exc
    return {"message": "Payment method linked successfully"}


@router.get("")
def list_payment_methods(
    current_user: dict = Depends(get_current_active_user),
    connection: oracledb.Connection = Depends(get_connection),
) -> list[dict]:
    with connection.cursor() as cursor:
        try:
            rows = fetch_all(
                cursor,
                """
                SELECT method_id,
                       method_type,
                       provider_name,
                       masked_number,
                       is_default,
                       is_verified,
                       is_active
                FROM payment_methods
                WHERE user_id = :user_id
                ORDER BY is_default DESC, method_id DESC
                """,
                {"user_id": current_user["user_id"]},
            )
        except oracledb.Error as exc:
            raise translate_oracle_error(exc) from exc

    for row in rows:
        row["is_default"] = bool(row["is_default"])
        row["is_verified"] = bool(row["is_verified"])
        row["is_active"] = bool(row["is_active"])
    return rows


@router.put("/{method_id}/default")
def set_default_payment_method(
    method_id: int,
    current_user: dict = Depends(get_current_active_user),
    connection: oracledb.Connection = Depends(get_connection),
) -> dict:
    with connection.cursor() as cursor:
        try:
            method = fetch_one(
                cursor,
                """
                SELECT method_id
                FROM payment_methods
                WHERE method_id = :method_id
                  AND user_id = :user_id
                  AND is_active = 1
                  AND is_verified = 1
                """,
                {"method_id": method_id, "user_id": current_user["user_id"]},
            )
            if method is None:
                raise_not_found("Active verified payment method not found")

            cursor.execute(
                """
                UPDATE payment_methods
                SET is_default = 0
                WHERE user_id = :user_id AND is_default = 1
                """,
                {"user_id": current_user["user_id"]},
            )
            cursor.execute(
                """
                UPDATE payment_methods
                SET is_default = 1
                WHERE method_id = :method_id AND user_id = :user_id
                """,
                {"method_id": method_id, "user_id": current_user["user_id"]},
            )
            connection.commit()
        except oracledb.Error as exc:
            connection.rollback()
            raise translate_oracle_error(exc) from exc
    return {"message": "Default payment method updated successfully"}


@router.delete("/{method_id}")
def unlink_payment_method(
    method_id: int,
    current_user: dict = Depends(get_current_active_user),
    connection: oracledb.Connection = Depends(get_connection),
) -> dict:
    with connection.cursor() as cursor:
        try:
            cursor.execute(
                """
                UPDATE payment_methods
                SET is_active = 0,
                    is_default = 0
                WHERE method_id = :method_id
                  AND user_id = :user_id
                  AND is_active = 1
                """,
                {"method_id": method_id, "user_id": current_user["user_id"]},
            )
            if cursor.rowcount == 0:
                raise_not_found("Active payment method not found")
            connection.commit()
        except oracledb.Error as exc:
            connection.rollback()
            raise translate_oracle_error(exc) from exc
    return {"message": "Payment method unlinked successfully"}
