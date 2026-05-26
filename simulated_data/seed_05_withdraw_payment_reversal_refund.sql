-- ============================================================
-- SEED PART 5: WITHDRAW + PAYMENT + REVERSAL + REFUND
-- Chạy SAU Part 4.
-- ============================================================

-- ============================================================
-- 5A: WITHDRAW TRANSACTIONS (~200 giao dịch)
-- Fee WITHDRAW: 1%, min 5000, max 100000
-- Chỉ có sender_wallet_id, KHÔNG có receiver_wallet_id
-- Kéo theo fund_order WITHDRAW
-- ============================================================
DECLARE
    TYPE t_winfo IS RECORD (
        wallet_id   NUMBER,
        user_id     NUMBER,
        pin_code    VARCHAR2(6)
    );
    TYPE t_wtab IS TABLE OF t_winfo INDEX BY PLS_INTEGER;
    v_wallets  t_wtab;
    v_cnt      PLS_INTEGER := 0;

    v_method_id  NUMBER;
    v_order_id   NUMBER;
    v_tx_id      NUMBER;
    v_ref        VARCHAR2(50);
    v_amount     NUMBER;
    v_fee        NUMBER;
    v_limit_id   NUMBER;
    v_created_ts TIMESTAMP;
    v_type_id    CONSTANT NUMBER := 2; -- WITHDRAW

    FUNCTION calc_fee_wd(p_amount IN NUMBER) RETURN NUMBER IS
        v_f NUMBER;
    BEGIN
        v_f := p_amount * 0.01;
        IF v_f < 5000  THEN v_f := 5000;  END IF;
        IF v_f > 100000 THEN v_f := 100000; END IF;
        RETURN ROUND(v_f, 4);
    END;

BEGIN
    -- 0. TẮT TRIGGER BẢO VỆ THỜI GIAN
    EXECUTE IMMEDIATE 'ALTER TRIGGER TRG_CHECK_TRANSACTION_DATE DISABLE';

    FOR r IN (
        SELECT w.wallet_id, w.user_id, w.pin_code
        FROM wallets w JOIN users u ON w.user_id = u.user_id
        WHERE w.wallet_status = 'ACTIVE'
          AND u.is_active = 1 AND u.kyc_status = 'VERIFIED'
        ORDER BY w.wallet_id
    ) LOOP
        v_cnt := v_cnt + 1;
        v_wallets(v_cnt).wallet_id := r.wallet_id;
        v_wallets(v_cnt).user_id   := r.user_id;
        v_wallets(v_cnt).pin_code  := r.pin_code;
    END LOOP;

    SELECT limit_id INTO v_limit_id
    FROM transaction_limits WHERE kyc_level = 'VERIFIED' AND ROWNUM = 1;

    FOR i IN 1..200 LOOP
        DECLARE
            v_idx PLS_INTEGER := MOD(i - 1, v_cnt) + 1;
        BEGIN
            CASE MOD(i, 10)
                WHEN 0 THEN v_amount := 200000;
                WHEN 1 THEN v_amount := 500000;
                WHEN 2 THEN v_amount := 800000;
                WHEN 3 THEN v_amount := 1000000;
                WHEN 4 THEN v_amount := 1200000;
                WHEN 5 THEN v_amount := 1500000;
                WHEN 6 THEN v_amount := 2000000;
                WHEN 7 THEN v_amount := 2500000;
                WHEN 8 THEN v_amount := 3000000;
                ELSE        v_amount := 700000;
            END CASE;

            v_fee := calc_fee_wd(v_amount);
            v_created_ts := SYSTIMESTAMP - NUMTODSINTERVAL((200 - i) * 5400, 'SECOND');

            BEGIN
                SELECT method_id INTO v_method_id
                FROM payment_methods
                WHERE user_id = v_wallets(v_idx).user_id
                  AND is_default = 1 AND ROWNUM = 1;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN v_method_id := NULL;
            END;

            v_ref := 'WDR-' || TO_CHAR(TRUNC(v_created_ts), 'YYYYMMDD') || '-W' || LPAD(i, 6, '0');

            INSERT INTO fund_orders (
                wallet_id, method_id, order_type, amount,
                status, idempotency_key, gateway_ref, created_at
            ) VALUES (
                v_wallets(v_idx).wallet_id, v_method_id, 'WITHDRAW', v_amount,
                'SUCCESS', 'WD-IDEM-' || LPAD(i, 6, '0'),
                'GW-WDR-' || LPAD(i, 6, '0'),
                v_created_ts
            ) RETURNING order_id INTO v_order_id;

            INSERT INTO transactions (
                type_id, sender_wallet_id, receiver_wallet_id,
                limit_id, amount, fee_amount, status, reference_code,
                step, description, created_at
            ) VALUES (
                v_type_id, v_wallets(v_idx).wallet_id, NULL,
                v_limit_id, v_amount, v_fee, 'COMPLETED', v_ref,
                MOD(i, 24), 'Rút tiền | WITHDRAW_ORDER_ID=' || v_order_id,
                v_created_ts
            ) RETURNING transaction_id INTO v_tx_id;

            INSERT INTO audit_logs (
                transaction_id, wallet_id, action_type,
                balance_before, balance_after, delta
            ) VALUES (
                v_tx_id, v_wallets(v_idx).wallet_id, 'DEBIT',
                v_amount * 5, v_amount * 5 - (v_amount + v_fee), v_amount + v_fee
            );
        END;
    END LOOP;

    -- BẬT LẠI TRIGGER BẢO VỆ
    EXECUTE IMMEDIATE 'ALTER TRIGGER TRG_CHECK_TRANSACTION_DATE ENABLE';
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Đã sinh xong 200 giao dịch Rút tiền.');
EXCEPTION
    WHEN OTHERS THEN 
        ROLLBACK; 
        EXECUTE IMMEDIATE 'ALTER TRIGGER TRG_CHECK_TRANSACTION_DATE ENABLE';
        RAISE;
