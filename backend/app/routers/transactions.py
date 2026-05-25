import oracledb
from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.db import get_connection
from app.db_utils import fetch_all, fetch_one, raise_not_found, translate_oracle_error
from app.dependencies import get_current_active_user
from app.schemas import (
    ConfirmWithdrawRequest,
    ConfirmWithdrawResponse,
    TopUpRequest,
    TopUpResponse,
    TransactionEstimateRequest,
    TransactionEstimateResponse,
    TransferRequest,
    TransferResponse,
    WithdrawRequest,
    WithdrawResponse,
)

router = APIRouter(prefix="/transactions", tags=["transactions"])


def get_owned_wallet_id(cursor: oracledb.Cursor, user_id: int) -> int:
    wallet = fetch_one(
        cursor,
        """
        SELECT wallet_id
        FROM wallets
        WHERE user_id = :user_id
        """,
        {"user_id": user_id},
    )
    if wallet is None:
        raise_not_found("Wallet not found")
    return wallet["wallet_id"]


def resolve_receiver_wallet_id(
    cursor: oracledb.Cursor,
    sender_wallet_id: int,
    receiver_wallet_id: int | None,
    receiver_phone: str | None,
) -> int:
    if receiver_phone:
        receiver = fetch_one(
            cursor,
            """
            SELECT w.wallet_id, w.wallet_status
            FROM users u
            JOIN wallets w ON w.user_id = u.user_id
            WHERE u.phone = :phone
              AND u.is_active = 1
            """,
            {"phone": receiver_phone},
        )
        if receiver is None:
            raise_not_found("Receiver phone was not found or receiver account is inactive")
        resolved_wallet_id = receiver["wallet_id"]
    elif receiver_wallet_id is not None:
        receiver = fetch_one(
            cursor,
            """
            SELECT wallet_id, wallet_status
            FROM wallets
            WHERE wallet_id = :wallet_id
            """,
            {"wallet_id": receiver_wallet_id},
        )
        if receiver is None:
            raise_not_found("Receiver wallet not found")
        resolved_wallet_id = receiver_wallet_id
    else:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="receiver_phone or receiver_wallet_id is required",
        )

    if resolved_wallet_id == sender_wallet_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Cannot transfer to your own wallet")

    return resolved_wallet_id


def get_transaction_type(cursor: oracledb.Cursor, type_code: str) -> dict:
    transaction_type = fetch_one(
        cursor,
        """
        SELECT type_id, type_code
        FROM transaction_types
        WHERE type_code = :type_code
        """,
        {"type_code": type_code.upper()},
    )
    if transaction_type is None:
        raise_not_found("Transaction type not found")
    return transaction_type


def call_number_function(cursor: oracledb.Cursor, function_name: str, params: list) -> object:
    bind_names = [f"p{i}" for i in range(len(params))]
    row = fetch_one(
        cursor,
        f"SELECT {function_name}({', '.join(':' + name for name in bind_names)}) AS value FROM dual",
        {name: value for name, value in zip(bind_names, params, strict=False)},
    )
    return row["value"] if row else None


@router.post("/estimate", response_model=TransactionEstimateResponse)
def estimate_transaction(
    payload: TransactionEstimateRequest,
    current_user: dict = Depends(get_current_active_user),
    connection: oracledb.Connection = Depends(get_connection),
) -> TransactionEstimateResponse:
    del current_user
    with connection.cursor() as cursor:
        try:
            transaction_type = get_transaction_type(cursor, payload.type_code)
            fee_amount = call_number_function(cursor, "fn_real_fee", [transaction_type["type_id"], payload.amount])

            voucher_valid = False
            discount_amount = 0
            if payload.voucher_code:
                voucher_valid = bool(call_number_function(cursor, "fn_validate_voucher", [payload.voucher_code, payload.amount]))
                if voucher_valid and payload.type_code == "TRANSFER":
                    discount_amount = call_number_function(cursor, "fn_voucher_discount", [payload.voucher_code, payload.amount])
                    if discount_amount > fee_amount:
                        discount_amount = fee_amount
        except oracledb.Error as exc:
            raise translate_oracle_error(exc) from exc

    net_fee = fee_amount - discount_amount
    if payload.type_code in {"TRANSFER", "WITHDRAW"}:
        total_deduct = payload.amount + net_fee
        receiver_amount = payload.amount
    elif payload.type_code == "TOP_UP":
        total_deduct = payload.amount
        receiver_amount = payload.amount
    else:
        total_deduct = payload.amount + net_fee
        receiver_amount = payload.amount

    return TransactionEstimateResponse(
        type_code=payload.type_code,
        amount=payload.amount,
        fee_amount=fee_amount,
        voucher_code=payload.voucher_code,
        voucher_valid=voucher_valid,
        discount_amount=discount_amount,
        total_deduct=total_deduct,
        receiver_amount=receiver_amount,
        net_fee=net_fee,
    )


