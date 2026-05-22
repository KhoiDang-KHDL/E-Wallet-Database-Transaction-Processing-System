from decimal import Decimal
from datetime import datetime

from sqlalchemy.orm import Session

from app.repositories.base import execute, many, one


def estimate_fee(db: Session, type_code: str, amount: Decimal) -> dict:
    fee = one(
        db,
        """
        SELECT tf.fee_rate, tf.fee_fixed, tf.min_fee, tf.max_fee
        FROM transaction_fees tf
        JOIN transaction_types tt ON tt.type_id = tf.type_id
        WHERE tt.type_code = :type_code
        ORDER BY tf.effective_from DESC
        FETCH FIRST 1 ROWS ONLY
        """,
        {"type_code": type_code},
    ) or {"fee_rate": Decimal("0"), "fee_fixed": Decimal("0"), "min_fee": None, "max_fee": None}
    fee_amount = amount * Decimal(str(fee["fee_rate"])) + Decimal(str(fee["fee_fixed"]))
    if fee.get("min_fee") is not None:
        fee_amount = max(fee_amount, Decimal(str(fee["min_fee"])))
    if fee.get("max_fee") is not None:
        fee_amount = min(fee_amount, Decimal(str(fee["max_fee"])))
    return {"type_code": type_code, "amount": amount, "fee_amount": fee_amount, "total_deducted": amount + fee_amount, "voucher_discount": 0, "net_amount": amount, "can_process": True}


def create_transaction(db: Session, data: dict, fee_amount: Decimal) -> dict:
    reference_code = f"TXN{datetime.now().strftime('%Y%m%d%H%M%S%f')}"
    execute(
        db,
        """
        INSERT INTO transactions
        (type_id, sender_wallet_id, receiver_wallet_id, limit_id, voucher_id, amount, fee_amount, status, reference_code, step, created_at)
        VALUES
        (
            (SELECT type_id FROM transaction_types WHERE type_code = :type_code),
            :sender_wallet_id,
            :receiver_wallet_id,
            NULL,
            :voucher_id,
            :amount,
            :fee_amount,
            'PENDING',
            :reference_code,
            TO_NUMBER(TO_CHAR(SYSTIMESTAMP, 'HH24')),
            SYSTIMESTAMP
        )
        """,
        {
            "type_code": data["type_code"],
            "sender_wallet_id": data.get("sender_wallet_id"),
            "receiver_wallet_id": data.get("receiver_wallet_id"),
            "voucher_id": data.get("voucher_id"),
            "amount": data["amount"],
            "fee_amount": fee_amount,
            "reference_code": reference_code,
        },
    )
    db.commit()
    return get_transaction_by_reference(db, reference_code) or {}


def list_transactions(db: Session, page: int, size: int, status: str | None, type_code: str | None, user_id: int | None = None) -> dict:
    filters = []
    params = {"offset": (page - 1) * size, "size": size, "status": status, "type_code": type_code, "user_id": user_id}
    if status:
        filters.append("t.status = :status")
    if type_code:
        filters.append("tt.type_code = :type_code")
    if user_id:
        filters.append("t.sender_wallet_id IN (SELECT wallet_id FROM wallets WHERE user_id = :user_id)")
    where = " WHERE " + " AND ".join(filters) if filters else ""
    rows = many(
        db,
        f"""
        SELECT t.transaction_id, t.reference_code, tt.type_code, t.amount, t.fee_amount, t.status, t.created_at
        FROM transactions t
        LEFT JOIN transaction_types tt ON tt.type_id = t.type_id
        {where}
        ORDER BY t.created_at DESC
        OFFSET :offset ROWS FETCH NEXT :size ROWS ONLY
        """,
        params,
    )
    return {"page": page, "size": size, "total": len(rows), "transactions": rows}


def get_transaction(db: Session, transaction_id: int) -> dict | None:
    return one(
        db,
        """
        SELECT t.*, tt.type_code
        FROM transactions t
        LEFT JOIN transaction_types tt ON tt.type_id = t.type_id
        WHERE t.transaction_id = :transaction_id
        """,
        {"transaction_id": transaction_id},
    )


def get_transaction_by_reference(db: Session, reference_code: str) -> dict | None:
    return one(
        db,
        """
        SELECT t.transaction_id, t.reference_code, tt.type_code, t.amount, t.fee_amount, t.status, t.created_at
        FROM transactions t
        LEFT JOIN transaction_types tt ON tt.type_id = t.type_id
        WHERE t.reference_code = :reference_code
        """,
        {"reference_code": reference_code},
    )


def update_transaction_status(db: Session, transaction_id: int, status: str) -> None:
    execute(db, "UPDATE transactions SET status = :status WHERE transaction_id = :transaction_id", {"transaction_id": transaction_id, "status": status})
    db.commit()
