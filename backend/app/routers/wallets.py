import oracledb
from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.db import get_connection
from app.db_utils import fetch_all, fetch_one, raise_not_found, translate_oracle_error
from app.dependencies import get_current_active_user

router = APIRouter(prefix="/wallet", tags=["wallet"])


@router.get("")
def get_my_wallet(
    current_user: dict = Depends(get_current_active_user),
    connection: oracledb.Connection = Depends(get_connection),
) -> dict:
    with connection.cursor() as cursor:
        try:
            wallet = fetch_one(
                cursor,
                """
                SELECT wallet_id, balance, currency, wallet_status
                FROM wallets
                WHERE user_id = :user_id
                """,
                {"user_id": current_user["user_id"]},
            )
        except oracledb.Error as exc:
            raise translate_oracle_error(exc) from exc
    if wallet is None:
        raise_not_found("Wallet not found")
    return wallet


@router.get("/limits")
def list_transaction_limits(connection: oracledb.Connection = Depends(get_connection)) -> list[dict]:
    with connection.cursor() as cursor:
        try:
            return fetch_all(
                cursor,
                """
                SELECT limit_id, kyc_level, max_amount_per_trans, max_amount_per_day, max_trans_per_day
                FROM transaction_limits
                ORDER BY limit_id
                """,
            )
        except oracledb.Error as exc:
            raise translate_oracle_error(exc) from exc


@router.get("/audit-logs")
def list_my_audit_logs(
    current_user: dict = Depends(get_current_active_user),
    connection: oracledb.Connection = Depends(get_connection),
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
) -> list[dict]:
    with connection.cursor() as cursor:
        try:
            return fetch_all(
                cursor,
                """
                SELECT log_id,
                       transaction_id,
                       wallet_id,
                       action_type,
                       balance_before,
                       balance_after,
                       delta
                FROM (
                    SELECT al.*,
                           ROW_NUMBER() OVER (ORDER BY al.log_id DESC) AS rn
                    FROM audit_logs al
                    JOIN wallets w ON w.wallet_id = al.wallet_id
                    WHERE w.user_id = :user_id
                )
                WHERE rn > :offset AND rn <= :max_row
                ORDER BY rn
                """,
                {"user_id": current_user["user_id"], "offset": offset, "max_row": offset + limit},
            )
        except oracledb.Error as exc:
            raise translate_oracle_error(exc) from exc


@router.get("/lookup")
def lookup_receiver_wallet(
    phone: str = Query(min_length=8, max_length=15),
    current_user: dict = Depends(get_current_active_user),
    connection: oracledb.Connection = Depends(get_connection),
) -> dict:
    with connection.cursor() as cursor:
        try:
            receiver = fetch_one(
                cursor,
                """
                SELECT u.user_id,
                       u.full_name,
                       u.phone,
                       w.wallet_id,
                       w.wallet_status,
                       w.currency
                FROM users u
                JOIN wallets w ON w.user_id = u.user_id
                WHERE u.phone = :phone
                  AND u.is_active = 1
                """,
                {"phone": phone},
            )
        except oracledb.Error as exc:
            raise translate_oracle_error(exc) from exc

    if receiver is None:
        raise_not_found("Receiver phone was not found or receiver account is inactive")
    if receiver["user_id"] == current_user["user_id"]:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Cannot transfer to your own wallet")

    phone_value = receiver["phone"] or ""
    masked_phone = phone_value[:3] + "***" + phone_value[-3:] if len(phone_value) >= 6 else phone_value
    return {
        "receiver_wallet_id": receiver["wallet_id"],
        "full_name": receiver["full_name"],
        "phone": masked_phone,
        "wallet_status": receiver["wallet_status"],
        "currency": receiver["currency"],
    }
