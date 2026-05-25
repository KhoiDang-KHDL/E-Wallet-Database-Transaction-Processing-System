# IS210 E-Wallet FastAPI Backend

Backend nay dung FastAPI + Oracle `oracledb` va bam theo schema/procedure trong cac file SQL hien co. Code khong tao them bang/cot moi.

## 1. Chuan bi database Oracle

Chay cac script SQL trong schema Oracle theo thu tu:

1. `create_DB.sql`
2. `IS210_Ewallet_function.sql`
3. `IS210_Ewallet_procedure.sql`
4. `IS210_Ewallet_trigger.sql`

Luu y: database can co du lieu trong `transaction_limits`, vi `sp_transfer_money` va trigger se doc han muc theo KYC. Script hien tai moi seed `transaction_types`.

Vi du du lieu han muc mau, chi chay neu thay dung voi yeu cau nhom:

```sql
INSERT INTO transaction_limits (limit_id, kyc_level, max_amount_per_trans, max_amount_per_day, max_trans_per_day)
VALUES (1, 'UNVERIFIED', 5000000, 20000000, 10);

INSERT INTO transaction_limits (limit_id, kyc_level, max_amount_per_trans, max_amount_per_day, max_trans_per_day)
VALUES (2, 'VERIFIED', 50000000, 200000000, 50);

COMMIT;
```

## 2. Tao moi truong Python trong VS Code

Mo terminal tai thu muc `backend`:

```powershell
cd C:\Users\User\Desktop\IS210_project\backend
py -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

Neu PowerShell chan activate script, chay:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\.venv\Scripts\Activate.ps1
```

## 3. Cau hinh ket noi Oracle

Copy file `.env.example` thanh `.env`:

```powershell
Copy-Item .env.example .env
```

Sua `.env` theo database cua ban:

```env
ORACLE_USER=EWALLET_USER
ORACLE_PASSWORD=your_password
ORACLE_DSN=localhost:1521/XEPDB1
JWT_SECRET_KEY=change-me-to-a-long-random-secret
```

Voi Oracle XE thuong gap cac DSN:

```env
ORACLE_DSN=localhost:1521/XEPDB1
```

hoac:

```env
ORACLE_DSN=localhost:1521/XE
```

Thu vien `oracledb` dang dung Thin mode, nen khong can cai Oracle Instant Client neu ket noi bang host/port/service name.

## 4. Chay API

```powershell
uvicorn app.main:app --reload
```

Mo Swagger UI:

```text
http://127.0.0.1:8000/docs
```

Kiem tra ket noi:

```text
GET /health
```

## 5. Luong su dung chinh

Dang ky tai khoan:

```http
POST /auth/register
```

Body:

```json
{
  "full_name": "Nguyen Van A",
  "email": "a@example.com",
  "phone": "0900000001",
  "password": "password123",
  "pin_code": "123456",
  "currency": "VND"
}
```

Dang nhap:

```http
POST /auth/login
```

Body:

```json
{
  "phone": "0900000001",
  "password": "password123",
  "device_info": "VS Code test"
}
```

Lay `access_token` tra ve, bam nut `Authorize` tren Swagger va nhap:

```text
Bearer <access_token>
```

## 6. Cac endpoint da code

Auth:

- `POST /auth/register`: dang ky user, hash password, tao wallet qua `proc_create_user_with_wallet`
- `POST /auth/login`: dang nhap va nhan JWT
- `POST /auth/logout`: danh dau cac login session cua user la inactive

Thong tin ca nhan:

- `GET /me`: xem thong tin ca nhan va `kyc_status`, khong tra `password_hash`, `is_active`
- `PUT /me`: cap nhat mot hoac nhieu truong `full_name`, `email`, `phone`; backend tu giu nguyen truong khong gui va goi `proc_update_user_info`
- `PUT /me/password`: doi mat khau, co verify mat khau hien tai
- `PUT /me/pin`: doi ma PIN, backend goi `pr_update_pin_code(user_id, current_pin_code, new_pin_code)` de Oracle kiem tra PIN cu va trang thai vi

Vi:

- `GET /wallet`: xem `wallet_id`, `balance`, `currency`, `wallet_status`
- `GET /wallet/limits`: xem bang han muc chung
- `GET /wallet/audit-logs`: xem bien dong so du cua vi minh
- `GET /wallet/lookup?phone=...`: tra cuu vi nguoi nhan theo so dien thoai de frontend hien thi xac nhan truoc khi chuyen tien

Phuong thuc thanh toan:

- `POST /payment-methods`: them phuong thuc thanh toan
- `GET /payment-methods`: xem danh sach phuong thuc cua minh
- `PUT /payment-methods/{method_id}/default`: dat mac dinh
- `DELETE /payment-methods/{method_id}`: huy lien ket bang cach set `is_active = 0`

Giao dich nguoi dung:

- `POST /transactions/estimate`: uoc tinh phi, tong tien tru, discount; goi `fn_real_fee`, `fn_validate_voucher`, `fn_voucher_discount`
- `POST /transactions/top-up`: nap tien vao vi; goi `sp_top_up_wallet`
- `POST /transactions/withdraw`: tao yeu cau rut tien; goi `sp_withdraw_request`
- `POST /transactions/withdraw/{order_id}/confirm`: xac nhan ket qua rut tien demo/gateway; goi `sp_confirm_withdraw`
- `POST /transactions/transfer`: chuyen tien tu vi cua user dang dang nhap qua `sp_transfer_money`; frontend co the gui `receiver_phone` de backend tu map sang vi nguoi nhan
- `GET /transactions`: xem giao dich ma vi cua user la ben gui hoac ben nhan
- `GET /transactions/{transaction_id}`: xem chi tiet mot giao dich cua minh
- `POST /transactions/{transaction_id}/cancel`: huy giao dich `PENDING` neu chua co audit log, tuc chua xu ly so du
- `GET /transactions/{transaction_id}/receipt`: xem bien nhan giao dich `COMPLETED`

Voucher:

- `GET /vouchers`: xem danh sach voucher dang active, con luot, con han
- `POST /vouchers/apply`: kiem tra voucher va tinh discount bang function Oracle

## 7. Cac rang buoc bao ve da ap dung o backend

- API khong nhan `user_id` tu client cho cac thao tac ca nhan.
- User chi doc wallet, audit logs, transactions, payment methods cua minh.
- User khong co endpoint tu cap nhat KYC, mo/khoa tai khoan, sua so du.
- User khong co endpoint update truc tiep transaction da hoan tat.
- Chuyen tien goi stored procedure `sp_transfer_money`, de DB kiem tra PIN, trang thai vi, so du, han muc KYC va ghi audit log.
- Huy giao dich cho xu ly hien chua co procedure Oracle rieng, backend chi update transaction/fund_order thanh `FAILED` neu transaction la cua user, dang `PENDING`, va khong co dong `audit_logs`.

## 8. Ghi chu ve logout

JWT dang la stateless token. Endpoint `/auth/logout` cap nhat `login_sessions.is_active = 0`, nhung khong the thu hoi token cu ngay lap tuc vi bang `login_sessions` hien khong co cot token/jti. Client can xoa token sau khi logout. Neu muon revoke token that su, can xac nhan thay doi schema truoc khi lam.

## 9. Ghi chu ve SQL hien co

`sp_reversal` trong file procedure co doan update transaction goc thanh status `REVERSED`, nhung constraint trong `create_DB.sql` chi cho `PENDING`, `COMPLETED`, `FAILED`. Backend hien chua mo API reversal de tranh cham vao loi nay khi chua co xac nhan sua DB.

Ngoai ra, user moi co `users.kyc_status = PENDING`, trong khi `transaction_limits.kyc_level` chi cho `UNVERIFIED` hoac `VERIFIED`. `sp_transfer_money` co map `PENDING` sang `UNVERIFIED`, nhung trigger `trg_validate_transaction_rules` lai doc truc tiep `users.kyc_status` de tim han muc. Vi vay giao dich cua user `PENDING` co the bi loi truoc khi insert transaction. Can xac nhan cach xu ly KYC/hạn muc truoc khi sua SQL.

## 10. Cap nhat function/procedure tren Oracle sau khi merge SQL

Sau khi sua `IS210_Ewallet_function.sql` va `IS210_Ewallet_procedure.sql`, chay lai theo thu tu:

```sql
@IS210_Ewallet_function.sql
@IS210_Ewallet_procedure.sql
```

Neu chay bang SQL Developer, mo tung file va bam Run Script/F5. Function phai chay truoc procedure vi procedure moi co goi cac function nhu `fn_check_transaction_limit`, `fn_risk_score`, `fnc_wallet_transactable`.

Procedure `pr_update_pin_code` da doi signature thanh:

```sql
pr_update_pin_code(p_user_id, p_old_pin, p_new_pin)
```

Backend hien da cap nhat de goi dung signature moi.
