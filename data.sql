--------------------------------------------------------------------------------
-- CLEAN DATA ĐỂ CHẠY LẠI SCRIPT NHIỀU LẦN
--------------------------------------------------------------------------------

ALTER TRIGGER trg_prevent_audit_log_u_d DISABLE;

DELETE FROM audit_logs;
DELETE FROM transactions;
DELETE FROM fund_orders;
DELETE FROM login_sessions;
DELETE FROM payment_methods;
DELETE FROM wallets;
DELETE FROM vouchers;
DELETE FROM transaction_fees;
DELETE FROM users;
DELETE FROM transaction_limits;

COMMIT;

ALTER TRIGGER trg_prevent_audit_log_u_d ENABLE;

--------------------------------------------------------------------------------
-- 1. TRANSACTION_LIMITS
--------------------------------------------------------------------------------

INSERT INTO transaction_limits
    (limit_id, kyc_level, max_amount_per_trans, max_amount_per_day, max_trans_per_day)
VALUES
    (101, 'UNVERIFIED', 1000000,  5000000,   10);

INSERT INTO transaction_limits
    (limit_id, kyc_level, max_amount_per_trans, max_amount_per_day, max_trans_per_day)
VALUES
    (102, 'UNVERIFIED', 2000000, 10000000,   15);

INSERT INTO transaction_limits
    (limit_id, kyc_level, max_amount_per_trans, max_amount_per_day, max_trans_per_day)
VALUES
    (103, 'UNVERIFIED', 5000000, 20000000,   20);

INSERT INTO transaction_limits
    (limit_id, kyc_level, max_amount_per_trans, max_amount_per_day, max_trans_per_day)
VALUES
    (104, 'VERIFIED', 10000000,  50000000,   30);

INSERT INTO transaction_limits
    (limit_id, kyc_level, max_amount_per_trans, max_amount_per_day, max_trans_per_day)
VALUES
    (105, 'VERIFIED', 20000000, 100000000,   50);

INSERT INTO transaction_limits
    (limit_id, kyc_level, max_amount_per_trans, max_amount_per_day, max_trans_per_day)
VALUES
    (106, 'VERIFIED', 50000000, 300000000,  100);

--------------------------------------------------------------------------------
-- 2. USERS
--------------------------------------------------------------------------------

INSERT INTO users
    (user_id, full_name, email, phone, password_hash, kyc_status, is_active)
VALUES
    (1, 'Nguyễn Ngọc Minh Huy', 'wowy@gmail.com', '0901000001', 'HASH_AN_001', 'VERIFIED', 1);

INSERT INTO users
    (user_id, full_name, email, phone, password_hash, kyc_status, is_active, created_at, updated_at)
VALUES
    (2, 'Phạm Hoàng Khoa', 'karik@gmail.com', '0901000002', 'HASH_BINH_002', 'VERIFIED', 1, SYSTIMESTAMP, NULL);

INSERT INTO users
    (user_id, full_name, email, phone, password_hash, kyc_status, is_active, created_at, updated_at)
VALUES
    (3, 'Nguyễn Đức Cường', 'denvau@gmail.com', '0901000003', 'HASH_CUONG_003', 'PENDING', 1, SYSTIMESTAMP, NULL);

INSERT INTO users
    (user_id, full_name, email, phone, password_hash, kyc_status, is_active, created_at, updated_at)
VALUES
    (4, 'Lê Nguyễn Trung Đan', 'binz@gmail.com', '0901000004', 'HASH_DUC_004', 'VERIFIED', 1, SYSTIMESTAMP, NULL);

INSERT INTO users
    (user_id, full_name, email, phone, password_hash, kyc_status, is_active, created_at, updated_at)
VALUES
    (5, 'Hàng Lâm Trang Anh', 'suboi@gmail.com', '0901000005', 'HASH_HAN_005', 'VERIFIED', 1, SYSTIMESTAMP, NULL);

INSERT INTO users
    (user_id, full_name, email, phone, password_hash, kyc_status, is_active, created_at, updated_at)
VALUES
    (6, 'Nguyễn Quang Hưng', 'lk@gmail.com', '0901000006', 'HASH_KIET_006', 'REJECTED', 1, SYSTIMESTAMP, NULL);

INSERT INTO users
    (user_id, full_name, email, phone, password_hash, kyc_status, is_active, created_at, updated_at)
VALUES
    (7, 'Trần Sơn Đạt', 'dat.maniac@gmail.com', '0901000007', 'HASH_LONG_007', 'VERIFIED', 1, SYSTIMESTAMP, NULL);

INSERT INTO users
    (user_id, full_name, email, phone, password_hash, kyc_status, is_active, created_at, updated_at)
