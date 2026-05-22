from fastapi import APIRouter, Query, status

from app.api.deps import AdminUser, CurrentUser, DbSession
from app.repositories import wallets as wallet_repo
from app.schemas.common import ok
from app.schemas.wallets import FeeConfigRequest, PaymentMethodActionRequest, WalletAdjustRequest, WalletStatusRequest


router = APIRouter()


@router.get("/wallets/me/logs")
def my_wallet_logs(db: DbSession, current_user: CurrentUser, page: int = Query(1, ge=1), size: int = Query(10, ge=1, le=100)):
    return ok(wallet_repo.get_wallet_with_logs(db, int(current_user["sub"]), page, size))


@router.patch("/payment-methods/{method_id}")
def update_payment_method(method_id: int, payload: PaymentMethodActionRequest, db: DbSession, _: CurrentUser):
    return ok(wallet_repo.update_payment_method(db, method_id, payload.action), "Cập nhật phương thức thanh toán thành công")


@router.get("/vouchers/available")
def available_vouchers(db: DbSession, current_user: CurrentUser):
    return ok(wallet_repo.available_vouchers(db, int(current_user["sub"])))


@router.put("/admin/wallets/{wallet_id}/status")
def update_wallet_status(wallet_id: int, payload: WalletStatusRequest, db: DbSession, _: AdminUser):
    wallet_repo.update_wallet_status(db, wallet_id, payload.status)
    return ok({"wallet_id": wallet_id, "new_status": payload.status}, "Ví đã được cập nhật trạng thái")


@router.post("/admin/configs/fees", status_code=status.HTTP_201_CREATED)
def create_fee(payload: FeeConfigRequest, db: DbSession, _: AdminUser):
    return ok(wallet_repo.create_fee_config(db, payload.model_dump()), "Cấu hình phí mới đã được lưu")


@router.post("/admin/wallets/adjust")
def adjust_wallet(payload: WalletAdjustRequest, db: DbSession, _: AdminUser):
    return ok(wallet_repo.adjust_wallet(db, payload.wallet_id, payload.amount, payload.action, payload.reason), "Điều chỉnh số dư thành công")
