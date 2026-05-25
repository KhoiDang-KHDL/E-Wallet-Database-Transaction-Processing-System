from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.core.config import get_settings
from app.db import create_pool
from app.routers import auth, health, payment_methods, transactions, users, vouchers, wallets


@asynccontextmanager
async def lifespan(app: FastAPI):
    app.state.oracle_pool = create_pool()
    try:
        yield
    finally:
        app.state.oracle_pool.close()


settings = get_settings()

app = FastAPI(
    title=settings.app_name,
    debug=settings.app_debug,
    lifespan=lifespan,
)

app.include_router(health.router)
app.include_router(auth.router)
app.include_router(users.router)
app.include_router(wallets.router)
app.include_router(payment_methods.router)
app.include_router(transactions.router)
app.include_router(vouchers.router)
