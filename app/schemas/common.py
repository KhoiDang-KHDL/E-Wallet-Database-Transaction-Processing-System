from typing import Generic, TypeVar

from pydantic import BaseModel


T = TypeVar("T")


class ApiResponse(BaseModel, Generic[T]):
    success: bool = True
    message: str | None = None
    data: T | None = None
    error_code: str | None = None


def ok(data=None, message: str | None = None):
    return {"success": True, "message": message, "data": data, "error_code": None}
