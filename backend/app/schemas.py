from decimal import Decimal

from pydantic import BaseModel, EmailStr, Field, field_validator


class RegisterRequest(BaseModel):
    full_name: str = Field(min_length=1, max_length=100)
    email: EmailStr
    phone: str = Field(min_length=8, max_length=15)
    password: str = Field(min_length=8, max_length=72)
    pin_code: str = Field(pattern=r"^\d{6}$")
    currency: str = Field(default="VND", min_length=3, max_length=10)


class LoginRequest(BaseModel):
    phone: str
    password: str
    device_info: str | None = Field(default=None, max_length=255)


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class UserProfile(BaseModel):
    user_id: int
    full_name: str | None
    email: str | None
    phone: str | None
    kyc_status: str | None
    created_at: str | None = None
    updated_at: str | None = None


class UpdateProfileRequest(BaseModel):
    full_name: str | None = Field(default=None, min_length=1, max_length=100)
    email: EmailStr | None = None
    phone: str | None = Field(default=None, min_length=8, max_length=15)


class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str = Field(min_length=8, max_length=72)


class ChangePinRequest(BaseModel):
    current_pin_code: str = Field(pattern=r"^\d{6}$")
    new_pin_code: str = Field(pattern=r"^\d{6}$")


class WalletResponse(BaseModel):
    wallet_id: int
    balance: Decimal
    currency: str | None
    wallet_status: str | None


class TransactionLimitResponse(BaseModel):
    limit_id: int
    kyc_level: str
    max_amount_per_trans: Decimal
    max_amount_per_day: Decimal
    max_trans_per_day: int


class AuditLogResponse(BaseModel):
    log_id: int
    transaction_id: int | None
    wallet_id: int
    action_type: str
    balance_before: Decimal
    balance_after: Decimal
    delta: Decimal


class PaymentMethodCreateRequest(BaseModel):
    method_type: str = Field(default="BANK_ACCOUNT")
    provider_name: str = Field(min_length=1, max_length=100)
    masked_number: str = Field(min_length=4, max_length=20)
    is_default: bool = False

    @field_validator("method_type")
    @classmethod
    def validate_method_type(cls, value: str) -> str:
        value = value.upper()
        if value not in {"BANK_ACCOUNT", "CREDIT_CARD"}:
            raise ValueError("method_type must be BANK_ACCOUNT or CREDIT_CARD")
        return value


class PaymentMethodResponse(BaseModel):
    method_id: int
    method_type: str | None
    provider_name: str | None
    masked_number: str | None
    is_default: bool
    is_verified: bool
    is_active: bool


class TransferRequest(BaseModel):
    receiver_wallet_id: int | None = None
    receiver_phone: str | None = Field(default=None, min_length=8, max_length=15)
    amount: Decimal = Field(gt=0)
    pin_code: str = Field(pattern=r"^\d{6}$")
    voucher_code: str | None = Field(default=None, max_length=20)
    description: str | None = Field(default=None, max_length=500)

    @field_validator("receiver_phone")
    @classmethod
    def normalize_receiver_phone(cls, value: str | None) -> str | None:
        return value.strip() if value else value


class TransferResponse(BaseModel):
    transaction_id: int
    reference_code: str
    status: str


class TransactionEstimateRequest(BaseModel):
    type_code: str = Field(min_length=1, max_length=20)
    amount: Decimal = Field(gt=0)
    voucher_code: str | None = Field(default=None, max_length=20)

    @field_validator("type_code")
    @classmethod
    def normalize_type_code(cls, value: str) -> str:
        return value.upper()


class TransactionEstimateResponse(BaseModel):
    type_code: str
    amount: Decimal
    fee_amount: Decimal
    voucher_code: str | None = None
    voucher_valid: bool = False
    discount_amount: Decimal = Decimal("0")
    total_deduct: Decimal
    receiver_amount: Decimal
    net_fee: Decimal


class TopUpRequest(BaseModel):
    method_id: int
    amount: Decimal = Field(gt=0)
    idempotency_key: str = Field(min_length=1, max_length=100)
    gateway_success: bool = True
    gateway_ref: str | None = Field(default=None, max_length=100)
    description: str | None = Field(default=None, max_length=500)


class TopUpResponse(BaseModel):
    order_id: int
    transaction_id: int | None = None
    status: str


class WithdrawRequest(BaseModel):
    method_id: int
    amount: Decimal = Field(gt=0)
    pin_code: str = Field(pattern=r"^\d{6}$")
    idempotency_key: str | None = Field(default=None, max_length=100)
    description: str | None = Field(default=None, max_length=500)


class WithdrawResponse(BaseModel):
    order_id: int
    transaction_id: int | None = None
    reference_code: str | None = None
    status: str


class ConfirmWithdrawRequest(BaseModel):
    gateway_success: bool
    gateway_ref: str | None = Field(default=None, max_length=100)


class ConfirmWithdrawResponse(BaseModel):
    status: str


class VoucherApplyRequest(BaseModel):
    type_code: str = Field(default="TRANSFER", max_length=20)
    amount: Decimal = Field(gt=0)
    voucher_code: str = Field(min_length=1, max_length=20)

    @field_validator("type_code")
    @classmethod
    def normalize_voucher_type(cls, value: str) -> str:
        return value.upper()


class VoucherApplyResponse(BaseModel):
    voucher_code: str
    type_code: str
    valid: bool
    discount_amount: Decimal
    message: str


class VoucherResponse(BaseModel):
    voucher_id: int
    code: str
    discount_type: str | None
    discount_value: Decimal | None
    min_order_value: Decimal | None
    max_discount: Decimal | None
    valid_until: str | None = None
    amount_vouchers: int


class TransactionResponse(BaseModel):
    transaction_id: int
    type_code: str | None
    sender_wallet_id: int | None
    receiver_wallet_id: int | None
    amount: Decimal
    fee_amount: Decimal
    status: str
    reference_code: str | None
    description: str | None
    created_at: str | None = None
    updated_at: str | None = None


class TransactionReceiptResponse(BaseModel):
    transaction: dict
    audit_logs: list[dict]
