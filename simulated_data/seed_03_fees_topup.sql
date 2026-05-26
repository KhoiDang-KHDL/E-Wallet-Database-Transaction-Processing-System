-- ============================================================
-- SEED PART 3: TRANSACTION_FEES + FUND_ORDERS (TOP_UP)
-- Chạy SAU Part 2.
-- ============================================================

-- -------------------------------------------------------
-- 1. TRANSACTION_FEES
--    fee_id dùng số cố định (không phải IDENTITY)
--    type_id: 1=TOP_UP, 2=WITHDRAW, 3=TRANSFER, 4=PAYMENT, 5=REVERSAL, 6=REFUND
-- -------------------------------------------------------
INSERT INTO transaction_fees (fee_id, type_id, fee_rate, fee_fixed, min_fee, max_fee, effective_from, effective_to)
VALUES (1, 1, 0.0000, 0,     0,    NULL, DATE '2024-01-01', NULL);   -- TOP_UP: miễn phí

INSERT INTO transaction_fees (fee_id, type_id, fee_rate, fee_fixed, min_fee, max_fee, effective_from, effective_to)
VALUES (2, 2, 0.0100, 0,     5000, 100000, DATE '2024-01-01', NULL); -- WITHDRAW: 1%, tối thiểu 5k, tối đa 100k

INSERT INTO transaction_fees (fee_id, type_id, fee_rate, fee_fixed, min_fee, max_fee, effective_from, effective_to)
VALUES (3, 3, 0.0050, 0,     2000, 50000, DATE '2024-01-01', NULL);  -- TRANSFER: 0.5%, tối thiểu 2k, tối đa 50k

INSERT INTO transaction_fees (fee_id, type_id, fee_rate, fee_fixed, min_fee, max_fee, effective_from, effective_to)
VALUES (4, 4, 0.0000, 0,     0,    NULL, DATE '2024-01-01', NULL);   -- PAYMENT: miễn phí

INSERT INTO transaction_fees (fee_id, type_id, fee_rate, fee_fixed, min_fee, max_fee, effective_from, effective_to)
VALUES (5, 5, 0.0000, 0,     0,    NULL, DATE '2024-01-01', NULL);   -- REVERSAL: miễn phí

INSERT INTO transaction_fees (fee_id, type_id, fee_rate, fee_fixed, min_fee, max_fee, effective_from, effective_to)
VALUES (6, 6, 0.0000, 0,     0,    NULL, DATE '2024-01-01', NULL);   -- REFUND: miễn phí

COMMIT;

-- ============================================================
-- SEED PART 3B: FUND_ORDERS TOP_UP + TRANSACTIONS TOP_UP + AUDIT_LOGS
--
-- Chiến lược:
--   - Nạp tiền (TOP_UP) không có sender_wallet_id, chỉ có receiver_wallet_id
--   - Mỗi fund_order TOP_UP SUCCESS kéo theo 1 transaction COMPLETED + audit CREDIT
--   - Balance ví đã được set sẵn ở Part 2 (coi đó là số dư SAU KHI đã top-up nhiều lần)
--   - Chúng ta ghi nhận lịch sử top-up, balance_before/after được tính ngược lại
--     theo cách: balance_before = balance_hiện_tại - amount (ước lượng)
--   - Cách đơn giản: ghi audit_log với balance_before/after consistent nội bộ
--     mà không cần phải trùng khớp 100% với số dư hiện tại
--     (vì đây là dữ liệu lịch sử mô phỏng nhiều thời điểm khác nhau)
--
-- Để tránh vi phạm triggers:
--   - TOP_UP: sender_wallet_id = NULL (đúng spec cho loại nạp tiền)
--   - WITHDRAW: receiver_wallet_id = NULL
--   - TRANSFER: cả 2 phải có
--   - reference_code phải UNIQUE → dùng prefix + số để phân biệt
-- ============================================================

