-- ============================================================
-- SEED PART 1: MASTER DATA
-- Thứ tự: users → transaction_limits → vouchers
-- Chạy file này trước tiên.
-- ============================================================
--ALTER TRIGGER trg_prevent_audit_log_u_d DISABLE;
--
--DELETE FROM audit_logs;
--DELETE FROM transactions;
--DELETE FROM fund_orders;
--DELETE FROM login_sessions;
--DELETE FROM payment_methods;
--DELETE FROM wallets;
--DELETE FROM vouchers;
--DELETE FROM transaction_fees;
--DELETE FROM users;
--DELETE FROM transaction_limits;
--
--COMMIT;
--
--ALTER TRIGGER trg_prevent_audit_log_u_d ENABLE;
-- -------------------------------------------------------
-- 1. USERS (50 người dùng Việt Nam)
--    user_id tự sinh → KHÔNG chỉ định giá trị
--    kyc_status DEFAULT 'VERIFIED', is_active DEFAULT 1
--    Một số user có kyc_status = 'PENDING' để test hạn mức khác nhau
-- -------------------------------------------------------
INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Nguyễn Văn An',        'an.nguyen@gmail.com',        '0901000001', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'VERIFIED', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Trần Thị Bình',        'binh.tran@gmail.com',        '0901000002', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'VERIFIED', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Lê Minh Cường',        'cuong.le@gmail.com',         '0901000003', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'VERIFIED', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Phạm Thị Dung',        'dung.pham@gmail.com',        '0901000004', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'VERIFIED', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Hoàng Văn Em',         'em.hoang@gmail.com',         '0901000005', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'VERIFIED', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Vũ Thị Phương',        'phuong.vu@gmail.com',        '0901000006', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'VERIFIED', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Đặng Quốc Giang',      'giang.dang@gmail.com',       '0901000007', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'VERIFIED', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Bùi Thị Hoa',          'hoa.bui@gmail.com',          '0901000008', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'VERIFIED', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Ngô Thanh Hùng',       'hung.ngo@gmail.com',         '0901000009', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'VERIFIED', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Đinh Thị Lan',         'lan.dinh@gmail.com',         '0901000010', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'VERIFIED', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Trịnh Văn Khánh',      'khanh.trinh@gmail.com',      '0901000011', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'VERIFIED', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Lý Thị Mai',           'mai.ly@gmail.com',           '0901000012', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'VERIFIED', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Phan Đình Nam',        'nam.phan@gmail.com',         '0901000013', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'VERIFIED', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Hà Thị Oanh',          'oanh.ha@gmail.com',          '0901000014', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'VERIFIED', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Cao Minh Phát',        'phat.cao@gmail.com',         '0901000015', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'VERIFIED', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Lưu Thị Quyên',        'quyen.luu@gmail.com',        '0901000016', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'VERIFIED', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Đỗ Văn Rồng',          'rong.do@gmail.com',          '0901000017', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'VERIFIED', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Nguyễn Thị Sương',     'suong.nguyen@gmail.com',     '0901000018', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'VERIFIED', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Trần Thanh Tâm',       'tam.tran@gmail.com',         '0901000019', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'VERIFIED', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Võ Thị Uyên',          'uyen.vo@gmail.com',          '0901000020', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'VERIFIED', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Huỳnh Quốc Việt',      'viet.huynh@gmail.com',       '0901000021', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'VERIFIED', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Dương Thị Xuân',       'xuan.duong@gmail.com',       '0901000022', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'VERIFIED', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Mai Văn Ý',             'y.mai@gmail.com',            '0901000023', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'VERIFIED', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Tô Thị Ánh',           'anh.to@gmail.com',           '0901000024', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'VERIFIED', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Lê Công Bằng',         'bang.le@gmail.com',          '0901000025', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'VERIFIED', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Nguyễn Thị Cẩm',       'cam.nguyen@gmail.com',       '0901000026', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'VERIFIED', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Phạm Hữu Dũng',        'dung2.pham@gmail.com',       '0901000027', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'VERIFIED', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Trần Thị Điệp',        'diep.tran@gmail.com',        '0901000028', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'VERIFIED', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Hoàng Minh Đức',       'duc.hoang@gmail.com',        '0901000029', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'VERIFIED', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Vũ Thị Gấm',           'gam.vu@gmail.com',           '0901000030', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'VERIFIED', 1);