VALUES
    (8, 'Trần Tất Vũ', 'bigdaddy@gmail.com', '0901000008', 'HASH_LY_008', 'VERIFIED', 1, SYSTIMESTAMP, NULL);

INSERT INTO users
    (user_id, full_name, email, phone, password_hash, kyc_status, is_active, created_at, updated_at)
VALUES
    (9, 'Vũ Đức Thiện', 'rhy@gmail.com', '0901000009', 'HASH_MINH_009', 'PENDING', 1, SYSTIMESTAMP, NULL);

INSERT INTO users
    (user_id, full_name, email, phone, password_hash, kyc_status, is_active, created_at, updated_at)
VALUES
    (10, 'Trần Thiện Thanh Bảo', 'bray@gmail.com', '0901000010', 'HASH_TRANG_010', 'VERIFIED', 1, SYSTIMESTAMP, NULL);

COMMIT;

--------------------------------------------------------------------------------
-- 3. WALLETS
--------------------------------------------------------------------------------

INSERT INTO wallets
    (wallet_id, user_id, balance, currency, wallet_status, pin_code)
VALUES
    (1, 1, 8500000, 'VND', 'ACTIVE', '111111');

INSERT INTO wallets
    (wallet_id, user_id, balance, currency, wallet_status, pin_code, created_at, updated_at)
VALUES
    (2, 2, 12500000, 'VND', 'ACTIVE', '222222', SYSTIMESTAMP, NULL);

INSERT INTO wallets
    (wallet_id, user_id, balance, currency, wallet_status, pin_code, created_at, updated_at)
VALUES
    (3, 3, 2300000, 'VND', 'ACTIVE', '333333', SYSTIMESTAMP, NULL);

INSERT INTO wallets
    (wallet_id, user_id, balance, currency, wallet_status, pin_code, created_at, updated_at)
VALUES
    (4, 4, 15400000, 'VND', 'ACTIVE', '444444', SYSTIMESTAMP, NULL);

INSERT INTO wallets
    (wallet_id, user_id, balance, currency, wallet_status, pin_code, created_at, updated_at)
VALUES
    (5, 5, 6100000, 'VND', 'ACTIVE', '555555', SYSTIMESTAMP, NULL);

INSERT INTO wallets
    (wallet_id, user_id, balance, currency, wallet_status, pin_code, created_at, updated_at)
VALUES
    (6, 6, 0, 'VND', 'FROZEN', '666666', SYSTIMESTAMP, NULL);

INSERT INTO wallets
    (wallet_id, user_id, balance, currency, wallet_status, pin_code, created_at, updated_at)
VALUES
    (7, 7, 9800000, 'VND', 'ACTIVE', '777777', SYSTIMESTAMP, NULL);

INSERT INTO wallets
    (wallet_id, user_id, balance, currency, wallet_status, pin_code, created_at, updated_at)
VALUES
    (8, 8, 4500000, 'VND', 'ACTIVE', '888888', SYSTIMESTAMP, NULL);

INSERT INTO wallets
    (wallet_id, user_id, balance, currency, wallet_status, pin_code, created_at, updated_at)
VALUES
    (9, 9, 1750000, 'VND', 'ACTIVE', '999999', SYSTIMESTAMP, NULL);

INSERT INTO wallets
    (wallet_id, user_id, balance, currency, wallet_status, pin_code, created_at, updated_at)
VALUES
    (10, 10, 21200000, 'VND', 'ACTIVE', '101010', SYSTIMESTAMP, NULL);

COMMIT;

--------------------------------------------------------------------------------
-- 4. PAYMENT_METHODS
--------------------------------------------------------------------------------

INSERT INTO payment_methods
    (method_id, user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active, created_at, updated_at)
VALUES
    (1, 1, 'BANK_ACCOUNT', 'Vietcombank', 'VCB-****-1201', 1, 1, 1, SYSTIMESTAMP, NULL);

INSERT INTO payment_methods
    (method_id, user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active, created_at, updated_at)
VALUES
    (2, 1, 'CREDIT_CARD', 'Visa', 'VISA-****-4411', 0, 1, 1, SYSTIMESTAMP, NULL);

INSERT INTO payment_methods
    (method_id, user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active, created_at, updated_at)
VALUES
    (3, 2, 'BANK_ACCOUNT', 'Techcombank', 'TCB-****-2302', 1, 1, 1, SYSTIMESTAMP, NULL);

INSERT INTO payment_methods
    (method_id, user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active, created_at, updated_at)
VALUES
    (4, 2, 'CREDIT_CARD', 'MasterCard', 'MC-****-7722', 0, 1, 1, SYSTIMESTAMP, NULL);