-- -------------------------------------------------------
-- FUND_ORDERS TOP_UP (50 lệnh nạp tiền – 1 per user)
-- Giả sử wallet_id và method_id được sinh tuần tự từ 1
-- wallet_id 1..50 tương ứng user 1..50
-- method_id: mỗi user có ít nhất 1 method; method đầu tiên của user là default
-- Để an toàn, dùng sub-query lấy method_id default của từng user
-- -------------------------------------------------------

-- Tạo 50 fund_orders TOP_UP SUCCESS cùng transactions và audit_logs
-- Sử dụng PL/SQL block để dễ quản lý reference_code unique và balance_before/after

DECLARE
    TYPE t_wallet_rec IS RECORD (
        wallet_id  NUMBER,
        user_id    NUMBER,
        balance    NUMBER
    );
    TYPE t_wallet_tab IS TABLE OF t_wallet_rec INDEX BY PLS_INTEGER;
    v_wallets t_wallet_tab;

    v_method_id  NUMBER;
    v_order_id   NUMBER;
    v_tx_id      NUMBER;
    v_ref_code   VARCHAR2(50);
    v_type_id    NUMBER := 1; -- TOP_UP
    v_amounts    SYS.ODCINUMBERLIST := SYS.ODCINUMBERLIST(
        2000000, 5000000, 3000000, 1000000, 10000000,
        2500000, 4000000, 1500000, 8000000, 3500000,
        5000000, 2000000, 7000000, 1000000, 6000000,
        3000000, 9000000, 1500000, 2000000, 8000000,
        1000000, 6000000, 3000000, 5000000, 1500000,
        7000000, 4000000, 1000000, 4000000, 2500000,
        500000,  3000000, 8000000, 1500000, 500000,
        7000000, 9000000, 1000000, 6000000, 9000000,
        5000000,  800000, 9000000, 2000000, 5000000,
        6000000, 3000000, 8000000,10000000, 1500000
    );
    v_balance_before NUMBER;
    v_balance_after  NUMBER;
    v_amt  NUMBER;
    i      PLS_INTEGER := 1;
    v_key  VARCHAR2(100);
