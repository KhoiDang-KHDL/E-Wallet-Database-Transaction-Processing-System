-- ============================================================
-- SEED PART 4: TRANSFER TRANSACTIONS
-- Chạy SAU Part 3.
-- ~600 giao dịch TRANSFER, mix có/không voucher
-- Giới hạn: VERIFIED ≤ 50tr/giao dịch; UNVERIFIED ≤ 2tr/giao dịch
-- Fee TRANSFER: 0.5%, min 2000, max 50000
-- ============================================================

-- Sử dụng PL/SQL để tự động lấy wallet_id thực, tính fee, giảm voucher count

DECLARE
    -- Lấy danh sách wallet (chỉ VERIFIED users để đơn giản cho batch lớn)
    TYPE t_winfo IS RECORD (
        wallet_id   NUMBER,
        user_id     NUMBER,
        kyc_status  VARCHAR2(20),
        pin_code    VARCHAR2(6)
    );
    TYPE t_wtab IS TABLE OF t_winfo INDEX BY PLS_INTEGER;
    v_wallets  t_wtab;
    v_cnt      PLS_INTEGER := 0;

    -- Voucher info
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

    v_limit_ver    NUMBER := 50000000;
    v_limit_unver  NUMBER := 2000000;

    v_sender_idx   PLS_INTEGER;
    v_recv_idx     PLS_INTEGER;
    v_sender_wid   NUMBER;
    v_recv_wid     NUMBER;
    v_amount       NUMBER;
    v_fee          NUMBER;
    v_disc         NUMBER;
    v_net_fee      NUMBER;
    v_total_deduct NUMBER;
    v_voucher_id   NUMBER;
    v_limit_id     NUMBER;
    v_tx_id        NUMBER;
    v_ref          VARCHAR2(50);
    v_type_id      CONSTANT NUMBER := 3; -- TRANSFER
    v_created_ts   TIMESTAMP;

    -- Mảng số tiền chuyển (tất cả ≤ 50tr để safe với VERIFIED)
    TYPE t_amts IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
    v_amts t_amts;

    -- Hàm tính fee transfer
    FUNCTION calc_fee(p_amount IN NUMBER) RETURN NUMBER IS
        v_f NUMBER;
    BEGIN
        v_f := p_amount * 0.005;
        IF v_f < 2000 THEN v_f := 2000; END IF;
        IF v_f > 50000 THEN v_f := 50000; END IF;
        RETURN ROUND(v_f, 4);
    END;

    -- Hàm tính discount
    FUNCTION calc_discount(
        p_disc_type IN VARCHAR2,
        p_disc_val  IN NUMBER,
        p_max_disc  IN NUMBER,
        p_fee       IN NUMBER,
        p_amount    IN NUMBER
    ) RETURN NUMBER IS
        v_d NUMBER;
    BEGIN
        IF p_disc_type = 'PERCENTAGE' THEN
            v_d := p_amount * p_disc_val;
        ELSE
            v_d := p_disc_val;
        END IF;
        IF p_max_disc IS NOT NULL AND v_d > p_max_disc THEN
            v_d := p_max_disc;
        END IF;
        IF v_d > p_fee THEN v_d := p_fee; END IF;
        RETURN ROUND(v_d, 4);
    END;

