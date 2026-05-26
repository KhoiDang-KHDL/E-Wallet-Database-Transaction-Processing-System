-- ============================================================
-- SEED PART 2: WALLETS, PAYMENT_METHODS, LOGIN_SESSIONS
-- Chạy SAU Part 1.
-- Giả sử users được sinh user_id từ 1 → 50 theo thứ tự INSERT.
-- Nếu sequence bắt đầu khác, hãy kiểm tra:
--   SELECT user_id, full_name FROM users ORDER BY user_id;
-- rồi điều chỉnh user_id bên dưới.
-- ============================================================

-- -------------------------------------------------------
-- 1. WALLETS (1 ví / 1 user, balance ban đầu đủ để thực hiện giao dịch test)
--    wallet_id tự sinh
--    pin_code: 6 số cố định (mỗi user có PIN riêng)
--    Balance VERIFIED users: 5tr – 50tr
--    Balance PENDING users: 500k – 2tr
-- -------------------------------------------------------

-- user_id 3161-3170
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3161,  45000000, 'VND', 'ACTIVE', '111111');
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3162,  38000000, 'VND', 'ACTIVE', '222222');
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3163,  27000000, 'VND', 'ACTIVE', '333333');
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3164,  15000000, 'VND', 'ACTIVE', '444444');
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3165,  50000000, 'VND', 'ACTIVE', '555555');
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3166,  22000000, 'VND', 'ACTIVE', '666666');
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3167,  31000000, 'VND', 'ACTIVE', '777777');
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3168,  18000000, 'VND', 'ACTIVE', '888888');
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3169,  42000000, 'VND', 'ACTIVE', '999999');
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3170,  25000000, 'VND', 'ACTIVE', '121212');

-- user_id 3171-3180
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3171, 33000000, 'VND', 'ACTIVE', '131313');
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3172, 20000000, 'VND', 'ACTIVE', '141414');
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3173, 48000000, 'VND', 'ACTIVE', '151515');
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3174, 12000000, 'VND', 'ACTIVE', '161616');
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3175, 36000000, 'VND', 'ACTIVE', '171717');
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3176, 29000000, 'VND', 'ACTIVE', '181818');
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3177, 41000000, 'VND', 'ACTIVE', '191919');
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3178, 17000000, 'VND', 'ACTIVE', '202020');
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3179, 24000000, 'VND', 'ACTIVE', '212121');
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3180, 39000000, 'VND', 'ACTIVE', '232323');

-- user_id 3181-3190
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3181, 16000000, 'VND', 'ACTIVE', '242424');
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3182, 44000000, 'VND', 'ACTIVE', '252525');
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3183, 23000000, 'VND', 'ACTIVE', '262626');
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3184, 35000000, 'VND', 'ACTIVE', '272727');
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3185, 19000000, 'VND', 'ACTIVE', '282828');
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3186, 47000000, 'VND', 'ACTIVE', '292929');
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3187, 28000000, 'VND', 'ACTIVE', '303030');
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3188, 13000000, 'VND', 'ACTIVE', '313131');
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3189, 32000000, 'VND', 'ACTIVE', '323232');
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3190, 21000000, 'VND', 'ACTIVE', '333334');

-- user_id 3191-3210 (3191, 3195, 3202 là PENDING)
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3191, 1500000,  'VND', 'ACTIVE', '343434');  -- PENDING user
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3192, 26000000, 'VND', 'ACTIVE', '353535');
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3193, 40000000, 'VND', 'ACTIVE', '363636');
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3194, 14000000, 'VND', 'ACTIVE', '373737');
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3195, 800000,   'VND', 'ACTIVE', '383838');  -- PENDING user
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3196, 37000000, 'VND', 'ACTIVE', '393939');
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3197, 43000000, 'VND', 'ACTIVE', '404040');
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3198, 11000000, 'VND', 'ACTIVE', '414141');
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3199, 34000000, 'VND', 'ACTIVE', '424242');
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3200, 46000000, 'VND', 'ACTIVE', '434343');
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3201, 30000000, 'VND', 'ACTIVE', '454545');
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3202, 1200000,  'VND', 'ACTIVE', '464646');  -- PENDING user
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3203, 49000000, 'VND', 'ACTIVE', '474747');
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3204, 8000000,  'VND', 'ACTIVE', '484848');
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3205, 26000000, 'VND', 'ACTIVE', '494949');
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3206, 33000000, 'VND', 'ACTIVE', '505050');
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3207, 19000000, 'VND', 'ACTIVE', '515151');
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3208, 42000000, 'VND', 'ACTIVE', '525252');
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3209, 55000000, 'VND', 'ACTIVE', '535353');
INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
VALUES (3210, 7000000,  'VND', 'ACTIVE', '545454');