@router.post("/top-up", response_model=TopUpResponse)
def top_up_wallet(
    payload: TopUpRequest,
    current_user: dict = Depends(get_current_active_user),
    connection: oracledb.Connection = Depends(get_connection),
) -> TopUpResponse:
    with connection.cursor() as cursor:
        try:
            wallet_id = get_owned_wallet_id(cursor, current_user["user_id"])
            out_order_id = cursor.var(oracledb.NUMBER)
            out_transaction_id = cursor.var(oracledb.NUMBER)
            out_status = cursor.var(oracledb.STRING)

            cursor.callproc(
                "sp_top_up_wallet",
                [
                    wallet_id,
                    payload.method_id,
                    payload.amount,
                    payload.idempotency_key,
                    1 if payload.gateway_success else 0,
                    payload.gateway_ref,
                    payload.description,
                    out_order_id,
                    out_transaction_id,
                    out_status,
                ],
            )
            connection.commit()
        except oracledb.Error as exc:
            connection.rollback()
            raise translate_oracle_error(exc) from exc

    transaction_id = out_transaction_id.getvalue()
    return TopUpResponse(
        order_id=int(out_order_id.getvalue()),
        transaction_id=int(transaction_id) if transaction_id is not None else None,
        status=out_status.getvalue(),
    )


@router.post("/withdraw", response_model=WithdrawResponse)
def withdraw_from_wallet(
    payload: WithdrawRequest,
    current_user: dict = Depends(get_current_active_user),
    connection: oracledb.Connection = Depends(get_connection),
) -> WithdrawResponse:
    with connection.cursor() as cursor:
        try:
            wallet_id = get_owned_wallet_id(cursor, current_user["user_id"])
            out_order_id = cursor.var(oracledb.NUMBER)
            out_transaction_id = cursor.var(oracledb.NUMBER)
            out_reference_code = cursor.var(oracledb.STRING)
            out_status = cursor.var(oracledb.STRING)

            cursor.callproc(
                "sp_withdraw_request",
                [
                    wallet_id,
                    payload.method_id,
                    payload.amount,
                    payload.pin_code,
                    payload.idempotency_key,
                    payload.description,
                    out_order_id,
                    out_transaction_id,
                    out_reference_code,
                    out_status,
                ],
            )
            connection.commit()
        except oracledb.Error as exc:
            connection.rollback()
            raise translate_oracle_error(exc) from exc

    transaction_id = out_transaction_id.getvalue()
    return WithdrawResponse(
        order_id=int(out_order_id.getvalue()),
        transaction_id=int(transaction_id) if transaction_id is not None else None,
        reference_code=out_reference_code.getvalue(),
        status=out_status.getvalue(),
    )


@router.post("/withdraw/{order_id}/confirm", response_model=ConfirmWithdrawResponse)
def confirm_withdraw_for_demo(
    order_id: int,
    payload: ConfirmWithdrawRequest,
    current_user: dict = Depends(get_current_active_user),
    connection: oracledb.Connection = Depends(get_connection),
) -> ConfirmWithdrawResponse:
    with connection.cursor() as cursor:
        try:
            wallet_id = get_owned_wallet_id(cursor, current_user["user_id"])
            order_row = fetch_one(
                cursor,
                """
                SELECT fo.order_id, t.transaction_id
                FROM fund_orders fo
                JOIN transactions t
                  ON t.sender_wallet_id = fo.wallet_id
                 AND t.description LIKE '%WITHDRAW_ORDER_ID=' || fo.order_id || '%'
                WHERE fo.order_id = :order_id
                  AND fo.wallet_id = :wallet_id
                """,
                {"order_id": order_id, "wallet_id": wallet_id},
            )
            if order_row is None:
                raise_not_found("Withdraw order not found")

            out_status = cursor.var(oracledb.STRING)
            cursor.callproc(
                "sp_confirm_withdraw",
                [
                    order_id,
                    order_row["transaction_id"],
                    1 if payload.gateway_success else 0,
                    payload.gateway_ref,
                    out_status,
                ],
            )
            connection.commit()
        except oracledb.Error as exc:
            connection.rollback()
            raise translate_oracle_error(exc) from exc

    return ConfirmWithdrawResponse(status=out_status.getvalue())


