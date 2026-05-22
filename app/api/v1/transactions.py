from fastapi import APIRouter, Query, status

from app.api.deps import AdminUser, CurrentUser, DbSession
from app.repositories import transactions as txn_repo
from app.schemas.common import ok
from app.schemas.transactions import (
    CancelTransactionRequest,
    ReconcileRequest,
    RefundRequest,
    TransactionCreateRequest,
    TransactionEstimateRequest,
    TransactionStatusRequest,
)


router = APIRouter()


@router.post("/transactions/estimate")
def estimate(payload: TransactionEstimateRequest, db: DbSession, _: CurrentUser):
    return ok(txn_repo.estimate_fee(db, payload.type_code, payload.amount), "Tính phí giao dịch thành công")


@router.post("/transactions", status_code=status.HTTP_201_CREATED)
def create_transaction(payload: TransactionCreateRequest, db: DbSession, _: CurrentUser):
    estimate_data = txn_repo.estimate_fee(db, payload.type_code, payload.amount)
    txn = txn_repo.create_transaction(db, payload.model_dump(), estimate_data["fee_amount"])
    return ok(txn, "Tạo giao dịch thành công")


@router.get("/transactions/me")
def my_transactions(db: DbSession, current_user: CurrentUser, page: int = Query(1, ge=1), size: int = Query(10, ge=1, le=100), status: str | None = None, type_code: str | None = None):
    return ok(txn_repo.list_transactions(db, page, size, status, type_code, int(current_user["sub"])), "Lấy danh sách giao dịch thành công")


@router.get("/transactions/{transaction_id}")
def transaction_detail(transaction_id: int, db: DbSession, _: CurrentUser):
    return ok({"transaction": txn_repo.get_transaction(db, transaction_id)}, "Lấy chi tiết giao dịch thành công")


@router.patch("/transactions/{transaction_id}/cancel")
def cancel_transaction(transaction_id: int, payload: CancelTransactionRequest, db: DbSession, _: CurrentUser):
    txn_repo.update_transaction_status(db, transaction_id, "CANCELLED")
    return ok({"transaction_id": transaction_id, "status": "CANCELLED", "reason": payload.reason}, "Hủy giao dịch thành công")


@router.get("/admin/transactions")
def admin_transactions(db: DbSession, _: AdminUser, page: int = Query(1, ge=1), size: int = Query(10, ge=1, le=100), status: str | None = None, type_code: str | None = None):
    return ok(txn_repo.list_transactions(db, page, size, status, type_code), "Lấy danh sách giao dịch thành công")


@router.patch("/admin/transactions/{transaction_id}/status")
def admin_update_status(transaction_id: int, payload: TransactionStatusRequest, db: DbSession, _: AdminUser):
    txn_repo.update_transaction_status(db, transaction_id, payload.status)
    return ok({"transaction_id": transaction_id, "status": payload.status}, "Cập nhật trạng thái giao dịch thành công")


@router.post("/admin/transactions/{transaction_id}/refund")
def refund(transaction_id: int, payload: RefundRequest, db: DbSession, _: AdminUser):
    return ok({"transaction_id": transaction_id, "refund_amount": payload.refund_amount, "refund_status": "COMPLETED"}, "Hoàn tiền thành công")


@router.post("/admin/transactions/{transaction_id}/reconcile")
def reconcile(transaction_id: int, payload: ReconcileRequest, db: DbSession, _: AdminUser):
    return ok({"transaction_id": transaction_id, "reconcile_status": payload.reconcile_status, "gateway_ref": payload.gateway_ref}, "Đối soát giao dịch thành công")