-- 20 user tiếp theo: mix PENDING/VERIFIED
INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Bùi Thị Hằng',         'hang.bui@gmail.com',         '0901000031', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'PENDING', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Đặng Văn Hiếu',        'hieu.dang@gmail.com',        '0901000032', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'VERIFIED', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Ngô Thị Hương',        'huong.ngo@gmail.com',        '0901000033', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'VERIFIED', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Đinh Văn Khoa',        'khoa.dinh@gmail.com',        '0901000034', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'VERIFIED', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Trịnh Thị Linh',       'linh.trinh@gmail.com',       '0901000035', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'PENDING', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Lý Văn Long',           'long.ly@gmail.com',          '0901000036', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'VERIFIED', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Phan Thị Mộng',        'mong.phan@gmail.com',        '0901000037', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'VERIFIED', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Hà Quốc Năng',         'nang.ha@gmail.com',          '0901000038', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'VERIFIED', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Cao Thị Nhung',        'nhung.cao@gmail.com',        '0901000039', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'VERIFIED', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Lưu Văn Phong',        'phong.luu@gmail.com',        '0901000040', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'VERIFIED', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Đỗ Thị Quỳnh',         'quynh.do@gmail.com',         '0901000041', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'VERIFIED', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Nguyễn Hữu Sang',      'sang.nguyen@gmail.com',      '0901000042', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'PENDING', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Trần Thị Thắm',        'tham.tran@gmail.com',        '0901000043', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'VERIFIED', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Lê Thị Thu',            'thu.le@gmail.com',           '0901000044', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'VERIFIED', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Phạm Văn Tiến',        'tien.pham@gmail.com',        '0901000045', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'VERIFIED', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Hoàng Thị Trang',      'trang.hoang@gmail.com',      '0901000046', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'VERIFIED', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Vũ Đức Trung',         'trung.vu@gmail.com',         '0901000047', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'VERIFIED', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Đặng Thị Tuyết',       'tuyet.dang@gmail.com',       '0901000048', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'VERIFIED', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Bùi Quang Vũ',         'vu.bui@gmail.com',           '0901000049', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'VERIFIED', 1);

INSERT INTO users (full_name, email, phone, password_hash, kyc_status, is_active)
VALUES ('Ngô Thị Yến',          'yen.ngo@gmail.com',          '0901000050', '$2b$12$jpRRpziubXV8LjvED5z9XutG7y6V1J62ZPZA7UY0UYx7eJwjkaklS', 'VERIFIED', 1);

COMMIT;

-- -------------------------------------------------------
-- 2. TRANSACTION_LIMITS
--    Đã có seed data từ create_DB.sql?
--    → Không có, cần INSERT tại đây.
--    Dùng limit_id cố định (không dùng IDENTITY)
--    VERIFIED: 50tr/giao dịch, 200tr/ngày, 20 lần/ngày
--    UNVERIFIED (PENDING/REJECTED): 2tr/giao dịch, 5tr/ngày, 5 lần/ngày
--    Lưu ý: kyc_level chỉ nhận 'VERIFIED' hoặc 'UNVERIFIED' (theo CHECK constraint)
-- -------------------------------------------------------
INSERT INTO transaction_limits (limit_id, kyc_level, max_amount_per_trans, max_amount_per_day, max_trans_per_day)
VALUES (1, 'VERIFIED',   50000000, 200000000, 20);
 
INSERT INTO transaction_limits (limit_id, kyc_level, max_amount_per_trans, max_amount_per_day, max_trans_per_day)
VALUES (2, 'UNVERIFIED',  2000000,  10000000,  5);

COMMIT;

-- -------------------------------------------------------
-- 3. VOUCHERS (50 vouchers)
--    voucher_id tự sinh
--    Discount_type: FIXED hoặc PERCENTAGE
--    PERCENTAGE: discount_value là tỉ lệ thập phân (0.05 = 5%)
--    FIXED: discount_value là số tiền VND cố định
--    amount_vouchers: 100-200
-- -------------------------------------------------------

