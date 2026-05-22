from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, Field


class TransactionEstimateRequest(BaseModel):
    type_code: str
    sender_wallet_id: int | None = None
    receiver_wallet_id: int | None = None
    amount: Decimal = Field(gt=0)
    voucher_code: str | None = None


class TransactionCreateRequest(BaseModel):
    type_code: str
    sender_wallet_id: int | None = None
    receiver_wallet_id: int | None = None
    amount: Decimal = Field(gt=0)
    voucher_id: int | None = None
    note: str | None = None
    idempotency_key: str | None = None


class CancelTransactionRequest(BaseModel):
    reason: str


class TransactionStatusRequest(BaseModel):
    status: str
    reason: str | None = None


class RefundRequest(BaseModel):
    refund_amount: Decimal = Field(gt=0)
    reason: str


class ReconcileRequest(BaseModel):
    gateway_ref: str
    reconcile_status: str


class TransactionRead(BaseModel):
    transaction_id: int
    reference_code: str | None = None
    type_code: str | None = None
    amount: Decimal
    fee_amount: Decimal | None = None
    status: str
    created_at: datetime | None = None
