from fastapi import APIRouter, HTTPException, Query, status

from app.api.deps import AdminUser, DbSession
from app.repositories import fraud as fraud_repo
from app.schemas.common import ok
from app.schemas.fraud import FraudCheckRequest, FraudConfirmRequest, FraudRuleCreateRequest, FraudRuleStatusRequest, FraudRuleUpdateRequest


router = APIRouter()


@router.post("/admin/risk/rules", status_code=status.HTTP_201_CREATED)
def create_rule(payload: FraudRuleCreateRequest, db: DbSession, _: AdminUser):
    return ok(fraud_repo.create_rule(db, payload.model_dump()), "Tạo quy tắc phát hiện gian lận thành công")


@router.patch("/admin/risk/rules/{rule_id}")
def update_rule(rule_id: int, payload: FraudRuleUpdateRequest, db: DbSession, _: AdminUser):
    return ok(fraud_repo.update_rule(db, rule_id, payload.model_dump(exclude_unset=True)), "Cập nhật quy tắc phát hiện gian lận thành công")


@router.patch("/admin/fraud-rules/{rule_id}/status")
def update_rule_status(rule_id: int, payload: FraudRuleStatusRequest, db: DbSession, _: AdminUser):
    raise HTTPException(status_code=501, detail="Current fraud_rules table has no is_active column.")


@router.get("/admin/fraud-rules")
def list_rules(db: DbSession, _: AdminUser, page: int = Query(1, ge=1), size: int = Query(10, ge=1, le=100), is_active: bool | None = None):
    return ok(fraud_repo.list_rules(db, page, size, is_active), "Lấy danh sách quy tắc phát hiện gian lận thành công")


@router.get("/admin/fraud-flags")
def list_flags(db: DbSession, _: AdminUser, page: int = Query(1, ge=1), size: int = Query(10, ge=1, le=100), is_confirmed_fraud: bool | None = None):
    return ok(fraud_repo.list_flags(db, page, size, is_confirmed_fraud), "Lấy danh sách giao dịch rủi ro thành công")


@router.get("/admin/fraud-flags/{flag_id}")
def flag_detail(flag_id: int, db: DbSession, _: AdminUser):
    return ok({"flag": fraud_repo.get_flag(db, flag_id)}, "Lấy chi tiết giao dịch rủi ro thành công")


@router.patch("/admin/fraud-flags/{flag_id}/confirm")
def confirm_flag(flag_id: int, payload: FraudConfirmRequest, db: DbSession, _: AdminUser):
    return ok(fraud_repo.confirm_flag(db, flag_id, payload.is_confirmed_fraud), "Cập nhật trạng thái xác nhận gian lận thành công")


@router.post("/internal/fraud-check/transactions/{transaction_id}")
def fraud_check(transaction_id: int, payload: FraudCheckRequest, _: AdminUser):
    is_risky = payload.amount >= 50_000_000
    return ok(
        {
            "transaction_id": transaction_id,
            "is_risky": is_risky,
            "total_risk_score": 85 if is_risky else 0,
            "action_taken": "ALERT" if is_risky else "NONE",
            "matched_rules": [] if not is_risky else [{"rule_name": "High Value Transaction", "risk_score": 85, "action": "ALERT"}],
            "fraud_flag_ids": [],
        },
        "Kiểm tra rủi ro giao dịch thành công",
    )