INSERT INTO payment_methods
    (method_id, user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active, created_at, updated_at)
VALUES
    (5, 3, 'BANK_ACCOUNT', 'BIDV', 'BIDV-****-9921', 1, 0, 1, SYSTIMESTAMP, NULL);

INSERT INTO payment_methods
    (method_id, user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active, created_at, updated_at)
VALUES
    (6, 4, 'BANK_ACCOUNT', 'ACB', 'ACB-****-2201', 1, 1, 1, SYSTIMESTAMP, NULL);

INSERT INTO payment_methods
    (method_id, user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active, created_at, updated_at)
VALUES
    (7, 4, 'CREDIT_CARD', 'Visa', 'VISA-****-9901', 0, 1, 1, SYSTIMESTAMP, NULL);

INSERT INTO payment_methods
    (method_id, user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active, created_at, updated_at)
VALUES
    (8, 5, 'BANK_ACCOUNT', 'MB Bank', 'MBB-****-8111', 1, 1, 1, SYSTIMESTAMP, NULL);

INSERT INTO payment_methods
    (method_id, user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active, created_at, updated_at)
VALUES
    (9, 6, 'BANK_ACCOUNT', 'Sacombank', 'STB-****-6612', 1, 0, 1, SYSTIMESTAMP, NULL);

INSERT INTO payment_methods
    (method_id, user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active, created_at, updated_at)
VALUES
    (10, 7, 'BANK_ACCOUNT', 'VPBank', 'VPB-****-7720', 1, 1, 1, SYSTIMESTAMP, NULL);

INSERT INTO payment_methods
    (method_id, user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active, created_at, updated_at)
VALUES
    (11, 7, 'CREDIT_CARD', 'JCB', 'JCB-****-1199', 0, 1, 1, SYSTIMESTAMP, NULL);

INSERT INTO payment_methods
    (method_id, user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active, created_at, updated_at)
VALUES
    (12, 8, 'BANK_ACCOUNT', 'Agribank', 'AGR-****-0091', 1, 1, 1, SYSTIMESTAMP, NULL);

INSERT INTO payment_methods
    (method_id, user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active, created_at, updated_at)
VALUES
    (13, 8, 'CREDIT_CARD', 'Visa', 'VISA-****-4488', 0, 1, 1, SYSTIMESTAMP, NULL);

INSERT INTO payment_methods
    (method_id, user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active, created_at, updated_at)
VALUES
    (14, 9, 'BANK_ACCOUNT', 'OCB', 'OCB-****-3377', 1, 0, 1, SYSTIMESTAMP, NULL);

INSERT INTO payment_methods
    (method_id, user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active, created_at, updated_at)
VALUES
    (15, 10, 'BANK_ACCOUNT', 'VietinBank', 'VTB-****-1009', 1, 1, 1, SYSTIMESTAMP, NULL);

COMMIT;

--------------------------------------------------------------------------------
-- 5. VOUCHERS
--------------------------------------------------------------------------------

INSERT INTO vouchers
    (voucher_id, code, discount_type, discount_value, min_order_value, max_discount,
     valid_until, amount_vouchers, is_active, created_at, updated_at)
VALUES
    (1, 'WELCOME50', 'FIXED', 50000, 200000, 50000, SYSTIMESTAMP + 90, 100, 1, SYSTIMESTAMP, NULL);

INSERT INTO vouchers
    (voucher_id, code, discount_type, discount_value, min_order_value, max_discount,
     valid_until, amount_vouchers, is_active, created_at, updated_at)
VALUES
    (2, 'PAYDAY10', 'PERCENTAGE', 10, 500000, 100000, SYSTIMESTAMP + 60, 200, 1, SYSTIMESTAMP, NULL);

INSERT INTO vouchers
    (voucher_id, code, discount_type, discount_value, min_order_value, max_discount,
     valid_until, amount_vouchers, is_active, created_at, updated_at)
VALUES
    (3, 'FOOD30', 'FIXED', 30000, 100000, 30000, SYSTIMESTAMP + 45, 150, 1, SYSTIMESTAMP, NULL);

INSERT INTO vouchers
    (voucher_id, code, discount_type, discount_value, min_order_value, max_discount,
     valid_until, amount_vouchers, is_active, created_at, updated_at)
VALUES
    (4, 'SHOP15', 'PERCENTAGE', 15, 300000, 120000, SYSTIMESTAMP + 120, 120, 1, SYSTIMESTAMP, NULL);

INSERT INTO vouchers
    (voucher_id, code, discount_type, discount_value, min_order_value, max_discount,
     valid_until, amount_vouchers, is_active, created_at, updated_at)
VALUES
    (5, 'SUMMER20', 'PERCENTAGE', 20, 800000, 200000, SYSTIMESTAMP + 30, 80, 1, SYSTIMESTAMP, NULL);

