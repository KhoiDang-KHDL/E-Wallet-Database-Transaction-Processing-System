from fastapi import APIRouter

from app.api.v1 import admin, auth, fraud, transactions, wallets


api_router = APIRouter()
api_router.include_router(auth.router, tags=["users"])
api_router.include_router(admin.router, tags=["admin"])
api_router.include_router(wallets.router, prefix="/v1", tags=["wallets"])
api_router.include_router(transactions.router, prefix="/v1", tags=["transactions"])
api_router.include_router(fraud.router, prefix="/v1", tags=["fraud"])
