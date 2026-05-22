from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel


class FraudRuleCreateRequest(BaseModel):
    rule_name: str
    condition_field: str
    operator: str
    threshold_value: Decimal
    action: str
    priority: int = 1
    is_active: bool = True


class FraudRuleUpdateRequest(BaseModel):
    rule_name: str | None = None
    condition_field: str | None = None
    operator: str | None = None
    threshold_value: Decimal | None = None
    action: str | None = None
    priority: int | None = None
    is_active: bool | None = None


class FraudRuleStatusRequest(BaseModel):
    is_active: bool


class FraudConfirmRequest(BaseModel):
    is_confirmed_fraud: bool
    note: str | None = None


class FraudCheckRequest(BaseModel):
    transaction_id: int
    amount: Decimal
    sender_wallet_id: int | None = None
    receiver_wallet_id: int | None = None
    currency: str = "VND"
    created_at: datetime | None = None