INSERT INTO vouchers
    (voucher_id, code, discount_type, discount_value, min_order_value, max_discount,
     valid_until, amount_vouchers, is_active, created_at, updated_at)
VALUES
    (6, 'NEWUSER', 'FIXED', 100000, 1000000, 100000, SYSTIMESTAMP + 180, 50, 1, SYSTIMESTAMP, NULL);

COMMIT;

--------------------------------------------------------------------------------
-- 6. TRANSACTION_FEES
--------------------------------------------------------------------------------

INSERT INTO transaction_fees
    (fee_id, type_id, fee_rate, fee_fixed, min_fee, max_fee, effective_from, effective_to)
VALUES
    (201, 1, 0.0000, 0, 0, 0, SYSDATE - 30, NULL);

INSERT INTO transaction_fees
    (fee_id, type_id, fee_rate, fee_fixed, min_fee, max_fee, effective_from, effective_to)
VALUES
    (202, 2, 0.0050, 3000, 3000, 50000, SYSDATE - 30, NULL);

INSERT INTO transaction_fees
    (fee_id, type_id, fee_rate, fee_fixed, min_fee, max_fee, effective_from, effective_to)
VALUES
    (203, 3, 0.0020, 1000, 1000, 20000, SYSDATE - 30, NULL);

INSERT INTO transaction_fees
    (fee_id, type_id, fee_rate, fee_fixed, min_fee, max_fee, effective_from, effective_to)
VALUES
    (204, 4, 0.0100, 2000, 2000, 50000, SYSDATE - 30, NULL);

INSERT INTO transaction_fees
    (fee_id, type_id, fee_rate, fee_fixed, min_fee, max_fee, effective_from, effective_to)
VALUES
    (205, 5, 0.0000, 0, 0, 0, SYSDATE - 30, NULL);

INSERT INTO transaction_fees
    (fee_id, type_id, fee_rate, fee_fixed, min_fee, max_fee, effective_from, effective_to)
VALUES
    (206, 6, 0.0000, 0, 0, 0, SYSDATE - 30, NULL);

COMMIT;

--------------------------------------------------------------------------------
-- 7. LOGIN_SESSIONS
--------------------------------------------------------------------------------

INSERT INTO login_sessions
    (SESSION_ID, USER_ID, DEVICE_INFO, IP_ADDRESS, IS_ACTIVE)
VALUES
    (1, 1, 'iPhone 15 Pro - iOS 18', '192.168.1.10', 1);

INSERT INTO login_sessions
    (SESSION_ID, USER_ID, DEVICE_INFO, IP_ADDRESS, IS_ACTIVE)
VALUES
    (2, 2, 'Samsung Galaxy S24', '192.168.1.11', 1);

INSERT INTO login_sessions
    (SESSION_ID, USER_ID, DEVICE_INFO, IP_ADDRESS, IS_ACTIVE)
VALUES
    (3, 3, 'Windows 11 Chrome', '192.168.1.12', 0);

INSERT INTO login_sessions
    (SESSION_ID, USER_ID, DEVICE_INFO, IP_ADDRESS, IS_ACTIVE)
VALUES
    (4, 4, 'Macbook Pro Safari', '192.168.1.13', 1);

INSERT INTO login_sessions
    (SESSION_ID, USER_ID, DEVICE_INFO, IP_ADDRESS, IS_ACTIVE)
VALUES
    (5, 5, 'Xiaomi Android 15', '192.168.1.14', 1);

INSERT INTO login_sessions
    (SESSION_ID, USER_ID, DEVICE_INFO, IP_ADDRESS, IS_ACTIVE)
VALUES
    (6, 7, 'iPad Air', '192.168.1.15', 0);

COMMIT;

--------------------------------------------------------------------------------
-- 8. FUND_ORDERS
--------------------------------------------------------------------------------

INSERT INTO fund_orders
    (order_id, wallet_id, method_id, order_type, amount, status, idempotency_key, gateway_ref, created_at, updated_at)
VALUES
    (1, 1, 1, 'TOP_UP', 2000000, 'SUCCESS', 'IDEMP-TOPUP-0001', 'GW-VNPAY-0001', SYSTIMESTAMP, NULL);

INSERT INTO fund_orders
    (order_id, wallet_id, method_id, order_type, amount, status, idempotency_key, gateway_ref, created_at, updated_at)
VALUES
    (2, 2, 3, 'TOP_UP', 5000000, 'SUCCESS', 'IDEMP-TOPUP-0002', 'GW-MOMO-0002', SYSTIMESTAMP, NULL);