BEGIN
    -- 0. TẠM TẮT TRIGGER KIỂM TRA NGÀY GIAO DỊCH
    EXECUTE IMMEDIATE 'ALTER TRIGGER TRG_CHECK_TRANSACTION_DATE DISABLE';

    -- Lấy toàn bộ danh sách wallets đang có trong hệ thống theo thứ tự user_id
    FOR r IN (SELECT w.wallet_id, w.user_id, w.balance FROM wallets w ORDER BY w.user_id) LOOP
        v_wallets(i).wallet_id := r.wallet_id;
        v_wallets(i).user_id   := r.user_id;
        v_wallets(i).balance   := r.balance;
        i := i + 1;
    END LOOP;

    -- Kiểm tra xem có lấy đủ data không
    IF v_wallets.COUNT < 50 THEN
        DBMS_OUTPUT.PUT_LINE('Cảnh báo: Số lượng ví tìm thấy nhỏ hơn 50!');
    END IF;

    -- Chạy vòng lặp duyệt qua các ví đã lấy được
    FOR idx IN 1..LEAST(50, v_wallets.COUNT) LOOP
        v_amt := v_amounts(idx);
        v_balance_before := v_wallets(idx).balance - v_amt;
        IF v_balance_before < 0 THEN v_balance_before := 0; END IF;
        v_balance_after := v_balance_before + v_amt;

        -- Lấy method_id default của user
        BEGIN
            SELECT method_id INTO v_method_id
            FROM payment_methods
            WHERE user_id = v_wallets(idx).user_id AND is_default = 1
              AND ROWNUM = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_method_id := NULL; -- Tránh lỗi nếu user không có method mặc định
        END;

        v_key := 'TOPUP-IDEM-' || LPAD(idx, 4, '0');

        -- Tạo fund_order
        INSERT INTO fund_orders (
            wallet_id, method_id, order_type, amount,
            status, idempotency_key, gateway_ref, created_at
        ) VALUES (
            v_wallets(idx).wallet_id, v_method_id, 'TOP_UP', v_amt,
            'SUCCESS', v_key, 'GW-TOPUP-' || LPAD(idx,6,'0'),
            SYSTIMESTAMP - INTERVAL '30' DAY + NUMTODSINTERVAL(idx * 14400, 'SECOND')
        ) RETURNING order_id INTO v_order_id;

        v_ref_code := 'TOPUP-' || TO_CHAR(SYSDATE - 30, 'YYYYMMDD') || '-' || LPAD(idx, 6, '0');

        -- Tạo transaction
        INSERT INTO transactions (
            type_id, sender_wallet_id, receiver_wallet_id,
            amount, fee_amount, status, reference_code,
            step, description, created_at
        ) VALUES (
            v_type_id, NULL, v_wallets(idx).wallet_id,
            v_amt, 0, 'COMPLETED', v_ref_code,
            8, 'Nạp tiền vào ví | TOP_UP_ORDER_ID=' || v_order_id,
            SYSTIMESTAMP - INTERVAL '30' DAY + NUMTODSINTERVAL(idx * 14400, 'SECOND')
        ) RETURNING transaction_id INTO v_tx_id;

        -- Ghi audit log
        INSERT INTO audit_logs (
            transaction_id, wallet_id, action_type,
            balance_before, balance_after, delta
        ) VALUES (
            v_tx_id, v_wallets(idx).wallet_id, 'CREDIT',
            v_balance_before, v_balance_after, v_amt
        );
    END LOOP;

    -- BẬT LẠI TRIGGER SAU KHI INSERT XONG
    EXECUTE IMMEDIATE 'ALTER TRIGGER TRG_CHECK_TRANSACTION_DATE ENABLE';
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Đã giả lập thành công ' || LEAST(50, v_wallets.COUNT) || ' giao dịch nạp tiền lịch sử!');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        -- LUÔN BẬT LẠI TRIGGER DÙ CÓ LỖI HAY KHÔNG
        EXECUTE IMMEDIATE 'ALTER TRIGGER TRG_CHECK_TRANSACTION_DATE ENABLE';
        DBMS_OUTPUT.PUT_LINE('Tiến trình thất bại: ' || SQLERRM);
END;
/
-- -------------------------------------------------------
-- FUND_ORDERS TOP_UP thêm – batch 2 (50 lệnh nữa, phân bổ ngẫu nhiên)
-- Chọn 1 nạp thêm cho 1 số users có giao dịch nhiều
-- -------------------------------------------------------
DECLARE
    -- (wallet_id, amount) cho 50 lệnh top-up thêm
    TYPE t_pair IS RECORD (wid NUMBER, amt NUMBER);
    TYPE t_pairs IS TABLE OF t_pair INDEX BY PLS_INTEGER;
    v_pairs t_pairs;
    v_uid   NUMBER;
    v_method_id NUMBER;
    v_order_id  NUMBER;
    v_tx_id     NUMBER;
    v_ref       VARCHAR2(50);
    v_key       VARCHAR2(100);
    v_bal_bef   NUMBER;
    v_bal_aft   NUMBER;
    
    PROCEDURE add_pair(i IN PLS_INTEGER, w IN NUMBER, a IN NUMBER) IS
    BEGIN
        v_pairs(i).wid := w;
        v_pairs(i).amt := a;
    END;
