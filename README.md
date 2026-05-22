# E-Wallet FastAPI Backend

Backend starter for the e-wallet transaction management system.

## Setup

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
Copy-Item .env.example .env
```

Update `.env` with your local Oracle username, password, host, port, and service name.

## Run

```powershell
uvicorn app.main:app --reload
```

Open:

- API docs: http://127.0.0.1:8000/docs
- Health check: http://127.0.0.1:8000/health

## Authentication

Protected APIs use Bearer token authentication.

1. Login with `POST /api/users/login`.
2. Copy the `data.token` value from the response.
3. In Swagger UI, click **Authorize** and paste the token value.

The request header sent by clients should be:

```text
Authorization: Bearer <token>
```

## Notes

The backend has been aligned with `create_DB_Project.sql` and `E-Wallet_Dictionary.pdf`.

Important schema notes:

- Admin permission is controlled by `ADMIN_USER_IDS` in `.env` because the current `users` table has no `role` column.
- `PUT /api/users/change_pin` returns `501` until you add a `pin_hash` column or create a separate PIN table.
- `PATCH /api/v1/admin/fraud-rules/{rule_id}/status` returns `501` until you add an `is_active` column to `fraud_rules`.
- `transactions` currently has no `note`, `idempotency_key`, or `updated_at` column, so the backend does not persist those fields.