INSERT INTO fund_orders
    (order_id, wallet_id, method_id, order_type, amount, status, idempotency_key, gateway_ref, created_at, updated_at)
VALUES
    (3, 3, 5, 'WITHDRAW', 500000, 'PENDING', 'IDEMP-WD-0003', 'GW-NAPAS-0003', SYSTIMESTAMP, NULL);

INSERT INTO fund_orders
    (order_id, wallet_id, method_id, order_type, amount, status, idempotency_key, gateway_ref, created_at, updated_at)
VALUES
    (4, 4, 6, 'TOP_UP', 10000000, 'SUCCESS', 'IDEMP-TOPUP-0004', 'GW-ZALOPAY-0004', SYSTIMESTAMP, NULL);

INSERT INTO fund_orders
    (order_id, wallet_id, method_id, order_type, amount, status, idempotency_key, gateway_ref, created_at, updated_at)
VALUES
    (5, 5, 8, 'WITHDRAW', 1500000, 'FAILED', 'IDEMP-WD-0005', 'GW-BANK-0005', SYSTIMESTAMP, NULL);

INSERT INTO fund_orders
    (order_id, wallet_id, method_id, order_type, amount, status, idempotency_key, gateway_ref, created_at, updated_at)
VALUES
    (6, 10, 15, 'TOP_UP', 7000000, 'SUCCESS', 'IDEMP-TOPUP-0006', 'GW-VCB-0006', SYSTIMESTAMP, NULL);

COMMIT;

--------------------------------------------------------------------------------
-- 9. TRANSACTIONS (20 RECORDS)
--------------------------------------------------------------------------------

INSERT INTO transactions
    (transaction_id, type_id, sender_wallet_id, receiver_wallet_id, limit_id, voucher_id,
     original_transaction_id, amount, fee_amount, status, reference_code, step,
     description, created_at, updated_at)
VALUES
    (1, 1, NULL, 1, 104, NULL, NULL, 2000000, 0, 'COMPLETED',
     'TXN202605260001', 1, 'Nạp tiền ví Nguyễn Văn An', SYSTIMESTAMP, NULL);

INSERT INTO transactions
    (transaction_id, type_id, sender_wallet_id, receiver_wallet_id, limit_id, voucher_id,
     original_transaction_id, amount, fee_amount, status, reference_code, step,
     description, created_at, updated_at)
VALUES
    (2, 3, 3, 1, 101, NULL, NULL, 500000, 1000, 'COMPLETED',
     'TXN202605260002', 1, 'Chuyển tiền từ Bình sang An', SYSTIMESTAMP, NULL);

INSERT INTO transactions
    (transaction_id, type_id, sender_wallet_id, receiver_wallet_id, limit_id, voucher_id,
     original_transaction_id, amount, fee_amount, status, reference_code, step,
     description, created_at, updated_at)
VALUES
    (3, 4, 4, 2, 104, 2, NULL, 1200000, 12000, 'COMPLETED',
     'TXN202605260003', 1, 'Thanh toán đơn hàng điện tử', SYSTIMESTAMP, NULL);

INSERT INTO transactions
    (transaction_id, type_id, sender_wallet_id, receiver_wallet_id, limit_id, voucher_id,
     original_transaction_id, amount, fee_amount, status, reference_code, step,
     description, created_at, updated_at)
VALUES
    (4, 3, 3, 4, 101, NULL, NULL, 300000, 600, 'COMPLETED',
     'TXN202605260004', 1, 'Chuyển tiền hỗ trợ bạn bè', SYSTIMESTAMP, NULL);

INSERT INTO transactions
    (transaction_id, type_id, sender_wallet_id, receiver_wallet_id, limit_id, voucher_id,
     original_transaction_id, amount, fee_amount, status, reference_code, step,
     description, created_at, updated_at)
VALUES
    (5, 2, 2, NULL, 104, NULL, NULL, 1500000, 7500, 'COMPLETED',
     'TXN202605260005', 1, 'Rút tiền về ngân hàng', SYSTIMESTAMP, NULL);

INSERT INTO transactions
    (transaction_id, type_id, sender_wallet_id, receiver_wallet_id, limit_id, voucher_id,
     original_transaction_id, amount, fee_amount, status, reference_code, step,
     description, created_at, updated_at)
VALUES
    (6, 1, NULL, 10, 106, NULL, NULL, 7000000, 0, 'COMPLETED',
     'TXN202605260006', 1, 'Nạp tiền ví MOMO', SYSTIMESTAMP, NULL);

INSERT INTO transactions
    (transaction_id, type_id, sender_wallet_id, receiver_wallet_id, limit_id, voucher_id,
     original_transaction_id, amount, fee_amount, status, reference_code, step,
     description, created_at, updated_at)
