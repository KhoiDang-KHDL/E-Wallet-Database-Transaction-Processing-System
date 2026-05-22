from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel


class PaymentMethodActionRequest(BaseModel):
    action: str


class WalletStatusRequest(BaseModel):
    status: str
    reason: str | None = None


class FeeConfigRequest(BaseModel):
    type_id: int
    fee_rate: Decimal = Decimal("0")
    fee_fixed: Decimal = Decimal("0")
    effective_from: date


class WalletAdjustRequest(BaseModel):
    wallet_id: int
    amount: Decimal
    action: str
    reason: str


class AuditLogRead(BaseModel):
    log_id: int
    action_type: str
    amount: Decimal
    balance_before: Decimal | None = None
    balance_after: Decimal | None = None
    description: str | None = None
    changed_at: datetime | None = None