-- FIXED vouchers (25 cái)
INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('FIXED5K',   'FIXED',  5000,    50000,  NULL,  SYSTIMESTAMP + INTERVAL '365' DAY(4), 150, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('FIXED10K',  'FIXED',  10000,   100000, NULL,  SYSTIMESTAMP + INTERVAL '365' DAY(4), 120, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('FIXED20K',  'FIXED',  20000,   200000, NULL,  SYSTIMESTAMP + INTERVAL '365' DAY(3), 100, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('FIXED50K',  'FIXED',  50000,   500000, NULL,  SYSTIMESTAMP + INTERVAL '365' DAY(4), 130, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('FIXED100K', 'FIXED',  100000, 1000000, NULL,  SYSTIMESTAMP + INTERVAL '365' DAY(4), 110, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('FIXED15K',  'FIXED',  15000,   150000, NULL,  SYSTIMESTAMP + INTERVAL '180' DAY(3), 140, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('FIXED30K',  'FIXED',  30000,   300000, NULL,  SYSTIMESTAMP + INTERVAL '180' DAY(3), 160, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('FIXED25K',  'FIXED',  25000,   250000, NULL,  SYSTIMESTAMP + INTERVAL '180' DAY(4), 200, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('FIXED40K',  'FIXED',  40000,   400000, NULL,  SYSTIMESTAMP + INTERVAL '180' DAY(3), 180, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('FIXED75K',  'FIXED',  75000,   750000, NULL,  SYSTIMESTAMP + INTERVAL '180' DAY(3), 170, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('TET5K',     'FIXED',  5000,    50000,  NULL,  SYSTIMESTAMP + INTERVAL '90'  DAY(4), 200, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('TET20K',    'FIXED',  20000,   200000, NULL,  SYSTIMESTAMP + INTERVAL '90'  DAY(4), 150, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('TET50K',    'FIXED',  50000,   500000, NULL,  SYSTIMESTAMP + INTERVAL '90'  DAY(4), 120, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('SUMMER10K', 'FIXED',  10000,   100000, NULL,  SYSTIMESTAMP + INTERVAL '60'  DAY(4), 190, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('SUMMER30K', 'FIXED',  30000,   300000, NULL,  SYSTIMESTAMP + INTERVAL '60'  DAY(4), 130, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('NEWUSER10', 'FIXED',  10000,   50000,  NULL,  SYSTIMESTAMP + INTERVAL '30'  DAY(4), 200, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('NEWUSER25', 'FIXED',  25000,   100000, NULL,  SYSTIMESTAMP + INTERVAL '30'  DAY(4), 160, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('NEWUSER50', 'FIXED',  50000,   200000, NULL,  SYSTIMESTAMP + INTERVAL '30'  DAY(4), 140, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('VIP10K',    'FIXED',  10000,   100000, NULL,  SYSTIMESTAMP + INTERVAL '365' DAY(4), 100, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('VIP50K',    'FIXED',  50000,   500000, NULL,  SYSTIMESTAMP + INTERVAL '365' DAY(4), 100, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('FLASH5K',   'FIXED',  5000,    50000,  NULL,  SYSTIMESTAMP + INTERVAL '7'   DAY(4), 200, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('FLASH10K',  'FIXED',  10000,   100000, NULL,  SYSTIMESTAMP + INTERVAL '7'   DAY(4), 200, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('FLASH20K',  'FIXED',  20000,   200000, NULL,  SYSTIMESTAMP + INTERVAL '7'   DAY(4), 200, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('LOYALTY5K', 'FIXED',  5000,    50000,  NULL,  SYSTIMESTAMP + INTERVAL '365' DAY(4), 150, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('LOYALTY20K','FIXED',  20000,   200000, NULL,  SYSTIMESTAMP + INTERVAL '365' DAY(4), 150, 1);

-- PERCENTAGE vouchers (25 cái)
-- discount_value là tỉ lệ thập phân (0.02 = 2%)
INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('PCT1',  'PERCENTAGE', 0.01, 100000,  10000,  SYSTIMESTAMP + INTERVAL '365' DAY(4), 200, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('PCT2',  'PERCENTAGE', 0.02, 200000,  20000,  SYSTIMESTAMP + INTERVAL '365' DAY(4), 180, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('PCT3',  'PERCENTAGE', 0.03, 200000,  30000,  SYSTIMESTAMP + INTERVAL '365' DAY(4), 170, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('PCT5',  'PERCENTAGE', 0.05, 300000,  50000,  SYSTIMESTAMP + INTERVAL '365' DAY(4), 160, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('PCT10', 'PERCENTAGE', 0.10, 500000, 100000,  SYSTIMESTAMP + INTERVAL '365' DAY(4), 120, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('PCT15', 'PERCENTAGE', 0.15, 500000, 150000,  SYSTIMESTAMP + INTERVAL '365' DAY(4), 110, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('PCT20', 'PERCENTAGE', 0.20, 1000000,200000,  SYSTIMESTAMP + INTERVAL '180' DAY(4), 100, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('TET2PCT',   'PERCENTAGE', 0.02, 200000, 20000, SYSTIMESTAMP + INTERVAL '90' DAY(4), 200, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('TET5PCT',   'PERCENTAGE', 0.05, 300000, 50000, SYSTIMESTAMP + INTERVAL '90' DAY(4), 180, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('TET10PCT',  'PERCENTAGE', 0.10, 500000,100000, SYSTIMESTAMP + INTERVAL '90' DAY(4), 150, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('SUMMER1PCT','PERCENTAGE', 0.01, 100000, 10000, SYSTIMESTAMP + INTERVAL '60' DAY(4), 200, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('SUMMER5PCT','PERCENTAGE', 0.05, 300000, 50000, SYSTIMESTAMP + INTERVAL '60' DAY(4), 160, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('NEW2PCT',   'PERCENTAGE', 0.02, 100000, 20000, SYSTIMESTAMP + INTERVAL '30' DAY(4), 200, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('NEW5PCT',   'PERCENTAGE', 0.05, 200000, 50000, SYSTIMESTAMP + INTERVAL '30' DAY(4), 180, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('VIP5PCT',   'PERCENTAGE', 0.05, 500000, 50000, SYSTIMESTAMP + INTERVAL '365' DAY(4), 100, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('VIP10PCT',  'PERCENTAGE', 0.10, 1000000,100000,SYSTIMESTAMP + INTERVAL '365' DAY(4), 100, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('FLASH1PCT', 'PERCENTAGE', 0.01,  50000,  5000, SYSTIMESTAMP + INTERVAL '7'  DAY(4), 200, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('FLASH3PCT', 'PERCENTAGE', 0.03, 100000, 30000, SYSTIMESTAMP + INTERVAL '7'  DAY(4), 200, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('FLASH5PCT', 'PERCENTAGE', 0.05, 200000, 50000, SYSTIMESTAMP + INTERVAL '7'  DAY(4), 200, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('LOY2PCT',   'PERCENTAGE', 0.02, 200000, 20000, SYSTIMESTAMP + INTERVAL '365' DAY(4), 150, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('LOY5PCT',   'PERCENTAGE', 0.05, 500000, 50000, SYSTIMESTAMP + INTERVAL '365' DAY(4), 150, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('HOLI2PCT',  'PERCENTAGE', 0.02, 100000, 20000, SYSTIMESTAMP + INTERVAL '120' DAY(4), 180, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('HOLI5PCT',  'PERCENTAGE', 0.05, 300000, 50000, SYSTIMESTAMP + INTERVAL '120' DAY(4), 160, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('HOLI10PCT', 'PERCENTAGE', 0.10, 500000,100000, SYSTIMESTAMP + INTERVAL '120' DAY(4), 130, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('SPEC2PCT',  'PERCENTAGE', 0.02, 200000, 20000, SYSTIMESTAMP + INTERVAL '45'  DAY(4), 170, 1);

INSERT INTO vouchers (code, discount_type, discount_value, min_order_value, max_discount, valid_until, amount_vouchers, is_active)
VALUES ('SPEC5PCT',  'PERCENTAGE', 0.05, 300000, 50000, SYSTIMESTAMP + INTERVAL '45'  DAY(4), 140, 1);

COMMIT;