BEGIN
    -- 0. TẠM TẮT TRIGGER KIỂM TRA NGÀY GIAO DỊCH
    EXECUTE IMMEDIATE 'ALTER TRIGGER TRG_CHECK_TRANSACTION_DATE DISABLE';

    -- wallet_id 1..50 (cần khớp với thứ tự tạo trong Part 2)
    -- Lấy wallet_id thực từ DB
    DECLARE
        wids SYS.ODCINUMBERLIST;
        amts SYS.ODCINUMBERLIST := SYS.ODCINUMBERLIST(
            3000000, 5000000, 2000000, 1000000, 7000000,
            2500000, 4000000, 1500000, 6000000, 3000000,
            4000000, 2000000, 5000000, 1000000, 8000000,
            3000000, 6000000, 1500000, 2000000, 4000000,
            1000000, 5000000, 2000000, 3000000, 1500000,
            6000000, 3000000, 1000000, 4000000, 2000000,
            500000,  2000000, 7000000, 1500000, 500000,
            5000000, 8000000, 1000000, 4000000, 7000000,
            3000000,  600000, 8000000, 1500000, 4000000,
            5000000, 2000000, 6000000, 8000000, 1000000
        );
        v_method_id2 NUMBER;
        v_order_id2  NUMBER;
        v_tx_id2     NUMBER;
        v_ref2       VARCHAR2(50);
        v_key2       VARCHAR2(100);
        v_bal_bef2   NUMBER;
        v_bal_aft2   NUMBER;
        v_uid2       NUMBER;
        v_balance2   NUMBER;
    BEGIN
        SELECT CAST(COLLECT(wallet_id ORDER BY user_id) AS SYS.ODCINUMBERLIST)
        INTO wids
        FROM wallets;

        FOR i IN 1..LEAST(50, wids.COUNT) LOOP
            -- Lấy user_id và balance từ wallet
            SELECT user_id, balance INTO v_uid2, v_balance2
            FROM wallets WHERE wallet_id = wids(i);

            v_bal_bef2 := v_balance2;
            v_bal_aft2 := v_balance2 + amts(i);

            -- Lấy method_id default an toàn
            BEGIN
                SELECT method_id INTO v_method_id2
                FROM payment_methods
                WHERE user_id = v_uid2 AND is_default = 1 AND ROWNUM = 1;
            EXCEPTION 
                WHEN NO_DATA_FOUND THEN v_method_id2 := NULL;
            END;

            v_key2 := 'TOPUP2-IDEM-' || LPAD(i, 4, '0');
            v_ref2 := 'TOPUP2-' || TO_CHAR(SYSDATE - 15, 'YYYYMMDD') || '-' || LPAD(i, 6, '0');

            INSERT INTO fund_orders (
                wallet_id, method_id, order_type, amount,
                status, idempotency_key, gateway_ref, created_at
            ) VALUES (
                wids(i), v_method_id2, 'TOP_UP', amts(i),
                'SUCCESS', v_key2, 'GW-TOPUP2-' || LPAD(i,6,'0'),
                SYSTIMESTAMP - INTERVAL '15' DAY + NUMTODSINTERVAL(i * 7200, 'SECOND')
            ) RETURNING order_id INTO v_order_id2;

            INSERT INTO transactions (
                type_id, sender_wallet_id, receiver_wallet_id,
                amount, fee_amount, status, reference_code,
                step, description, created_at
            ) VALUES (
                1, NULL, wids(i),
                amts(i), 0, 'COMPLETED', v_ref2,
                10, 'Nạp tiền vào ví lần 2 | TOP_UP_ORDER_ID=' || v_order_id2,
                SYSTIMESTAMP - INTERVAL '15' DAY + NUMTODSINTERVAL(i * 7200, 'SECOND')
            ) RETURNING transaction_id INTO v_tx_id2;

            INSERT INTO audit_logs (
                transaction_id, wallet_id, action_type,
                balance_before, balance_after, delta
            ) VALUES (
                v_tx_id2, wids(i), 'CREDIT',
                v_bal_bef2, v_bal_aft2, amts(i)
            );
        END LOOP;
    END;

    -- BẬT LẠI TRIGGER BẢO VỆ
    EXECUTE IMMEDIATE 'ALTER TRIGGER TRG_CHECK_TRANSACTION_DATE ENABLE';
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Đã giả lập thành công 50 lệnh Top-up lần 2!');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        -- LUÔN BẬT LẠI TRIGGER DÙ CÓ LỖI HAY KHÔNG
        EXECUTE IMMEDIATE 'ALTER TRIGGER TRG_CHECK_TRANSACTION_DATE ENABLE';
        RAISE;
END;
/