COMMIT;

-- -------------------------------------------------------
-- 2. PAYMENT_METHODS
--    method_id tự sinh
--    Mỗi user 1-3 phương thức, chỉ 1 is_default=1
--    masked_number: số tài khoản/thẻ tường minh
--    method_type: 'BANK_ACCOUNT' hoặc 'CREDIT_CARD'
--    Ngân hàng Việt: Vietcombank, Techcombank, BIDV, VietinBank, MBBank, TPBank, VPBank
-- -------------------------------------------------------

-- User 3161: 2 phương thức
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3161, 'BANK_ACCOUNT', 'Vietcombank',  '1234567890',     1, 1, 1);
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3161, 'CREDIT_CARD',  'Techcombank',  '4111111111111001', 0, 1, 1);

-- User 3162: 1 phương thức
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3162, 'BANK_ACCOUNT', 'BIDV',         '2000000002',     1, 1, 1);

-- User 3163: 3 phương thức
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3163, 'BANK_ACCOUNT', 'Vietcombank',  '3000000003',     1, 1, 1);
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3163, 'BANK_ACCOUNT', 'MBBank',       '3000000303',     0, 1, 1);
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3163, 'CREDIT_CARD',  'VPBank',       '4111111111113003', 0, 1, 1);

-- User 3164: 2 phương thức
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3164, 'BANK_ACCOUNT', 'Techcombank',  '4000000004',     1, 1, 1);
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3164, 'CREDIT_CARD',  'Vietcombank',  '4111111111114004', 0, 1, 1);

-- User 3165: 1 phương thức
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3165, 'BANK_ACCOUNT', 'VietinBank',   '5000000005',     1, 1, 1);

-- User 3166: 2 phương thức
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3166, 'BANK_ACCOUNT', 'MBBank',       '6000000006',     1, 1, 1);
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3166, 'BANK_ACCOUNT', 'TPBank',       '6000000606',     0, 1, 1);

-- User 3167: 3 phương thức
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3167, 'BANK_ACCOUNT', 'Vietcombank',  '7000000007',     1, 1, 1);
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3167, 'BANK_ACCOUNT', 'BIDV',         '7000000707',     0, 1, 1);
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3167, 'CREDIT_CARD',  'Techcombank',  '4111111111117007', 0, 1, 1);

-- User 3168: 1 phương thức
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3168, 'BANK_ACCOUNT', 'VPBank',       '8000000008',     1, 1, 1);

-- User 3169: 2 phương thức
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3169, 'BANK_ACCOUNT', 'Techcombank',  '9000000009',     1, 1, 1);
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3169, 'CREDIT_CARD',  'MBBank',       '4111111111119009', 0, 1, 1);

-- User 3170: 1 phương thức
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3170, 'BANK_ACCOUNT', 'BIDV',         '1000000010',     1, 1, 1);

-- User 3171: 2 phương thức
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3171, 'BANK_ACCOUNT', 'VietinBank',  '1100000011',     1, 1, 1);
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3171, 'CREDIT_CARD',  'TPBank',      '4111111111111101', 0, 1, 1);

-- User 3172: 1 phương thức
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3172, 'BANK_ACCOUNT', 'Vietcombank', '1200000012',     1, 1, 1);

-- User 3173: 3 phương thức
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3173, 'BANK_ACCOUNT', 'MBBank',      '1300000013',     1, 1, 1);
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3173, 'BANK_ACCOUNT', 'Techcombank', '1300001313',     0, 1, 1);
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3173, 'CREDIT_CARD',  'VPBank',      '4111111111131313', 0, 1, 1);

-- User 3174: 1 phương thức
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3174, 'BANK_ACCOUNT', 'BIDV',        '1400000014',     1, 1, 1);

