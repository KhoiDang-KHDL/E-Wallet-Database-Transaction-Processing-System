from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1.router import api_router
from app.core.config import settings


app = FastAPI(title=settings.app_name, debug=settings.debug)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health_check():
    return {"success": True, "message": "API is running", "data": {"env": settings.app_env}, "error_code": None}


app.include_router(api_router, prefix="/api") # sẽ chạy tất cả các route được định nghĩa trong api_router với prefix /api