@router.post("/transfer", response_model=TransferResponse)
def transfer_money(
    payload: TransferRequest,
    current_user: dict = Depends(get_current_active_user),
    connection: oracledb.Connection = Depends(get_connection),
) -> TransferResponse:
    with connection.cursor() as cursor:
        try:
            sender_wallet_id = get_owned_wallet_id(cursor, current_user["user_id"])
            receiver_wallet_id = resolve_receiver_wallet_id(
                cursor,
                sender_wallet_id,
                payload.receiver_wallet_id,
                payload.receiver_phone,
            )
            out_transaction_id = cursor.var(oracledb.NUMBER)
            out_reference_code = cursor.var(oracledb.STRING)
            out_status = cursor.var(oracledb.STRING)

            cursor.callproc(
                    "sp_transfer_money",
                    [
                        sender_wallet_id,
                    receiver_wallet_id,
                    payload.amount,
                    payload.pin_code,
                    payload.voucher_code,
                    payload.description,
                    out_transaction_id,
                    out_reference_code,
                    out_status,
                ],
            )
            connection.commit()
        except oracledb.Error as exc:
            connection.rollback()
            raise translate_oracle_error(exc) from exc

    return TransferResponse(
        transaction_id=int(out_transaction_id.getvalue()),
        reference_code=out_reference_code.getvalue(),
        status=out_status.getvalue(),
    )


@router.get("")
def list_my_transactions(
    current_user: dict = Depends(get_current_active_user),
    connection: oracledb.Connection = Depends(get_connection),
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
) -> list[dict]:
    with connection.cursor() as cursor:
        try:
            wallet_id = get_owned_wallet_id(cursor, current_user["user_id"])
            return fetch_all(
                cursor,
                """
                SELECT transaction_id,
                       type_code,
                       sender_wallet_id,
                       receiver_wallet_id,
                       amount,
                       fee_amount,
                       status,
                       reference_code,
                       description,
                       created_at,
                       updated_at
                FROM (
                    SELECT t.transaction_id,
                           tt.type_code,
                           t.sender_wallet_id,
                           t.receiver_wallet_id,
                           t.amount,
                           t.fee_amount,
                           t.status,
                           t.reference_code,
                           t.description,
                           TO_CHAR(t.created_at, 'YYYY-MM-DD HH24:MI:SS') AS created_at,
                           TO_CHAR(t.updated_at, 'YYYY-MM-DD HH24:MI:SS') AS updated_at,
                           ROW_NUMBER() OVER (ORDER BY t.created_at DESC, t.transaction_id DESC) AS rn
                    FROM transactions t
                    LEFT JOIN transaction_types tt ON tt.type_id = t.type_id
                    WHERE t.sender_wallet_id = :wallet_id
                       OR t.receiver_wallet_id = :wallet_id
                )
                WHERE rn > :offset AND rn <= :max_row
                ORDER BY rn
                """,
                {"wallet_id": wallet_id, "offset": offset, "max_row": offset + limit},
            )
        except oracledb.Error as exc:
            raise translate_oracle_error(exc) from exc


@router.get("/{transaction_id}")
def get_my_transaction(
    transaction_id: int,
    current_user: dict = Depends(get_current_active_user),
    connection: oracledb.Connection = Depends(get_connection),
) -> dict:
    with connection.cursor() as cursor:
        try:
            wallet_id = get_owned_wallet_id(cursor, current_user["user_id"])
            transaction = fetch_one(
                cursor,
                """
                SELECT t.transaction_id,
                       tt.type_code,
                       t.sender_wallet_id,
                       t.receiver_wallet_id,
                       t.amount,
                       t.fee_amount,
                       t.status,
                       t.reference_code,
                       t.description,
                       TO_CHAR(t.created_at, 'YYYY-MM-DD HH24:MI:SS') AS created_at,
                       TO_CHAR(t.updated_at, 'YYYY-MM-DD HH24:MI:SS') AS updated_at
                FROM transactions t
                LEFT JOIN transaction_types tt ON tt.type_id = t.type_id
                WHERE t.transaction_id = :transaction_id
                  AND (t.sender_wallet_id = :wallet_id OR t.receiver_wallet_id = :wallet_id)
                """,
                {"transaction_id": transaction_id, "wallet_id": wallet_id},
            )
        except oracledb.Error as exc:
            raise translate_oracle_error(exc) from exc
    if transaction is None:
        raise_not_found("Transaction not found")
    return transaction


