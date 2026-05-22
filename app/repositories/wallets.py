from sqlalchemy.orm import Session

from app.repositories.base import execute, many, one


def get_wallet_with_logs(db: Session, user_id: int, page: int, size: int) -> dict:
    wallet = one(
        db,
        """
        SELECT wallet_id, balance, currency, wallet_status AS status, created_at, updated_at
        FROM wallets
        WHERE user_id = :user_id
        """,
        {"user_id": user_id},
    )
    logs = []
    if wallet:
        logs = many(
            db,
            """
            SELECT log_id, action_type, delta AS amount, balance_before, balance_after, transaction_id
            FROM audit_logs
            WHERE wallet_id = :wallet_id
            ORDER BY log_id DESC
            OFFSET :offset ROWS FETCH NEXT :size ROWS ONLY
            """,
            {"wallet_id": wallet["wallet_id"], "offset": (page - 1) * size, "size": size},
        )
    return {"wallet": wallet, "logs": logs}


def update_payment_method(db: Session, method_id: int, action: str) -> dict:
    if action == "SET_DEFAULT":
        method = one(db, "SELECT user_id FROM payment_methods WHERE method_id = :method_id", {"method_id": method_id})
        if method:
            execute(db, "UPDATE payment_methods SET is_default = 0 WHERE user_id = :user_id", {"user_id": method["user_id"]})
            execute(db, "UPDATE payment_methods SET is_default = 1 WHERE method_id = :method_id", {"method_id": method_id})
    elif action == "UNLINK":
        execute(db, "DELETE FROM payment_methods WHERE method_id = :method_id", {"method_id": method_id})
    db.commit()
    return one(db, "SELECT method_id, is_default, is_verified FROM payment_methods WHERE method_id = :method_id", {"method_id": method_id}) or {"method_id": method_id, "unlinked": True}


def available_vouchers(db: Session, user_id: int) -> list[dict]:
    return many(
        db,
        """
        SELECT
            voucher_id,
            code,
            discount_type,
            discount_value AS value,
            min_order_value AS min_order,
            max_discount,
            valid_until
        FROM vouchers
        WHERE valid_until >= SYSTIMESTAMP
        ORDER BY valid_until
        """,
        {"user_id": user_id},
    )


def update_wallet_status(db: Session, wallet_id: int, status: str) -> None:
    execute(db, "UPDATE wallets SET wallet_status = :status, updated_at = SYSTIMESTAMP WHERE wallet_id = :wallet_id", {"wallet_id": wallet_id, "status": status})
    db.commit()


def create_fee_config(db: Session, data: dict) -> dict:
    execute(
        db,
        """
        INSERT INTO transaction_fees (fee_id, type_id, fee_rate, fee_fixed, min_fee, max_fee, effective_from)
        VALUES (
            COALESCE((SELECT MAX(fee_id) + 1 FROM transaction_fees), 1),
            :type_id,
            :fee_rate,
            :fee_fixed,
            0,
            NULL,
            :effective_from
        )
        """,
        data,
    )
    db.commit()
    return data


def adjust_wallet(db: Session, wallet_id: int, amount, action: str, reason: str) -> dict:
    sign = 1 if action == "CREDIT" else -1
    wallet = one(db, "SELECT balance FROM wallets WHERE wallet_id = :wallet_id FOR UPDATE", {"wallet_id": wallet_id})
    before = wallet["balance"]
    after = before + (amount * sign)
    execute(db, "UPDATE wallets SET balance = :balance, updated_at = SYSTIMESTAMP WHERE wallet_id = :wallet_id", {"wallet_id": wallet_id, "balance": after})
    execute(
        db,
        """
        INSERT INTO audit_logs (wallet_id, action_type, balance_before, balance_after, delta)
        VALUES (:wallet_id, :action, :before, :after, :amount)
        """,
        {"wallet_id": wallet_id, "action": action, "amount": amount * sign, "before": before, "after": after, "reason": reason},
    )
    db.commit()
    return {"new_balance": after}