END;
/

-- ============================================================
-- 5B: PAYMENT TRANSACTIONS (~200 giao dịch)
-- type_id = 4, fee = 0
-- sender_wallet_id có, receiver_wallet_id có (merchant wallets)
-- Dùng wallet 46-50 làm merchant wallets (người nhận)
-- ============================================================
DECLARE
    TYPE t_winfo IS RECORD (wallet_id NUMBER, user_id NUMBER);
    TYPE t_wtab  IS TABLE OF t_winfo INDEX BY PLS_INTEGER;
    v_senders   t_wtab;
    v_s_cnt     PLS_INTEGER := 0;
    v_merchants t_wtab;
    v_m_cnt     PLS_INTEGER := 0;

    v_tx_id      NUMBER;
    v_ref        VARCHAR2(50);
    v_amount     NUMBER;
    v_limit_id   NUMBER;
    v_created_ts TIMESTAMP;
    v_type_id    CONSTANT NUMBER := 4; -- PAYMENT
    v_sidx       PLS_INTEGER;
    v_midx       PLS_INTEGER;
    v_swid       NUMBER;
    v_mwid       NUMBER;

    TYPE t_vinfo IS RECORD (
        voucher_id    NUMBER,
        discount_type VARCHAR2(20),
        disc_val      NUMBER,
        min_order     NUMBER,
        max_disc      NUMBER,
        amount_left   NUMBER
    );
    TYPE t_vtab IS TABLE OF t_vinfo INDEX BY PLS_INTEGER;
    v_vouchers t_vtab;
    v_vcnt     PLS_INTEGER := 0;

    v_voucher_id NUMBER;
    v_disc       NUMBER;
    v_net_fee    NUMBER;

    FUNCTION calc_disc(
        p_dtype IN VARCHAR2, p_dval IN NUMBER,
        p_mdisc IN NUMBER, p_fee IN NUMBER, p_amt IN NUMBER
    ) RETURN NUMBER IS
        v_d NUMBER;
    BEGIN
        IF p_dtype = 'PERCENTAGE' THEN v_d := p_amt * p_dval;
        ELSE v_d := p_dval; END IF;
        IF p_mdisc IS NOT NULL AND v_d > p_mdisc THEN v_d := p_mdisc; END IF;
        IF v_d > p_fee THEN v_d := p_fee; END IF;
        RETURN ROUND(v_d, 4);
    END;

