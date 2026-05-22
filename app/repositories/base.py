from sqlalchemy import CursorResult, text
from sqlalchemy.orm import Session


def row_to_dict(row) -> dict:
    return dict(row._mapping)


def one(db: Session, statement: str, params: dict | None = None) -> dict | None:
    row = db.execute(text(statement), params or {}).mappings().first()
    return dict(row) if row else None


def many(db: Session, statement: str, params: dict | None = None) -> list[dict]:
    rows = db.execute(text(statement), params or {}).mappings().all()
    return [dict(row) for row in rows]


def execute(db: Session, statement: str, params: dict | None = None) -> CursorResult:
    return db.execute(text(statement), params or {})
