-- ============================================================
-- SEED PART 6: BỔ SUNG GIAO DỊCH ĐẠT ~1500 TỔNG
-- + Giao dịch FAILED và PENDING để đa dạng dữ liệu
-- Chạy SAU Part 5.
-- ============================================================

-- ============================================================
-- 6A: TRANSFER bổ sung batch 2 (~300 giao dịch)
-- Phân bổ thời gian trong 7 ngày gần đây
-- Mix: có/không voucher
-- ============================================================
DECLARE
    TYPE t_winfo IS RECORD (
        wallet_id  NUMBER,
        user_id    NUMBER,
        pin_code   VARCHAR2(6)
    );
    TYPE t_wtab IS TABLE OF t_winfo INDEX BY PLS_INTEGER;
    v_wallets t_wtab;
    v_cnt     PLS_INTEGER := 0;

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

    v_tx_id      NUMBER;
    v_ref        VARCHAR2(50);
    v_amount     NUMBER;
    v_fee        NUMBER;
    v_disc       NUMBER;
    v_net_fee    NUMBER;
    v_voucher_id NUMBER;
    v_limit_id   NUMBER;
    v_created_ts TIMESTAMP;
    v_sidx       PLS_INTEGER;
    v_ridx       PLS_INTEGER;

    FUNCTION calc_fee(p_amount IN NUMBER) RETURN NUMBER IS
        v_f NUMBER;
    BEGIN
        v_f := p_amount * 0.005;
        IF v_f < 2000 THEN v_f := 2000; END IF;
        IF v_f > 50000 THEN v_f := 50000; END IF;
        RETURN ROUND(v_f, 4);
    END;
    FUNCTION calc_disc(p_dtype IN VARCHAR2, p_dval IN NUMBER,
        p_mdisc IN NUMBER, p_fee IN NUMBER, p_amt IN NUMBER) RETURN NUMBER IS
        v_d NUMBER;
    BEGIN
        IF p_dtype = 'PERCENTAGE' THEN v_d := p_amt * p_dval;
        ELSE v_d := p_dval; END IF;
        IF p_mdisc IS NOT NULL AND v_d > p_mdisc THEN v_d := p_mdisc; END IF;
        IF v_d > p_fee THEN v_d := p_fee; END IF;
        RETURN ROUND(v_d, 4);
    END;