BEGIN
    -- 0. TẮT TRIGGER BẢO VỆ THỜI GIAN
    EXECUTE IMMEDIATE 'ALTER TRIGGER TRG_CHECK_TRANSACTION_DATE DISABLE';

    -- Senders: Tịnh tiến từ nhóm user_id 1-45 sang dải mới (3161 - 3205)
    FOR r IN (
        SELECT w.wallet_id, w.user_id FROM wallets w
        JOIN users u ON w.user_id = u.user_id
        WHERE u.kyc_status = 'VERIFIED' AND w.wallet_status = 'ACTIVE'
          AND u.user_id BETWEEN 3161 AND 3205
        ORDER BY w.wallet_id
    ) LOOP
        v_s_cnt := v_s_cnt + 1;
        v_senders(v_s_cnt).wallet_id := r.wallet_id;
        v_senders(v_s_cnt).user_id   := r.user_id;
    END LOOP;

    -- Merchants: Tịnh tiến từ nhóm user_id 46-50 sang dải mới (3206 - 3210)
    FOR r IN (
        SELECT w.wallet_id, w.user_id FROM wallets w
        WHERE w.user_id BETWEEN 3206 AND 3210
        ORDER BY w.wallet_id
    ) LOOP
        v_m_cnt := v_m_cnt + 1;
        v_merchants(v_m_cnt).wallet_id := r.wallet_id;
        v_merchants(v_m_cnt).user_id   := r.user_id;
    END LOOP;

    -- Kiểm tra phòng chống lỗi chia cho 0 nếu không tìm thấy dữ liệu user phù hợp
    IF v_s_cnt = 0 OR v_m_cnt = 0 THEN
        DBMS_OUTPUT.PUT_LINE('LỖI: Không tìm thấy Senders hoặc Merchants trong dải ID 3161-3210.');
        EXECUTE IMMEDIATE 'ALTER TRIGGER TRG_CHECK_TRANSACTION_DATE ENABLE';
        RETURN;
    END IF;

    SELECT limit_id INTO v_limit_id
    FROM transaction_limits WHERE kyc_level = 'VERIFIED' AND ROWNUM = 1;

    FOR r IN (
        SELECT voucher_id, discount_type, discount_value,
               NVL(min_order_value, 0) AS min_order_value,
               max_discount, amount_vouchers
        FROM vouchers
        WHERE is_active = 1 AND amount_vouchers > 5
          AND valid_until > SYSTIMESTAMP
        ORDER BY voucher_id
    ) LOOP
        v_vcnt := v_vcnt + 1;
        v_vouchers(v_vcnt).voucher_id    := r.voucher_id;
        v_vouchers(v_vcnt).discount_type := r.discount_type;
        v_vouchers(v_vcnt).disc_val      := r.discount_value;
        v_vouchers(v_vcnt).min_order     := r.min_order_value;
        v_vouchers(v_vcnt).max_disc      := r.max_discount;
        v_vouchers(v_vcnt).amount_left   := r.amount_vouchers;
    END LOOP;

    FOR i IN 1..200 LOOP
        v_sidx := MOD(i - 1, v_s_cnt) + 1;
        v_midx := MOD(i - 1, v_m_cnt) + 1;
        v_swid := v_senders(v_sidx).wallet_id;
        v_mwid := v_merchants(v_midx).wallet_id;

        IF v_swid = v_mwid THEN
            v_midx := MOD(v_midx, v_m_cnt) + 1;
            v_mwid := v_merchants(v_midx).wallet_id;
        END IF;

        CASE MOD(i, 8)
            WHEN 0 THEN v_amount := 50000;
            WHEN 1 THEN v_amount := 100000;
            WHEN 2 THEN v_amount := 150000;
            WHEN 3 THEN v_amount := 200000;
            WHEN 4 THEN v_amount := 300000;
            WHEN 5 THEN v_amount := 500000;
            WHEN 6 THEN v_amount := 750000;
            ELSE         v_amount := 400000;
        END CASE;

        v_created_ts := SYSTIMESTAMP - NUMTODSINTERVAL((200 - i) * 4200, 'SECOND');

        v_voucher_id := NULL;
        v_disc       := 0;
        IF MOD(i, 4) = 0 AND v_vcnt > 0 THEN
            DECLARE
                v_vidx PLS_INTEGER := MOD(i, v_vcnt) + 1;
                v_tries PLS_INTEGER := 0;
            BEGIN
                WHILE v_tries < v_vcnt LOOP
                    IF v_vouchers(v_vidx).amount_left > 0
                       AND v_amount >= v_vouchers(v_vidx).min_order THEN
                        v_voucher_id := v_vouchers(v_vidx).voucher_id;
                        v_disc := calc_disc(
                            v_vouchers(v_vidx).discount_type,
                            v_vouchers(v_vidx).disc_val,
                            v_vouchers(v_vidx).max_disc,
                            0, v_amount
                        );
                        v_vouchers(v_vidx).amount_left := v_vouchers(v_vidx).amount_left - 1;
                        EXIT;
                    END IF;
                    v_vidx := MOD(v_vidx, v_vcnt) + 1;
                    v_tries := v_tries + 1;
                END LOOP;
            END;
        END IF;

        v_net_fee := 0;
        v_ref := 'PAY-' || TO_CHAR(TRUNC(v_created_ts), 'YYYYMMDD') || '-P' || LPAD(i, 6, '0');

        INSERT INTO transactions (
            type_id, sender_wallet_id, receiver_wallet_id,
            limit_id, voucher_id,
            amount, fee_amount, status, reference_code,
            step, description, created_at
        ) VALUES (
            v_type_id, v_swid, v_mwid,
            v_limit_id, v_voucher_id,
            v_amount, 0, 'COMPLETED', v_ref,
            MOD(i, 24), 'Thanh toán dịch vụ #' || i,
            v_created_ts
        ) RETURNING transaction_id INTO v_tx_id;

        INSERT INTO audit_logs (transaction_id, wallet_id, action_type, balance_before, balance_after, delta)
        VALUES (v_tx_id, v_swid, 'DEBIT', v_amount * 4, v_amount * 4 - v_amount, v_amount);

        INSERT INTO audit_logs (transaction_id, wallet_id, action_type, balance_before, balance_after, delta)
        VALUES (v_tx_id, v_mwid, 'CREDIT', v_amount * 2, v_amount * 2 + v_amount, v_amount);
    END LOOP;

    FOR j IN 1..v_vcnt LOOP
        UPDATE vouchers SET amount_vouchers = v_vouchers(j).amount_left
        WHERE voucher_id = v_vouchers(j).voucher_id;
    END LOOP;

    -- BẬT LẠI TRIGGER BẢO VỆ
    EXECUTE IMMEDIATE 'ALTER TRIGGER TRG_CHECK_TRANSACTION_DATE ENABLE';
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Đã sinh xong 200 giao dịch Thanh toán.');
EXCEPTION
    WHEN OTHERS THEN 
        ROLLBACK; 
        EXECUTE IMMEDIATE 'ALTER TRIGGER TRG_CHECK_TRANSACTION_DATE ENABLE';
        RAISE;