@router.post("/{transaction_id}/cancel")
def cancel_pending_transaction(
    transaction_id: int,
    current_user: dict = Depends(get_current_active_user),
    connection: oracledb.Connection = Depends(get_connection),
) -> dict:
    with connection.cursor() as cursor:
        try:
            wallet_id = get_owned_wallet_id(cursor, current_user["user_id"])
            transaction = fetch_one(
                cursor,
                """
                SELECT transaction_id, status, description
                FROM transactions
                WHERE transaction_id = :transaction_id
                  AND (sender_wallet_id = :wallet_id OR receiver_wallet_id = :wallet_id)
                FOR UPDATE
                """,
                {"transaction_id": transaction_id, "wallet_id": wallet_id},
            )
            if transaction is None:
                raise_not_found("Transaction not found")
            if transaction["status"] != "PENDING":
                raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Only PENDING transactions can be cancelled")

            audit_count = fetch_one(
                cursor,
                "SELECT COUNT(*) AS count FROM audit_logs WHERE transaction_id = :transaction_id",
                {"transaction_id": transaction_id},
            )["count"]
            if audit_count > 0:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Cannot cancel because this transaction has already affected wallet balance",
                )

            cursor.execute(
                "UPDATE transactions SET status = 'FAILED' WHERE transaction_id = :transaction_id",
                {"transaction_id": transaction_id},
            )

            description = transaction.get("description") or ""
            for marker in ("TOP_UP_ORDER_ID=", "WITHDRAW_ORDER_ID="):
                if marker in description:
                    suffix = description.split(marker, 1)[1].split("|", 1)[0].strip()
                    if suffix.isdigit():
                        cursor.execute(
                            """
                            UPDATE fund_orders
                            SET status = 'FAILED'
                            WHERE order_id = :order_id
                              AND wallet_id = :wallet_id
                              AND status = 'PENDING'
                            """,
                            {"order_id": int(suffix), "wallet_id": wallet_id},
                        )
                    break

            connection.commit()
        except oracledb.Error as exc:
            connection.rollback()
            raise translate_oracle_error(exc) from exc

    return {"message": "Transaction cancelled successfully"}


@router.get("/{transaction_id}/receipt")
def get_transaction_receipt(
    transaction_id: int,
    current_user: dict = Depends(get_current_active_user),
    connection: oracledb.Connection = Depends(get_connection),
) -> dict:
    with connection.cursor() as cursor:
        try:
            wallet_id = get_owned_wallet_id(cursor, current_user["user_id"])
            transaction = fetch_one(
                cursor,
                """
                SELECT t.transaction_id,
                       tt.type_code,
                       t.sender_wallet_id,
                       t.receiver_wallet_id,
                       t.amount,
                       t.fee_amount,
                       t.status,
                       t.reference_code,
                       t.description,
                       TO_CHAR(t.created_at, 'YYYY-MM-DD HH24:MI:SS') AS created_at,
                       TO_CHAR(t.updated_at, 'YYYY-MM-DD HH24:MI:SS') AS updated_at
                FROM transactions t
                LEFT JOIN transaction_types tt ON tt.type_id = t.type_id
                WHERE t.transaction_id = :transaction_id
                  AND (t.sender_wallet_id = :wallet_id OR t.receiver_wallet_id = :wallet_id)
                """,
                {"transaction_id": transaction_id, "wallet_id": wallet_id},
            )
            if transaction is None:
                raise_not_found("Transaction not found")
            if transaction["status"] != "COMPLETED":
                raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Receipt is available only for COMPLETED transactions")

            audit_logs = fetch_all(
                cursor,
                """
                SELECT log_id, transaction_id, wallet_id, action_type,
                       balance_before, balance_after, delta
                FROM audit_logs
                WHERE transaction_id = :transaction_id
                ORDER BY log_id
                """,
                {"transaction_id": transaction_id},
            )
        except oracledb.Error as exc:
            raise translate_oracle_error(exc) from exc

    return {"transaction": transaction, "audit_logs": audit_logs}