-- User 3175: 2 phương thức
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3175, 'BANK_ACCOUNT', 'Vietcombank', '1500000015',     1, 1, 1);
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3175, 'CREDIT_CARD',  'MBBank',      '4111111111151515', 0, 1, 1);

-- User 3176: 1 phương thức
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3176, 'BANK_ACCOUNT', 'TPBank',      '1600000016',     1, 1, 1);

-- User 3177: 2 phương thức
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3177, 'BANK_ACCOUNT', 'VPBank',      '1700000017',     1, 1, 1);
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3177, 'BANK_ACCOUNT', 'VietinBank',  '1700001717',     0, 1, 1);

-- User 3178: 1 phương thức
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3178, 'BANK_ACCOUNT', 'Techcombank', '1800000018',     1, 1, 1);

-- User 3179: 3 phương thức
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3179, 'BANK_ACCOUNT', 'Vietcombank', '1900000019',     1, 1, 1);
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3179, 'BANK_ACCOUNT', 'BIDV',        '1900001919',     0, 1, 1);
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3179, 'CREDIT_CARD',  'TPBank',      '4111111111191919', 0, 1, 1);

-- User 3180: 1 phương thức
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3180, 'BANK_ACCOUNT', 'MBBank',      '2000000020',     1, 1, 1);

-- User 3181: 2 phương thức
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3181, 'BANK_ACCOUNT', 'Vietcombank', '2100000021',     1, 1, 1);
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3181, 'CREDIT_CARD',  'Techcombank', '4111111111212121', 0, 1, 1);

-- User 3182: 1 phương thức
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3182, 'BANK_ACCOUNT', 'BIDV',        '2200000022',     1, 1, 1);

-- User 3183: 2 phương thức
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3183, 'BANK_ACCOUNT', 'VietinBank',  '2300000023',     1, 1, 1);
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3183, 'BANK_ACCOUNT', 'VPBank',      '2300002323',     0, 1, 1);

-- User 3184: 1 phương thức
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3184, 'BANK_ACCOUNT', 'TPBank',      '2400000024',     1, 1, 1);

-- User 3185: 3 phương thức
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3185, 'BANK_ACCOUNT', 'Techcombank', '2500000025',     1, 1, 1);
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3185, 'BANK_ACCOUNT', 'MBBank',      '2500002525',     0, 1, 1);
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3185, 'CREDIT_CARD',  'Vietcombank', '4111111111252525', 0, 1, 1);

-- User 3186: 1 phương thức
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3186, 'BANK_ACCOUNT', 'Vietcombank', '2600000026',     1, 1, 1);

-- User 3187: 2 phương thức
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3187, 'BANK_ACCOUNT', 'BIDV',        '2700000027',     1, 1, 1);
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3187, 'CREDIT_CARD',  'TPBank',      '4111111111272727', 0, 1, 1);

-- User 3188: 1 phương thức
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3188, 'BANK_ACCOUNT', 'VietinBank',  '2800000028',     1, 1, 1);

-- User 3189: 2 phương thức
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3189, 'BANK_ACCOUNT', 'MBBank',      '2900000029',     1, 1, 1);
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3189, 'BANK_ACCOUNT', 'VPBank',      '2900002929',     0, 1, 1);

-- User 3190: 1 phương thức
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3190, 'BANK_ACCOUNT', 'Techcombank', '3000000030',     1, 1, 1);

-- User 3191: 1 phương thức (PENDING user)
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3191, 'BANK_ACCOUNT', 'Vietcombank', '3100000031',     1, 1, 1);

-- User 3192: 2 phương thức
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3192, 'BANK_ACCOUNT', 'BIDV',        '3200000032',     1, 1, 1);
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3192, 'CREDIT_CARD',  'MBBank',      '4111111111323232', 0, 1, 1);

-- User 3193: 1 phương thức
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3193, 'BANK_ACCOUNT', 'VietinBank',  '3300000033',     1, 1, 1);

-- User 3194: 2 phương thức
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3194, 'BANK_ACCOUNT', 'TPBank',      '3400000034',     1, 1, 1);
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3194, 'BANK_ACCOUNT', 'Techcombank', '3400003434',     0, 1, 1);

