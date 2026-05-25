import oracledb
from fastapi import APIRouter, Depends

from app.db import get_connection
from app.db_utils import fetch_one, translate_oracle_error

router = APIRouter(tags=["health"])


@router.get("/health")
def health_check(connection: oracledb.Connection = Depends(get_connection)) -> dict:
    with connection.cursor() as cursor:
        try:
            row = fetch_one(cursor, "SELECT 1 AS ok FROM dual")
        except oracledb.Error as exc:
            raise translate_oracle_error(exc) from exc
    return {"status": "ok", "database": bool(row and row["ok"] == 1)}