END;
/

-- ============================================================
-- 5C: REVERSAL TRANSACTIONS (~50 giao dịch)
-- Đảo ngược 50 giao dịch TRANSFER đã COMPLETED
-- type_id = 5, original_transaction_id phải trỏ về TRANSFER COMPLETED
-- ============================================================
DECLARE
    TYPE t_orig IS RECORD (
        tx_id      NUMBER,
        sender_wid NUMBER,
        recv_wid   NUMBER,
        amount     NUMBER
    );
    TYPE t_orig_tab IS TABLE OF t_orig INDEX BY PLS_INTEGER;
    v_origs t_orig_tab;
    v_cnt   PLS_INTEGER := 0;

    v_tx_id      NUMBER;
    v_ref        VARCHAR2(50);
    v_created_ts TIMESTAMP;
    v_type_id    CONSTANT NUMBER := 5; -- REVERSAL

BEGIN
    -- 0. TẠM TẮT TRIGGER BẢO VỆ THỜI GIAN
    EXECUTE IMMEDIATE 'ALTER TRIGGER TRG_CHECK_TRANSACTION_DATE DISABLE';

    FOR r IN (
        SELECT t.transaction_id, t.sender_wallet_id, t.receiver_wallet_id, t.amount
        FROM transactions t
        WHERE t.type_id = 3 AND t.status = 'COMPLETED'
          AND NOT EXISTS (
              SELECT 1 FROM transactions r2
              WHERE r2.original_transaction_id = t.transaction_id
                AND r2.type_id = 5
          )
        ORDER BY t.transaction_id
        FETCH FIRST 50 ROWS ONLY
    ) LOOP
        v_cnt := v_cnt + 1;
        v_origs(v_cnt).tx_id      := r.transaction_id;
        v_origs(v_cnt).sender_wid := r.sender_wallet_id;
        v_origs(v_cnt).recv_wid   := r.receiver_wallet_id;
        v_origs(v_cnt).amount     := r.amount;
    END LOOP;

    FOR i IN 1..v_cnt LOOP
        v_created_ts := SYSTIMESTAMP - NUMTODSINTERVAL((v_cnt - i) * 3600, 'SECOND');
        v_ref := 'REV-' || TO_CHAR(TRUNC(v_created_ts), 'YYYYMMDD') || '-R' || LPAD(i, 6, '0');

        INSERT INTO transactions (
            type_id,
            sender_wallet_id,   
            receiver_wallet_id, 
            original_transaction_id,
            amount, fee_amount, status, reference_code,
            step, description, created_at
        ) VALUES (
            v_type_id,
            v_origs(i).recv_wid,
            v_origs(i).sender_wid,
            v_origs(i).tx_id,
            v_origs(i).amount, 0, 'COMPLETED', v_ref,
            MOD(i, 24),
            'Đảo ngược giao dịch #' || v_origs(i).tx_id,
            v_created_ts
        ) RETURNING transaction_id INTO v_tx_id;

        INSERT INTO audit_logs (transaction_id, wallet_id, action_type, balance_before, balance_after, delta)
        VALUES (v_tx_id, v_origs(i).recv_wid, 'DEBIT',
                v_origs(i).amount * 3, v_origs(i).amount * 3 - v_origs(i).amount, v_origs(i).amount);

        INSERT INTO audit_logs (transaction_id, wallet_id, action_type, balance_before, balance_after, delta)
        VALUES (v_tx_id, v_origs(i).sender_wid, 'CREDIT',
                v_origs(i).amount * 2, v_origs(i).amount * 2 + v_origs(i).amount, v_origs(i).amount);

        UPDATE transactions SET status = 'REVERSED' WHERE transaction_id = v_origs(i).tx_id;
    END LOOP;

    -- BẬT LẠI TRIGGER BẢO VỆ
    EXECUTE IMMEDIATE 'ALTER TRIGGER TRG_CHECK_TRANSACTION_DATE ENABLE';
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Đã sinh xong các giao dịch Đảo ngược.');
EXCEPTION
    WHEN OTHERS THEN 
        ROLLBACK; 
        EXECUTE IMMEDIATE 'ALTER TRIGGER TRG_CHECK_TRANSACTION_DATE ENABLE';
        RAISE;