VALUES
    (7, 3, 3, 7, 101, NULL, NULL, 900000, 1800, 'COMPLETED',
     'TXN202605260007', 1, 'Chuyển tiền mua hàng', SYSTIMESTAMP, NULL);

INSERT INTO transactions
    (transaction_id, type_id, sender_wallet_id, receiver_wallet_id, limit_id, voucher_id,
     original_transaction_id, amount, fee_amount, status, reference_code, step,
     description, created_at, updated_at)
VALUES
    (8, 4, 4, 10, 104, 2, NULL, 2200000, 22000, 'FAILED',
     'TXN202605260008', 1, 'Thanh toán thất bại POS', SYSTIMESTAMP, NULL);

INSERT INTO transactions
    (transaction_id, type_id, sender_wallet_id, receiver_wallet_id, limit_id, voucher_id,
     original_transaction_id, amount, fee_amount, status, reference_code, step,
     description, created_at, updated_at)
VALUES
    (9, 3, 2, 4, 104, 1, NULL, 350000, 700, 'COMPLETED',
     'TXN202605260009', 1, 'Transfer nội bộ', SYSTIMESTAMP, NULL);

INSERT INTO transactions
    (transaction_id, type_id, sender_wallet_id, receiver_wallet_id, limit_id, voucher_id,
     original_transaction_id, amount, fee_amount, status, reference_code, step,
     description, created_at, updated_at)
VALUES
    (10, 3, 3, 5, 101, 1, NULL, 450000, 900, 'PENDING',
     'TXN202605260010', 1, 'Giao dịch đang xử lý', SYSTIMESTAMP, NULL);

INSERT INTO transactions
    (transaction_id, type_id, sender_wallet_id, receiver_wallet_id, limit_id, voucher_id,
     original_transaction_id, amount, fee_amount, status, reference_code, step,
     description, created_at, updated_at)
VALUES
    (11, 4, 4, 8, 104, 4, NULL, 1800000, 18000, 'COMPLETED',
     'TXN202605260011', 1, 'Thanh toán siêu thị', SYSTIMESTAMP, NULL);

INSERT INTO transactions
    (transaction_id, type_id, sender_wallet_id, receiver_wallet_id, limit_id, voucher_id,
     original_transaction_id, amount, fee_amount, status, reference_code, step,
     description, created_at, updated_at)
VALUES
    (12, 3, 3, 1, 101, NULL, NULL, 250000, 500, 'COMPLETED',
     'TXN202605260012', 1, 'Chuyển tiền ăn uống', SYSTIMESTAMP, NULL);

INSERT INTO transactions
    (transaction_id, type_id, sender_wallet_id, receiver_wallet_id, limit_id, voucher_id,
     original_transaction_id, amount, fee_amount, status, reference_code, step,
     description, created_at, updated_at)
VALUES
    (13, 3, 7, 2, 104, NULL, NULL, 1200000, 2400, 'COMPLETED',
     'TXN202605260013', 1, 'Chuyển khoản nhanh', SYSTIMESTAMP, NULL);

INSERT INTO transactions
    (transaction_id, type_id, sender_wallet_id, receiver_wallet_id, limit_id, voucher_id,
     original_transaction_id, amount, fee_amount, status, reference_code, step,
     description, created_at, updated_at)
VALUES
    (14, 3, 2, 7, 104, 5, NULL, 3000000, 30000, 'COMPLETED',
     'TXN202605260014', 1, 'Thanh toán laptop', SYSTIMESTAMP, NULL);

INSERT INTO transactions
    (transaction_id, type_id, sender_wallet_id, receiver_wallet_id, limit_id, voucher_id,
     original_transaction_id, amount, fee_amount, status, reference_code, step,
     description, created_at, updated_at)
VALUES
    (15, 2, 5, NULL, 104, 5, NULL, 2000000, 10000, 'COMPLETED',
     'TXN202605260015', 1, 'Rút tiền ngân hàng', SYSTIMESTAMP, NULL);

INSERT INTO transactions
    (transaction_id, type_id, sender_wallet_id, receiver_wallet_id, limit_id, voucher_id,
     original_transaction_id, amount, fee_amount, status, reference_code, step,
     description, created_at, updated_at)
VALUES
    (16, 5, 5, 4, 104, NULL, NULL, 500000, 0, 'REVERSED',
     'TXN202605260016', 1, 'Đảo ngược giao dịch lỗi', SYSTIMESTAMP, NULL);

INSERT INTO transactions
    (transaction_id, type_id, sender_wallet_id, receiver_wallet_id, limit_id, voucher_id,
     original_transaction_id, amount, fee_amount, status, reference_code, step,
     description, created_at, updated_at)
