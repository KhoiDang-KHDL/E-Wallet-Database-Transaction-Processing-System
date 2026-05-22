from datetime import datetime

from pydantic import BaseModel, EmailStr, Field


class UserRegisterRequest(BaseModel):
    full_name: str = Field(min_length=1, max_length=150)
    email: EmailStr
    phone: str = Field(min_length=9, max_length=20)
    password: str = Field(min_length=6, max_length=128)


class UserLoginRequest(BaseModel):
    email: EmailStr | None = None
    phone: str | None = None
    password: str


class UserUpdateRequest(BaseModel):
    full_name: str | None = None
    email: EmailStr | None = None
    phone: str | None = None


class ChangePasswordRequest(BaseModel):
    user_id: int
    old_password: str
    new_password: str = Field(min_length=6, max_length=128)


class ChangePinRequest(BaseModel):
    user_id: int
    old_pin: str
    new_pin: str = Field(min_length=4, max_length=12)


class AdminCreateUserRequest(UserRegisterRequest):
    pass


class UserRead(BaseModel):
    user_id: int
    full_name: str | None = None
    email: str | None = None
    phone: str | None = None
    kyc_status: str | None = None
    is_active: bool | None = None
    created_at: datetime | None = None


class KycUpdateRequest(BaseModel):
    kyc_status: str


class UserStatusRequest(BaseModel):
    is_active: bool