END;
/

-- ============================================================
-- 5D: REFUND TRANSACTIONS (~50 giao dịch)
-- Hoàn tiền cho 50 giao dịch PAYMENT COMPLETED
-- type_id = 6
-- ============================================================
DECLARE
    TYPE t_orig IS RECORD (
        tx_id      NUMBER,
        sender_wid NUMBER,
        recv_wid   NUMBER,
        amount     NUMBER
    );
    TYPE t_orig_tab IS TABLE OF t_orig INDEX BY PLS_INTEGER;
    v_origs t_orig_tab;
    v_cnt   PLS_INTEGER := 0;

    v_tx_id      NUMBER;
    v_ref        VARCHAR2(50);
    v_created_ts TIMESTAMP;
    v_type_id    CONSTANT NUMBER := 6; -- REFUND

BEGIN
    -- 0. TẠM TẮT TRIGGER BẢO VỆ THỜI GIAN
    EXECUTE IMMEDIATE 'ALTER TRIGGER TRG_CHECK_TRANSACTION_DATE DISABLE';

    FOR r IN (
        SELECT t.transaction_id, t.sender_wallet_id, t.receiver_wallet_id, t.amount
        FROM transactions t
        WHERE t.type_id = 4 AND t.status = 'COMPLETED'
          AND NOT EXISTS (
              SELECT 1 FROM transactions r2
              WHERE r2.original_transaction_id = t.transaction_id
                AND r2.type_id = 6
          )
        ORDER BY t.transaction_id
        FETCH FIRST 50 ROWS ONLY
    ) LOOP
        v_cnt := v_cnt + 1;
        v_origs(v_cnt).tx_id      := r.transaction_id;
        v_origs(v_cnt).sender_wid := r.sender_wallet_id;
        v_origs(v_cnt).recv_wid   := r.receiver_wallet_id;
        v_origs(v_cnt).amount     := r.amount;
    END LOOP;

    FOR i IN 1..v_cnt LOOP
        v_created_ts := SYSTIMESTAMP - NUMTODSINTERVAL((v_cnt - i) * 2700, 'SECOND');
        v_ref := 'RFD-' || TO_CHAR(TRUNC(v_created_ts), 'YYYYMMDD') || '-F' || LPAD(i, 6, '0');

        INSERT INTO transactions (
            type_id,
            sender_wallet_id,   
            receiver_wallet_id, 
            original_transaction_id,
            amount, fee_amount, status, reference_code,
            step, description, created_at
        ) VALUES (
            v_type_id,
            v_origs(i).recv_wid,
            v_origs(i).sender_wid,
            v_origs(i).tx_id,
            v_origs(i).amount, 0, 'COMPLETED', v_ref,
            MOD(i, 24),
            'Hoàn tiền giao dịch #' || v_origs(i).tx_id,
            v_created_ts
        ) RETURNING transaction_id INTO v_tx_id;

        INSERT INTO audit_logs (transaction_id, wallet_id, action_type, balance_before, balance_after, delta)
        VALUES (v_tx_id, v_origs(i).recv_wid, 'DEBIT',
                v_origs(i).amount * 2, v_origs(i).amount * 2 - v_origs(i).amount, v_origs(i).amount);

        INSERT INTO audit_logs (transaction_id, wallet_id, action_type, balance_before, balance_after, delta)
        VALUES (v_tx_id, v_origs(i).sender_wid, 'CREDIT',
                v_origs(i).amount * 3, v_origs(i).amount * 3 + v_origs(i).amount, v_origs(i).amount);

        UPDATE transactions SET status = 'REVERSED' WHERE transaction_id = v_origs(i).tx_id;
    END LOOP;

    -- BẬT LẠI TRIGGER BẢO VỆ
    EXECUTE IMMEDIATE 'ALTER TRIGGER TRG_CHECK_TRANSACTION_DATE ENABLE';
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Đã sinh xong các giao dịch Hoàn tiền.');
EXCEPTION
    WHEN OTHERS THEN 
        ROLLBACK; 
        EXECUTE IMMEDIATE 'ALTER TRIGGER TRG_CHECK_TRANSACTION_DATE ENABLE';
        RAISE;
END;
/