BEGIN
    -- TẠM TẮT TRIGGER BẢO VỆ THỜI GIAN
    EXECUTE IMMEDIATE 'ALTER TRIGGER TRG_CHECK_TRANSACTION_DATE DISABLE';

    FOR r IN (
        SELECT w.wallet_id, w.user_id, w.pin_code
        FROM wallets w JOIN users u ON w.user_id = u.user_id
        WHERE w.wallet_status = 'ACTIVE' AND u.is_active = 1
          AND u.kyc_status = 'VERIFIED'
        ORDER BY w.wallet_id
    ) LOOP
        v_cnt := v_cnt + 1;
        v_wallets(v_cnt).wallet_id := r.wallet_id;
        v_wallets(v_cnt).user_id   := r.user_id;
        v_wallets(v_cnt).pin_code  := r.pin_code;
    END LOOP;

    FOR r IN (
        SELECT voucher_id, discount_type, discount_value,
               NVL(min_order_value, 0) AS min_order_value,
               max_discount, amount_vouchers
        FROM vouchers
        WHERE is_active = 1 AND amount_vouchers > 5 AND valid_until > SYSTIMESTAMP
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

    SELECT limit_id INTO v_limit_id
    FROM transaction_limits WHERE kyc_level = 'VERIFIED' AND ROWNUM = 1;

    FOR i IN 1..300 LOOP
        v_sidx := MOD(i + 5, v_cnt) + 1;
        v_ridx := MOD(i + 13, v_cnt) + 1;
        IF v_sidx = v_ridx THEN v_ridx := MOD(v_ridx, v_cnt) + 1; END IF;

        CASE MOD(i, 12)
            WHEN 0  THEN v_amount := 150000;
            WHEN 1  THEN v_amount := 350000;
            WHEN 2  THEN v_amount := 600000;
            WHEN 3  THEN v_amount := 900000;
            WHEN 4  THEN v_amount := 1200000;
            WHEN 5  THEN v_amount := 1800000;
            WHEN 6  THEN v_amount := 2200000;
            WHEN 7  THEN v_amount := 3200000;
            WHEN 8  THEN v_amount := 4500000;
            WHEN 9  THEN v_amount := 6000000;
            WHEN 10 THEN v_amount := 7500000;
            ELSE         v_amount := 450000;
        END CASE;

        v_fee := calc_fee(v_amount);

        v_voucher_id := NULL;
        v_disc := 0;
        IF MOD(i, 4) = 1 AND v_vcnt > 0 THEN
            DECLARE
                v_vidx PLS_INTEGER := MOD(i * 3, v_vcnt) + 1;
                v_tries PLS_INTEGER := 0;
            BEGIN
                WHILE v_tries < v_vcnt LOOP
                    IF v_vouchers(v_vidx).amount_left > 0
                       AND v_amount >= v_vouchers(v_vidx).min_order THEN
                        v_voucher_id := v_vouchers(v_vidx).voucher_id;
                        v_disc := calc_disc(v_vouchers(v_vidx).discount_type,
                            v_vouchers(v_vidx).disc_val, v_vouchers(v_vidx).max_disc,
                            v_fee, v_amount);
                        v_vouchers(v_vidx).amount_left := v_vouchers(v_vidx).amount_left - 1;
                        EXIT;
                    END IF;
                    v_vidx := MOD(v_vidx, v_vcnt) + 1;
                    v_tries := v_tries + 1;
                END LOOP;
            END;
        END IF;

        v_net_fee := v_fee - v_disc;
        v_created_ts := SYSTIMESTAMP - NUMTODSINTERVAL((300 - i) * 1800, 'SECOND');
        v_ref := 'TXN2-' || TO_CHAR(TRUNC(v_created_ts), 'YYYYMMDD') || '-T' || LPAD(i, 6, '0');

        INSERT INTO transactions (
            type_id, sender_wallet_id, receiver_wallet_id,
            limit_id, voucher_id,
            amount, fee_amount, status, reference_code,
            step, description, created_at
        ) VALUES (
            3, v_wallets(v_sidx).wallet_id, v_wallets(v_ridx).wallet_id,
            v_limit_id, v_voucher_id,
            v_amount, v_net_fee, 'COMPLETED', v_ref,
            MOD(i, 24), 'Chuyển tiền bổ sung #' || i, v_created_ts
        ) RETURNING transaction_id INTO v_tx_id;

        INSERT INTO audit_logs (transaction_id, wallet_id, action_type, balance_before, balance_after, delta)
        VALUES (v_tx_id, v_wallets(v_sidx).wallet_id, 'DEBIT',
                v_amount * 4, v_amount * 4 - (v_amount + v_net_fee), v_amount + v_net_fee);

        INSERT INTO audit_logs (transaction_id, wallet_id, action_type, balance_before, balance_after, delta)
        VALUES (v_tx_id, v_wallets(v_ridx).wallet_id, 'CREDIT',
                v_amount * 3, v_amount * 3 + v_amount, v_amount);
    END LOOP;

    FOR j IN 1..v_vcnt LOOP
        UPDATE vouchers SET amount_vouchers = v_vouchers(j).amount_left
        WHERE voucher_id = v_vouchers(j).voucher_id;
    END LOOP;

    -- BẬT LẠI TRIGGER BẢO VỆ THỜI GIAN
    EXECUTE IMMEDIATE 'ALTER TRIGGER TRG_CHECK_TRANSACTION_DATE ENABLE';
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('6A: Hoàn thành 300 giao dịch TRANSFER bổ sung.');
EXCEPTION
    WHEN OTHERS THEN 
        ROLLBACK; 
        EXECUTE IMMEDIATE 'ALTER TRIGGER TRG_CHECK_TRANSACTION_DATE ENABLE';
        RAISE;
END;
/

-- ============================================================
-- 6B: GIAO DỊCH FAILED (~50 TRANSFER FAILED)
-- Giao dịch FAILED: không cần audit_log (chưa thực thi)
-- ============================================================
DECLARE
    v_cnt      PLS_INTEGER := 0;
    v_wallets SYS.ODCINUMBERLIST;
    v_wid1     NUMBER;
    v_wid2     NUMBER;
    v_amount   NUMBER;
    v_ref      VARCHAR2(50);
    v_limit_id NUMBER;
    v_created_ts TIMESTAMP;
BEGIN
    -- TẠM TẮT TRIGGER BẢO VỆ THỜI GIAN
    EXECUTE IMMEDIATE 'ALTER TRIGGER TRG_CHECK_TRANSACTION_DATE DISABLE';

    -- SỬA LỖI: Thêm w.user_id vào mệnh đề ORDER BY để tường minh
    SELECT CAST(COLLECT(wallet_id ORDER BY w.user_id) AS SYS.ODCINUMBERLIST)
    INTO v_wallets
    FROM wallets w JOIN users u ON w.user_id = u.user_id
    WHERE u.kyc_status = 'VERIFIED' AND w.wallet_status = 'ACTIVE';

    v_cnt := v_wallets.COUNT;

    SELECT limit_id INTO v_limit_id
    FROM transaction_limits WHERE kyc_level = 'VERIFIED' AND ROWNUM = 1;

    FOR i IN 1..50 LOOP
        v_wid1 := v_wallets(MOD(i - 1, v_cnt) + 1);
        v_wid2 := v_wallets(MOD(i + 7, v_cnt) + 1);
        IF v_wid1 = v_wid2 THEN v_wid2 := v_wallets(MOD(i + 1, v_cnt) + 1); END IF;

        v_amount := (MOD(i, 5) + 1) * 200000;
        v_created_ts := SYSTIMESTAMP - NUMTODSINTERVAL(i * 2400, 'SECOND');
        v_ref := 'FAIL-' || TO_CHAR(TRUNC(v_created_ts), 'YYYYMMDD') || '-F' || LPAD(i, 6, '0');

        INSERT INTO transactions (
            type_id, sender_wallet_id, receiver_wallet_id,
            limit_id, amount, fee_amount, status, reference_code,
            step, description, created_at
        ) VALUES (
            3, v_wid1, v_wid2,
            v_limit_id, v_amount, 0, 'FAILED', v_ref,
            MOD(i, 24), 'Giao dịch thất bại (test) #' || i, v_created_ts
        );
    END LOOP;

    -- BẬT LẠI TRIGGER BẢO VỆ THỜI GIAN
    EXECUTE IMMEDIATE 'ALTER TRIGGER TRG_CHECK_TRANSACTION_DATE ENABLE';
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('6B: Hoàn thành 50 giao dịch TRANSFER FAILED.');
EXCEPTION
    WHEN OTHERS THEN 
        ROLLBACK; 
        EXECUTE IMMEDIATE 'ALTER TRIGGER TRG_CHECK_TRANSACTION_DATE ENABLE';
        RAISE;
END;
/
-- ============================================================
-- 6C: GIAO DỊCH PENDING (~30 TRANSFER PENDING)
-- ============================================================
DECLARE
    v_cnt      PLS_INTEGER := 0;
    v_wallets SYS.ODCINUMBERLIST;
    v_wid1     NUMBER;
    v_wid2     NUMBER;
    v_amount   NUMBER;
    v_ref      VARCHAR2(50);
    v_limit_id NUMBER;
    v_created_ts TIMESTAMP;
BEGIN
    -- TẠM TẮT TRIGGER BẢO VỆ THỜI GIAN
    EXECUTE IMMEDIATE 'ALTER TRIGGER TRG_CHECK_TRANSACTION_DATE DISABLE';

    SELECT CAST(COLLECT(wallet_id ORDER BY w.user_id) AS SYS.ODCINUMBERLIST)
    INTO v_wallets
    FROM wallets w JOIN users u ON w.user_id = u.user_id
    WHERE u.kyc_status = 'VERIFIED' AND w.wallet_status = 'ACTIVE';

    v_cnt := v_wallets.COUNT;

    SELECT limit_id INTO v_limit_id
    FROM transaction_limits WHERE kyc_level = 'VERIFIED' AND ROWNUM = 1;

    FOR i IN 1..30 LOOP
        v_wid1 := v_wallets(MOD(i + 3, v_cnt) + 1);
        v_wid2 := v_wallets(MOD(i + 11, v_cnt) + 1);
        IF v_wid1 = v_wid2 THEN v_wid2 := v_wallets(MOD(i + 2, v_cnt) + 1); END IF;

        v_amount := (MOD(i, 6) + 1) * 300000;
        v_created_ts := SYSTIMESTAMP - NUMTODSINTERVAL(i * 1800, 'SECOND');
        v_ref := 'PEND-' || TO_CHAR(TRUNC(v_created_ts), 'YYYYMMDD') || '-P' || LPAD(i, 6, '0');

        INSERT INTO transactions (
            type_id, sender_wallet_id, receiver_wallet_id,
            limit_id, amount, fee_amount, status, reference_code,
            step, description, created_at
        ) VALUES (
            3, v_wid1, v_wid2,
            v_limit_id, v_amount, 0, 'PENDING', v_ref,
            MOD(i, 24), 'Giao dịch đang xử lý #' || i, v_created_ts
        );
    END LOOP;

    -- BẬT LẠI TRIGGER BẢO VỆ THỜI GIAN
    EXECUTE IMMEDIATE 'ALTER TRIGGER TRG_CHECK_TRANSACTION_DATE ENABLE';
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('6C: Hoàn thành 30 giao dịch TRANSFER PENDING.');
EXCEPTION
    WHEN OTHERS THEN 
        ROLLBACK; 
        EXECUTE IMMEDIATE 'ALTER TRIGGER TRG_CHECK_TRANSACTION_DATE ENABLE';
        RAISE;
END;
/
-- ============================================================
-- 6D: WITHDRAW FAILED (~20 giao dịch)
-- Fund order FAILED tương ứng
-- ============================================================
DECLARE
    v_wid      NUMBER;
    v_method_id NUMBER;
    v_order_id NUMBER;
    v_ref      VARCHAR2(50);
    v_amount   NUMBER;
    v_created_ts TIMESTAMP;
    v_wallets  SYS.ODCINUMBERLIST;
    v_ucnt     PLS_INTEGER;
    v_limit_id NUMBER;
    v_user_id  NUMBER;
BEGIN
    -- TẠM TẮT TRIGGER BẢO VỆ THỜI GIAN
    EXECUTE IMMEDIATE 'ALTER TRIGGER TRG_CHECK_TRANSACTION_DATE DISABLE';

    SELECT CAST(COLLECT(wallet_id ORDER BY w.user_id) AS SYS.ODCINUMBERLIST)
    INTO v_wallets
    FROM wallets w JOIN users u ON w.user_id = u.user_id
    WHERE u.kyc_status = 'VERIFIED' AND w.wallet_status = 'ACTIVE';

    v_ucnt := v_wallets.COUNT;

    SELECT limit_id INTO v_limit_id
    FROM transaction_limits WHERE kyc_level = 'VERIFIED' AND ROWNUM = 1;

    FOR i IN 1..20 LOOP
        v_wid := v_wallets(MOD(i + 8, v_ucnt) + 1);
        v_amount := 500000 + MOD(i, 5) * 200000;
        v_created_ts := SYSTIMESTAMP - NUMTODSINTERVAL(i * 3600, 'SECOND');

        -- Lấy chính xác user_id sở hữu ví
        SELECT user_id INTO v_user_id FROM wallets WHERE wallet_id = v_wid;
        
        -- Lấy an toàn phương thức thanh toán mặc định
        BEGIN
            SELECT method_id INTO v_method_id FROM payment_methods
            WHERE user_id = v_user_id AND is_default = 1 AND ROWNUM = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN v_method_id := NULL;
        END;

        v_ref := 'WDFAIL-' || TO_CHAR(TRUNC(v_created_ts), 'YYYYMMDD') || '-' || LPAD(i, 6, '0');

        INSERT INTO fund_orders (
            wallet_id, method_id, order_type, amount,
            status, idempotency_key, gateway_ref, created_at
        ) VALUES (
            v_wid, v_method_id, 'WITHDRAW', v_amount,
            'FAILED', 'WDFAIL-IDEM-' || LPAD(i, 6, '0'),
            'GW-WDFAIL-' || LPAD(i, 6, '0'), v_created_ts
        ) RETURNING order_id INTO v_order_id;

        INSERT INTO transactions (
            type_id, sender_wallet_id, receiver_wallet_id,
            limit_id, amount, fee_amount, status, reference_code,
            step, description, created_at
        ) VALUES (
            2, v_wid, NULL,
            v_limit_id, v_amount, 5000, 'FAILED', v_ref,
            MOD(i, 24),
            'Rút tiền thất bại (ngân hàng từ chối) | WITHDRAW_ORDER_ID=' || v_order_id,
            v_created_ts
        );
    END LOOP;

    -- BẬT LẠI TRIGGER BẢO VỆ THỜI GIAN
    EXECUTE IMMEDIATE 'ALTER TRIGGER TRG_CHECK_TRANSACTION_DATE ENABLE';
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('6D: Hoàn thành 20 giao dịch WITHDRAW FAILED.');
EXCEPTION
    WHEN OTHERS THEN 
        ROLLBACK; 
        EXECUTE IMMEDIATE 'ALTER TRIGGER TRG_CHECK_TRANSACTION_DATE ENABLE';
        RAISE;
END;
/