BEGIN
    -- 0. TẠM TẮT TRIGGER KIỂM TRA NGÀY GIAO DỊCH
    EXECUTE IMMEDIATE 'ALTER TRIGGER TRG_CHECK_TRANSACTION_DATE DISABLE';

    -- 1. Load wallets (chỉ ACTIVE wallets từ VERIFIED users)
    FOR r IN (
        SELECT w.wallet_id, w.user_id, u.kyc_status, w.pin_code
        FROM wallets w JOIN users u ON w.user_id = u.user_id
        WHERE w.wallet_status = 'ACTIVE'
          AND u.is_active = 1
          AND u.kyc_status = 'VERIFIED'
        ORDER BY w.wallet_id
    ) LOOP
        v_cnt := v_cnt + 1;
        v_wallets(v_cnt).wallet_id  := r.wallet_id;
        v_wallets(v_cnt).user_id    := r.user_id;
        v_wallets(v_cnt).kyc_status := r.kyc_status;
        v_wallets(v_cnt).pin_code   := r.pin_code;
    END LOOP;

    -- 2. Load vouchers có amount_vouchers > 10
    FOR r IN (
        SELECT voucher_id, discount_type, discount_value,
               NVL(min_order_value, 0) AS min_order_value,
               max_discount, amount_vouchers
        FROM vouchers
        WHERE is_active = 1 AND amount_vouchers > 10
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

    -- Lấy limit_id cho VERIFIED
    SELECT limit_id INTO v_limit_id
    FROM transaction_limits WHERE kyc_level = 'VERIFIED' AND ROWNUM = 1;

    -- 3. Tạo ~600 giao dịch TRANSFER
    -- Dùng vòng lặp 600 lần, phân bổ sender/receiver theo pattern
    FOR i IN 1..600 LOOP
        -- Chọn sender và receiver khác nhau
        v_sender_idx := MOD(i - 1, v_cnt) + 1;
        v_recv_idx   := MOD(i + 2, v_cnt) + 1;
        IF v_sender_idx = v_recv_idx THEN
            v_recv_idx := MOD(v_recv_idx, v_cnt) + 1;
        END IF;

        v_sender_wid := v_wallets(v_sender_idx).wallet_id;
        v_recv_wid   := v_wallets(v_recv_idx).wallet_id;

        -- Số tiền chuyển: từ 100k đến 5tr (an toàn trong giới hạn VERIFIED)
        -- Sử dụng pattern để đa dạng
        CASE MOD(i, 15)
            WHEN 0  THEN v_amount := 100000;
            WHEN 1  THEN v_amount := 200000;
            WHEN 2  THEN v_amount := 300000;
            WHEN 3  THEN v_amount := 500000;
            WHEN 4  THEN v_amount := 750000;
            WHEN 5  THEN v_amount := 1000000;
            WHEN 6  THEN v_amount := 1500000;
            WHEN 7  THEN v_amount := 2000000;
            WHEN 8  THEN v_amount := 2500000;
            WHEN 9  THEN v_amount := 3000000;
            WHEN 10 THEN v_amount := 3500000;
            WHEN 11 THEN v_amount := 4000000;
            WHEN 12 THEN v_amount := 4500000;
            WHEN 13 THEN v_amount := 5000000;
            ELSE         v_amount := 800000;
        END CASE;

        v_fee := calc_fee(v_amount);

        -- Quyết định dùng voucher không (1/3 giao dịch có voucher)
        v_voucher_id := NULL;
        v_disc       := 0;
        IF MOD(i, 3) = 0 AND v_vcnt > 0 THEN
            -- Chọn voucher phù hợp (min_order <= amount, còn lượt)
            DECLARE
                v_vidx PLS_INTEGER := MOD(i, v_vcnt) + 1;
                v_tries PLS_INTEGER := 0;
            BEGIN
                WHILE v_tries < v_vcnt LOOP
                    IF v_vouchers(v_vidx).amount_left > 0
                       AND v_amount >= v_vouchers(v_vidx).min_order THEN
                        v_voucher_id := v_vouchers(v_vidx).voucher_id;
                        v_disc := calc_discount(
                            v_vouchers(v_vidx).discount_type,
                            v_vouchers(v_vidx).disc_val,
                            v_vouchers(v_vidx).max_disc,
                            v_fee,
                            v_amount
                        );
                        v_vouchers(v_vidx).amount_left := v_vouchers(v_vidx).amount_left - 1;
                        EXIT;
                    END IF;
                    v_vidx := MOD(v_vidx, v_vcnt) + 1;
                    v_tries := v_tries + 1;
                END LOOP;
            END;
        END IF;

        v_net_fee      := v_fee - v_disc;
        v_total_deduct := v_amount + v_net_fee;

        -- Timestamp: phân bổ trong 25 ngày qua, trải đều
        v_created_ts := SYSTIMESTAMP - NUMTODSINTERVAL(25 * 86400 - i * 3600, 'SECOND');

        v_ref := 'TXN-' || TO_CHAR(TRUNC(SYSDATE) - 25 + TRUNC((i-1)/24), 'YYYYMMDD') || '-T' || LPAD(i, 6, '0');

        INSERT INTO transactions (
            type_id, sender_wallet_id, receiver_wallet_id,
            limit_id, voucher_id,
            amount, fee_amount, status, reference_code,
            step, description, created_at
        ) VALUES (
            v_type_id, v_sender_wid, v_recv_wid,
            v_limit_id, v_voucher_id,
            v_amount, v_net_fee, 'COMPLETED', v_ref,
            MOD(i, 24), 'Chuyển tiền | Giao dịch #' || i,
            v_created_ts
        ) RETURNING transaction_id INTO v_tx_id;

        -- Audit DEBIT sender
        INSERT INTO audit_logs (
            transaction_id, wallet_id, action_type,
            balance_before, balance_after, delta
        ) VALUES (
            v_tx_id, v_sender_wid, 'DEBIT',
            v_amount * 3, v_amount * 3 - v_total_deduct, v_total_deduct
        );

        -- Audit CREDIT receiver
        INSERT INTO audit_logs (
            transaction_id, wallet_id, action_type,
            balance_before, balance_after, delta
        ) VALUES (
            v_tx_id, v_recv_wid, 'CREDIT',
            v_amount * 2, v_amount * 2 + v_amount, v_amount
        );

    END LOOP;

    -- 4. Cập nhật amount_vouchers trong bảng vouchers
    FOR j IN 1..v_vcnt LOOP
        UPDATE vouchers
        SET amount_vouchers = v_vouchers(j).amount_left
        WHERE voucher_id = v_vouchers(j).voucher_id;
    END LOOP;

    -- BẬT LẠI TRIGGER BẢO VỆ
    EXECUTE IMMEDIATE 'ALTER TRIGGER TRG_CHECK_TRANSACTION_DATE ENABLE';

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Đã giả lập thành công 600 giao dịch chuyển tiền!');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        -- LUÔN BẬT LẠI TRIGGER DÙ CÓ LỖI HAY KHÔNG
        EXECUTE IMMEDIATE 'ALTER TRIGGER TRG_CHECK_TRANSACTION_DATE ENABLE';
        RAISE;
END;
/