-- User 3195: 1 phương thức (PENDING user)
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3195, 'BANK_ACCOUNT', 'Vietcombank', '3500000035',     1, 1, 1);

-- User 3196: 2 phương thức
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3196, 'BANK_ACCOUNT', 'VPBank',      '3600000036',     1, 1, 1);
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3196, 'CREDIT_CARD',  'BIDV',        '4111111111363636', 0, 1, 1);

-- User 3197: 1 phương thức
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3197, 'BANK_ACCOUNT', 'MBBank',      '3700000037',     1, 1, 1);

-- User 3198: 3 phương thức
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3198, 'BANK_ACCOUNT', 'Vietcombank', '3800000038',     1, 1, 1);
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3198, 'BANK_ACCOUNT', 'Techcombank', '3800003838',     0, 1, 1);
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3198, 'CREDIT_CARD',  'VietinBank',  '4111111111383838', 0, 1, 1);

-- User 3199: 1 phương thức
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3199, 'BANK_ACCOUNT', 'BIDV',        '3900000039',     1, 1, 1);

-- User 3200: 2 phương thức
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3200, 'BANK_ACCOUNT', 'TPBank',      '4000000040',     1, 1, 1);
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3200, 'CREDIT_CARD',  'MBBank',      '4111111111404040', 0, 1, 1);

-- User 3201: 1 phương thức
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3201, 'BANK_ACCOUNT', 'VPBank',      '4100000041',     1, 1, 1);

-- User 3202: 1 phương thức (PENDING user)
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3202, 'BANK_ACCOUNT', 'Vietcombank', '4200000042',     1, 1, 1);

-- User 3203: 2 phương thức
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3203, 'BANK_ACCOUNT', 'Techcombank', '4300000043',     1, 1, 1);
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3203, 'BANK_ACCOUNT', 'BIDV',        '4300004343',     0, 1, 1);

-- User 3204: 1 phương thức
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3204, 'BANK_ACCOUNT', 'MBBank',      '4400000044',     1, 1, 1);

-- User 3205: 2 phương thức
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3205, 'BANK_ACCOUNT', 'VietinBank',  '4500000045',     1, 1, 1);
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3205, 'CREDIT_CARD',  'Vietcombank', '4111111111454545', 0, 1, 1);

-- User 3206: 1 phương thức
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3206, 'BANK_ACCOUNT', 'Vietcombank', '4600000046',     1, 1, 1);

-- User 3207: 2 phương thức
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3207, 'BANK_ACCOUNT', 'TPBank',      '4700000047',     1, 1, 1);
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3207, 'BANK_ACCOUNT', 'VPBank',      '4700004747',     0, 1, 1);

-- User 3208: 3 phương thức
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3208, 'BANK_ACCOUNT', 'Techcombank', '4800000048',     1, 1, 1);
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3208, 'BANK_ACCOUNT', 'MBBank',      '4800004848',     0, 1, 1);
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3208, 'CREDIT_CARD',  'BIDV',        '4111111111484848', 0, 1, 1);

-- User 3209: 1 phương thức
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3209, 'BANK_ACCOUNT', 'Vietcombank', '4900000049',     1, 1, 1);

-- User 3210: 2 phương thức
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3210, 'BANK_ACCOUNT', 'BIDV',        '5000000050',     1, 1, 1);
INSERT INTO payment_methods (user_id, method_type, provider_name, masked_number, is_default, is_verified, is_active)
VALUES (3210, 'CREDIT_CARD',  'VietinBank',  '4111111111505050', 0, 1, 1);

