from sqlalchemy.orm import Session

from app.repositories.base import execute, many, one


def create_user(db: Session, data: dict) -> int:
    execute(
        db,
        """
        INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active, created_at)
        VALUES (:full_name, :email, :phone, :password_hash, 'PENDING', 1, SYSTIMESTAMP)
        """,
        data,
    )
    created = get_user_by_login(db, data.get("email"), data.get("phone"))
    execute(
        db,
        """
        INSERT INTO wallets (user_id, balance, currency, wallet_status, created_at, updated_at)
        VALUES (:user_id, 0, 'VND', 'ACTIVE', SYSTIMESTAMP, SYSTIMESTAMP)
        """,
        {"user_id": created["user_id"]},
    )
    db.commit()
    return int(created["user_id"])


def get_user_by_login(db: Session, email: str | None, phone: str | None) -> dict | None:
    if email:
        return one(db, "SELECT * FROM users WHERE email = :email", {"email": email})
    if phone:
        return one(db, "SELECT * FROM users WHERE phone = :phone", {"phone": phone})
    return None


def get_user(db: Session, user_id: int) -> dict | None:
    return one(
        db,
        """
        SELECT user_id, full_name, email, phone, kyc_status, is_active, created_at
        FROM users
        WHERE user_id = :user_id
        """,
        {"user_id": user_id},
    )


def get_user_with_auth(db: Session, user_id: int) -> dict | None:
    return one(db, "SELECT * FROM users WHERE user_id = :user_id", {"user_id": user_id})


def list_users(db: Session, page: int, size: int) -> list[dict]:
    offset = (page - 1) * size
    return many(
        db,
        """
        SELECT user_id, full_name, email, phone, kyc_status, is_active, created_at
        FROM users
        ORDER BY created_at DESC
        OFFSET :offset ROWS FETCH NEXT :size ROWS ONLY
        """,
        {"offset": offset, "size": size},
    )


def update_user(db: Session, user_id: int, values: dict) -> None:
    fields = {key: value for key, value in values.items() if value is not None}
    if not fields:
        return
    set_clause = ", ".join(f"{key} = :{key}" for key in fields)
    fields["user_id"] = user_id
    execute(db, f"UPDATE users SET {set_clause} WHERE user_id = :user_id", fields)
    db.commit()


def update_password_hash(db: Session, user_id: int, password_hash: str) -> None:
    execute(db, "UPDATE users SET password_hash = :password_hash WHERE user_id = :user_id", {"user_id": user_id, "password_hash": password_hash})
    db.commit()

