from collections.abc import Sequence
from typing import Any

import oracledb
from fastapi import HTTPException, status


def row_to_dict(cursor: oracledb.Cursor, row: Sequence[Any]) -> dict[str, Any]:
    columns = [description[0].lower() for description in cursor.description]
    return dict(zip(columns, row, strict=False))


def fetch_one(cursor: oracledb.Cursor, sql: str, params: dict[str, Any] | None = None) -> dict[str, Any] | None:
    cursor.execute(sql, params or {})
    row = cursor.fetchone()
    if row is None:
        return None
    return row_to_dict(cursor, row)


def fetch_all(cursor: oracledb.Cursor, sql: str, params: dict[str, Any] | None = None) -> list[dict[str, Any]]:
    cursor.execute(sql, params or {})
    return [row_to_dict(cursor, row) for row in cursor.fetchall()]


def raise_not_found(message: str) -> None:
    raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=message)


def translate_oracle_error(exc: oracledb.Error) -> HTTPException:
    error = exc.args[0]
    message = getattr(error, "message", str(exc))
    code = getattr(error, "code", None)

    if code in {1, 2290, 2291, 2292}:
        http_status = status.HTTP_409_CONFLICT
    elif code and 20000 <= abs(code) <= 20999:
        http_status = status.HTTP_400_BAD_REQUEST
    else:
        http_status = status.HTTP_500_INTERNAL_SERVER_ERROR

    return HTTPException(status_code=http_status, detail=message)