VALUES
    (17, 5, 2, 4, 104, NULL, 3, 1200000, 0, 'COMPLETED',
     'TXN202605260017', 1, 'Hoàn tiền giao dịch thanh toán', SYSTIMESTAMP, NULL);

INSERT INTO transactions
    (transaction_id, type_id, sender_wallet_id, receiver_wallet_id, limit_id, voucher_id,
     original_transaction_id, amount, fee_amount, status, reference_code, step,
     description, created_at, updated_at)
VALUES
    (18, 5, 7, 2, 104, NULL, 14, 3000000, 0, 'COMPLETED',
     'TXN202605260018', 1, 'Refund mua laptop', SYSTIMESTAMP, NULL);

INSERT INTO transactions
    (transaction_id, type_id, sender_wallet_id, receiver_wallet_id, limit_id, voucher_id,
     original_transaction_id, amount, fee_amount, status, reference_code, step,
     description, created_at, updated_at)
VALUES
    (19, 3, 3, 8, 101, NULL, NULL, 650000, 1300, 'COMPLETED',
     'TXN202605260019', 1, 'Chuyển tiền gia đình', SYSTIMESTAMP, NULL);

INSERT INTO transactions
    (transaction_id, type_id, sender_wallet_id, receiver_wallet_id, limit_id, voucher_id,
     original_transaction_id, amount, fee_amount, status, reference_code, step,
     description, created_at, updated_at)
VALUES
    (20, 4, 4, 1, 104, 2, NULL, 950000, 9500, 'COMPLETED',
     'TXN202605260020', 1, 'Thanh toán hóa đơn điện', SYSTIMESTAMP, NULL);

COMMIT;

--------------------------------------------------------------------------------
-- 10. AUDIT_LOGS
--------------------------------------------------------------------------------

INSERT INTO audit_logs
    (LOG_ID, TRANSACTION_ID, WALLET_ID, ACTION_TYPE, BALANCE_BEFORE, BALANCE_AFTER, DELTA)
VALUES
    (1, 2, 3, 'DEBIT', 2300000, 1799000, -501000);

INSERT INTO audit_logs
    (LOG_ID, TRANSACTION_ID, WALLET_ID, ACTION_TYPE, BALANCE_BEFORE, BALANCE_AFTER, DELTA)
VALUES
    (2, 2, 1, 'CREDIT', 8500000, 9000000, 500000);

INSERT INTO audit_logs
    (LOG_ID, TRANSACTION_ID, WALLET_ID, ACTION_TYPE, BALANCE_BEFORE, BALANCE_AFTER, DELTA)
VALUES
    (3, 3, 4, 'DEBIT', 15400000, 14188000, -1212000);

INSERT INTO audit_logs
    (LOG_ID, TRANSACTION_ID, WALLET_ID, ACTION_TYPE, BALANCE_BEFORE, BALANCE_AFTER, DELTA)
VALUES
    (4, 3, 2, 'CREDIT', 12500000, 13700000, 1200000);

INSERT INTO audit_logs
    (LOG_ID, TRANSACTION_ID, WALLET_ID, ACTION_TYPE, BALANCE_BEFORE, BALANCE_AFTER, DELTA)
VALUES
    (5, 4, 3, 'DEBIT', 2300000, 1999400, -300600);

INSERT INTO audit_logs
    (LOG_ID, TRANSACTION_ID, WALLET_ID, ACTION_TYPE, BALANCE_BEFORE, BALANCE_AFTER, DELTA)
VALUES
    (6, 4, 4, 'CREDIT', 15400000, 15700000, 300000);

INSERT INTO audit_logs
    (LOG_ID, TRANSACTION_ID, WALLET_ID, ACTION_TYPE, BALANCE_BEFORE, BALANCE_AFTER, DELTA)
VALUES
    (7, 5, 2, 'DEBIT', 12500000, 10992500, -1507500);

INSERT INTO audit_logs
    (LOG_ID, TRANSACTION_ID, WALLET_ID, ACTION_TYPE, BALANCE_BEFORE, BALANCE_AFTER, DELTA)
VALUES
    (8, 6, 10, 'CREDIT', 21200000, 28200000, 7000000);

INSERT INTO audit_logs
    (LOG_ID, TRANSACTION_ID, WALLET_ID, ACTION_TYPE, BALANCE_BEFORE, BALANCE_AFTER, DELTA)
VALUES
    (9, 7, 3, 'DEBIT', 2300000, 1398200, -901800);

INSERT INTO audit_logs
    (LOG_ID, TRANSACTION_ID, WALLET_ID, ACTION_TYPE, BALANCE_BEFORE, BALANCE_AFTER, DELTA)