COMMIT;
-- -------------------------------------------------------
-- 3. LOGIN_SESSIONS
--    Tạo 1-2 session cho mỗi user, chỉ dùng thiết bị di động
-- -------------------------------------------------------
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3161, 'iPhone 14 Pro / iOS 17.4',           '192.168.1.101', 1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3162, 'Samsung Galaxy S23 / Android 14',    '192.168.1.102', 1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3163, 'Xiaomi 13 / Android 13',             '192.168.1.103', 1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3163, 'OPPO Reno 10 / Android 13',          '192.168.1.203', 0);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3164, 'iPhone 15 / iOS 17.5',               '192.168.1.104', 1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3165, 'Samsung Galaxy A54 / Android 13',    '192.168.1.105', 1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3166, 'Vivo V27 / Android 13',              '192.168.1.106', 1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3167, 'iPhone 13 / iOS 16.7',               '192.168.1.107', 1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3167, 'Realme 11 Pro / Android 13',         '192.168.1.207', 0);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3168, 'Xiaomi Redmi Note 12 / Android 13',  '192.168.1.108', 1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3169, 'Samsung Galaxy S22 / Android 13',    '192.168.1.109', 1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3170, 'iPhone 12 / iOS 15.8',               '192.168.1.110', 1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3171, 'OPPO A98 / Android 13',              '192.168.1.111', 1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3172, 'Xiaomi 12 / Android 13',             '192.168.1.112', 1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3173, 'iPhone 14 / iOS 16.6',               '192.168.1.113', 1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3173, 'Samsung Galaxy M54 / Android 13',   '192.168.1.213', 0);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3174, 'Vivo Y36 / Android 13',              '192.168.1.114', 1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3175, 'Realme C55 / Android 13',            '192.168.1.115', 1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3176, 'Samsung Galaxy A34 / Android 13',   '192.168.1.116', 1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3177, 'iPhone 13 mini / iOS 16.7',          '192.168.1.117', 1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3178, 'OPPO Reno8 / Android 12',            '192.168.1.118', 1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3179, 'Xiaomi Redmi 12 / Android 13',       '192.168.1.119', 1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3180, 'Samsung Galaxy S21 / Android 13',   '192.168.1.120', 1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3181, 'iPhone 11 / iOS 15.8',               '192.168.1.121', 1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3182, 'Vivo V25 / Android 12',              '192.168.1.122', 1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3183, 'Realme GT Neo3 / Android 12',        '192.168.1.123', 1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3184, 'Samsung Galaxy A24 / Android 13',   '192.168.1.124', 1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3185, 'iPhone SE 3rd / iOS 16.7',           '192.168.1.125', 1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3186, 'Xiaomi 11T / Android 12',            '192.168.1.126', 1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3187, 'OPPO Find X6 / Android 13',          '192.168.1.127', 1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3188, 'Samsung Galaxy Note 20 / Android 13','192.168.1.128', 1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3189, 'iPhone 12 Pro / iOS 16.7',           '192.168.1.129', 1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3190, 'Vivo X90 / Android 13',              '192.168.1.130', 1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3191, 'Redmi 10C / Android 11',             '192.168.1.131', 1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3192, 'Samsung Galaxy A14 / Android 13',   '192.168.1.132', 1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3193, 'iPhone 14 Plus / iOS 16.6',          '192.168.1.133', 1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3194, 'OPPO A77 / Android 12',              '192.168.1.134', 1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3195, 'Xiaomi Poco X5 / Android 12',        '192.168.1.135', 1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3196, 'Samsung Galaxy S20 FE / Android 13','192.168.1.136', 1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3197, 'iPhone 13 Pro / iOS 17.2',           '192.168.1.137', 1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3198, 'Realme Narzo 60 / Android 13',       '192.168.1.138', 1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3199, 'Vivo Y55s / Android 11',             '192.168.1.139', 1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3200, 'Samsung Galaxy A53 / Android 13',   '192.168.1.140', 1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3201, 'iPhone 15 Pro / iOS 17.5',           '192.168.1.141', 1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3202, 'Xiaomi Redmi Note 11 / Android 11',  '192.168.1.142', 1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3203, 'Samsung Galaxy S23 Ultra / Android 14','192.168.1.143',1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3204, 'OPPO Reno 9 / Android 13',           '192.168.1.144', 1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3205, 'iPhone 14 Pro Max / iOS 17.4',       '192.168.1.145', 1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3206, 'Vivo V29 / Android 13',              '192.168.1.146', 1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3207, 'Realme 10 Pro+ / Android 13',        '192.168.1.147', 1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3208, 'Samsung Galaxy Z Fold 5 / Android 14','192.168.1.148',1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3209, 'iPhone 15 Plus / iOS 17.5',          '192.168.1.149', 1);
INSERT INTO login_sessions (user_id, device_info, ip_address, is_active) VALUES (3210, 'Xiaomi 13 Pro / Android 13',         '192.168.1.150', 1);

COMMIT;