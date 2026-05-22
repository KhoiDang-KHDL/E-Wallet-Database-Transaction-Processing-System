from sqlalchemy.orm import Session

from app.repositories.base import execute, many, one


def create_rule(db: Session, data: dict) -> dict:
    execute(
        db,
        """
        INSERT INTO fraud_rules (rule_id, rule_name, condition_field, operator, threshold_value, action)
        VALUES (
            COALESCE((SELECT MAX(rule_id) + 1 FROM fraud_rules), 1),
            :rule_name,
            :condition_field,
            :operator,
            :threshold_value,
            :action
        )
        """,
        {
            "rule_name": data["rule_name"],
            "condition_field": data["condition_field"],
            "operator": data["operator"],
            "threshold_value": data["threshold_value"],
            "action": data["action"],
        },
    )
    db.commit()
    return data


def update_rule(db: Session, rule_id: int, values: dict) -> dict:
    allowed = {"rule_name", "condition_field", "operator", "threshold_value", "action"}
    fields = {key: value for key, value in values.items() if key in allowed and value is not None}
    if fields:
        set_clause = ", ".join(f"{key} = :{key}" for key in fields)
        execute(db, f"UPDATE fraud_rules SET {set_clause} WHERE rule_id = :rule_id", {**fields, "rule_id": rule_id})
        db.commit()
    return one(db, "SELECT * FROM fraud_rules WHERE rule_id = :rule_id", {"rule_id": rule_id}) or {"rule_id": rule_id}


def list_rules(db: Session, page: int, size: int, is_active: bool | None) -> dict:
    rows = many(
        db,
        "SELECT * FROM fraud_rules ORDER BY rule_id OFFSET :offset ROWS FETCH NEXT :size ROWS ONLY",
        {"offset": (page - 1) * size, "size": size},
    )
    return {"page": page, "size": size, "total": len(rows), "rules": rows}


def list_flags(db: Session, page: int, size: int, is_confirmed_fraud: bool | None) -> dict:
    where = "WHERE is_confirmed = :is_confirmed_fraud" if is_confirmed_fraud is not None else ""
    rows = many(
        db,
        f"SELECT flag_id, transaction_id, rule_id, risk_score, action_taken, is_confirmed AS is_confirmed_fraud FROM fraud_flags {where} ORDER BY flag_id DESC OFFSET :offset ROWS FETCH NEXT :size ROWS ONLY",
        {"is_confirmed_fraud": is_confirmed_fraud, "offset": (page - 1) * size, "size": size},
    )
    return {"page": page, "size": size, "total": len(rows), "flags": rows}


def get_flag(db: Session, flag_id: int) -> dict | None:
    return one(
        db,
        "SELECT flag_id, transaction_id, rule_id, risk_score, action_taken, is_confirmed AS is_confirmed_fraud FROM fraud_flags WHERE flag_id = :flag_id",
        {"flag_id": flag_id},
    )


def confirm_flag(db: Session, flag_id: int, is_confirmed: bool) -> dict:
    execute(db, "UPDATE fraud_flags SET is_confirmed = :is_confirmed WHERE flag_id = :flag_id", {"flag_id": flag_id, "is_confirmed": int(is_confirmed)})
    db.commit()
    return get_flag(db, flag_id) or {"flag_id": flag_id, "is_confirmed_fraud": is_confirmed}
