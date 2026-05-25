from collections.abc import Generator

import oracledb
from fastapi import Request

from app.core.config import get_settings


def create_pool() -> oracledb.ConnectionPool:
    settings = get_settings()
    return oracledb.create_pool(
        user=settings.oracle_user,
        password=settings.oracle_password,
        dsn=settings.oracle_dsn,
        min=settings.oracle_pool_min,
        max=settings.oracle_pool_max,
        increment=settings.oracle_pool_increment,
    )


def get_connection(request: Request) -> Generator[oracledb.Connection, None, None]:
    pool: oracledb.ConnectionPool = request.app.state.oracle_pool
    with pool.acquire() as connection:
        yield connection