VALUES
    (10, 7, 7, 'CREDIT', 9800000, 10700000, 900000);

INSERT INTO audit_logs
    (LOG_ID, TRANSACTION_ID, WALLET_ID, ACTION_TYPE, BALANCE_BEFORE, BALANCE_AFTER, DELTA)
VALUES
    (11, 9, 2, 'DEBIT', 12500000, 12199300, -350700);

INSERT INTO audit_logs
    (LOG_ID, TRANSACTION_ID, WALLET_ID, ACTION_TYPE, BALANCE_BEFORE, BALANCE_AFTER, DELTA)
VALUES
    (12, 9, 4, 'CREDIT', 15400000, 15750000, 350000);

INSERT INTO audit_logs
    (LOG_ID, TRANSACTION_ID, WALLET_ID, ACTION_TYPE, BALANCE_BEFORE, BALANCE_AFTER, DELTA)
VALUES
    (13, 11, 4, 'DEBIT', 15400000, 13522000, -1818000);

INSERT INTO audit_logs
    (LOG_ID, TRANSACTION_ID, WALLET_ID, ACTION_TYPE, BALANCE_BEFORE, BALANCE_AFTER, DELTA)
VALUES
    (14, 11, 8, 'CREDIT', 4500000, 6300000, 1800000);

INSERT INTO audit_logs
    (LOG_ID, TRANSACTION_ID, WALLET_ID, ACTION_TYPE, BALANCE_BEFORE, BALANCE_AFTER, DELTA)
VALUES
    (15, 12, 3, 'DEBIT', 2300000, 2049500, -250500);

INSERT INTO audit_logs
    (LOG_ID, TRANSACTION_ID, WALLET_ID, ACTION_TYPE, BALANCE_BEFORE, BALANCE_AFTER, DELTA)
VALUES
    (16, 12, 1, 'CREDIT', 8500000, 8750000, 250000);

INSERT INTO audit_logs
    (LOG_ID, TRANSACTION_ID, WALLET_ID, ACTION_TYPE, BALANCE_BEFORE, BALANCE_AFTER, DELTA)
VALUES
    (17, 13, 7, 'DEBIT', 9800000, 8597600, -1202400);

INSERT INTO audit_logs
    (LOG_ID, TRANSACTION_ID, WALLET_ID, ACTION_TYPE, BALANCE_BEFORE, BALANCE_AFTER, DELTA)
VALUES
    (18, 13, 2, 'CREDIT', 12500000, 13700000, 1200000);

INSERT INTO audit_logs
    (LOG_ID, TRANSACTION_ID, WALLET_ID, ACTION_TYPE, BALANCE_BEFORE, BALANCE_AFTER, DELTA)
VALUES
    (19, 14, 2, 'DEBIT', 12500000, 9470000, -3030000);

INSERT INTO audit_logs
    (LOG_ID, TRANSACTION_ID, WALLET_ID, ACTION_TYPE, BALANCE_BEFORE, BALANCE_AFTER, DELTA)
VALUES
    (20, 14, 7, 'CREDIT', 9800000, 12800000, 3000000);

INSERT INTO audit_logs
    (LOG_ID, TRANSACTION_ID, WALLET_ID, ACTION_TYPE, BALANCE_BEFORE, BALANCE_AFTER, DELTA)
VALUES
    (21, 17, 2, 'DEBIT', 12500000, 11300000, -1200000);

INSERT INTO audit_logs
    (LOG_ID, TRANSACTION_ID, WALLET_ID, ACTION_TYPE, BALANCE_BEFORE, BALANCE_AFTER, DELTA)
VALUES
    (22, 17, 4, 'CREDIT', 15400000, 16600000, 1200000);

INSERT INTO audit_logs
    (LOG_ID, TRANSACTION_ID, WALLET_ID, ACTION_TYPE, BALANCE_BEFORE, BALANCE_AFTER, DELTA)
VALUES
    (23, 18, 7, 'DEBIT', 9800000, 6800000, -3000000);

INSERT INTO audit_logs
    (LOG_ID, TRANSACTION_ID, WALLET_ID, ACTION_TYPE, BALANCE_BEFORE, BALANCE_AFTER, DELTA)
VALUES
    (24, 18, 2, 'CREDIT', 12500000, 15500000, 3000000);

COMMIT;

-- Xem toàn bộ dữ liệu
SELECT u.user_id,
       u.full_name,
       u.email,
       u.phone,
       w.wallet_id,
       w.balance,
       t.transaction_id,
       t.amount,
       t.status
FROM users u
LEFT JOIN wallets w
       ON u.user_id = w.user_id
LEFT JOIN transactions t
       ON w.wallet_id = t.sender_wallet_id
ORDER BY u.user_id;
