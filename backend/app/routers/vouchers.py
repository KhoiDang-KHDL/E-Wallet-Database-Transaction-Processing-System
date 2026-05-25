import oracledb
from fastapi import APIRouter, Depends

from app.db import get_connection
from app.db_utils import fetch_all, fetch_one, translate_oracle_error
from app.dependencies import get_current_active_user
from app.schemas import VoucherApplyRequest, VoucherApplyResponse

router = APIRouter(prefix="/vouchers", tags=["vouchers"])


@router.get("")
def list_available_vouchers(
    current_user: dict = Depends(get_current_active_user),
    connection: oracledb.Connection = Depends(get_connection),
) -> list[dict]:
    del current_user
    with connection.cursor() as cursor:
        try:
            return fetch_all(
                cursor,
                """
                SELECT voucher_id,
                       code,
                       discount_type,
                       discount_value,
                       min_order_value,
                       max_discount,
                       TO_CHAR(valid_until, 'YYYY-MM-DD HH24:MI:SS') AS valid_until,
                       amount_vouchers
                FROM vouchers
                WHERE is_active = 1
                  AND amount_vouchers > 0
                  AND (valid_until IS NULL OR valid_until >= SYSTIMESTAMP)
                ORDER BY valid_until NULLS LAST, voucher_id
                """,
            )
        except oracledb.Error as exc:
            raise translate_oracle_error(exc) from exc


@router.post("/apply", response_model=VoucherApplyResponse)
def apply_voucher(
    payload: VoucherApplyRequest,
    current_user: dict = Depends(get_current_active_user),
    connection: oracledb.Connection = Depends(get_connection),
) -> VoucherApplyResponse:
    del current_user
    with connection.cursor() as cursor:
        try:
            valid_row = fetch_one(
                cursor,
                "SELECT fn_validate_voucher(:code, :amount) AS valid FROM dual",
                {"code": payload.voucher_code, "amount": payload.amount},
            )
            valid = bool(valid_row and valid_row["valid"] == 1)
            discount_amount = 0
            if valid:
                discount_row = fetch_one(
                    cursor,
                    "SELECT fn_voucher_discount(:code, :amount) AS discount_amount FROM dual",
                    {"code": payload.voucher_code, "amount": payload.amount},
                )
                discount_amount = discount_row["discount_amount"] if discount_row else 0

                if payload.type_code == "TRANSFER":
                    type_row = fetch_one(
                        cursor,
                        "SELECT type_id FROM transaction_types WHERE type_code = 'TRANSFER'",
                    )
                    fee_row = fetch_one(
                        cursor,
                        "SELECT fn_real_fee(:type_id, :amount) AS fee_amount FROM dual",
                        {"type_id": type_row["type_id"], "amount": payload.amount},
                    )
                    fee_amount = fee_row["fee_amount"] if fee_row else 0
                    if discount_amount > fee_amount:
                        discount_amount = fee_amount
        except oracledb.Error as exc:
            raise translate_oracle_error(exc) from exc

    return VoucherApplyResponse(
        voucher_code=payload.voucher_code,
        type_code=payload.type_code,
        valid=valid,
        discount_amount=discount_amount,
        message="Voucher can be applied" if valid else "Voucher is invalid for this transaction",
    )
