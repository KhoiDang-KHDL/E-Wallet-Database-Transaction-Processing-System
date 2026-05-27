-- Hàm tự động tạo mã reference_code duy nhất cho mỗi giao dịch dựa trên định dạng quy định (ví dụ: TXN + YYYYMMDD + Sequence) để đảm bảo không bị trùng lặp.
CREATE OR REPLACE FUNCTION fn_generate_ref_code 
RETURN VARCHAR2 
IS

    PRAGMA AUTONOMOUS_TRANSACTION;
    v_today    DATE;
    v_seq      NUMBER;
    v_ref_code VARCHAR2(50);
BEGIN
    v_today := TRUNC(SYSDATE);

    UPDATE transaction_ref_sequences
    SET current_value = current_value + 1,
        updated_at = SYSTIMESTAMP
    WHERE ref_date = v_today
    RETURNING current_value INTO v_seq;

    IF SQL%ROWCOUNT = 0 THEN
        v_seq := 1;
        INSERT INTO transaction_ref_sequences (ref_date, current_value)
        VALUES (v_today, v_seq);
    END IF;

    COMMIT;

    -- (VD: TXN20231027000001)
    v_ref_code := 'TXN' || TO_CHAR(SYSDATE, 'YYYYMMDD') || LPAD(v_seq, 6, '0');

    RETURN v_ref_code;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/
-- 2. Kiểm tra tính hợp lệ của mật khẩu khi người dùng thực hiện đăng nhập
CREATE OR REPLACE FUNCTION fn_get_hash_for_login (
    p_phone IN VARCHAR2
) 
RETURN VARCHAR2 
IS
    v_password_hash users.password_hash%TYPE;
    v_is_active     users.is_active%TYPE;
BEGIN

    SELECT password_hash, is_active
    INTO v_password_hash, v_is_active
    FROM users
    WHERE phone = p_phone;

    IF v_is_active = 0 THEN
        RAISE_APPLICATION_ERROR(-20100, 'Lá»—i: TÃ i khoáº£n Ä‘Ã£ bá»‹ khÃ³a hoáº·c vÃ´ hiá»‡u hÃ³a.');
    END IF;

    RETURN v_password_hash;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN)
        RETURN NULL;
    WHEN OTHERS THEN
        RAISE;
END;
/
--3. Truy xuáº¥t nhanh sá»‘ dÆ° kháº£ dá»¥ng hiá»‡n táº¡i vÃ  tráº¡ng thÃ¡i cá»§a má»™t vÃ­ cá»¥ thá»ƒ.
CREATE OR REPLACE FUNCTION fn_get_wallet_info (
    p_wallet_id IN NUMBER
)
RETURN VARCHAR2
AS
    v_balance wallets.balance%TYPE;
    v_status wallets.wallet_status%TYPE;
BEGIN
    SELECT balance, wallet_status
    INTO v_balance, v_status
    FROM wallets
    WHERE wallet_id = p_wallet_id;

    RETURN 'Balance: ' || v_balance ||
           ' | Status: ' || v_status;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'Wallet not found';
END;
/

--9. Kiểm tra xem ví (người gửi/người nhận) có đang ở trạng thái được phép giao dịch hay không (không bị khóa hoặc đóng).
CREATE OR REPLACE FUNCTION fn_is_wallet_active (
    p_wallet_id IN NUMBER
)
RETURN NUMBER
AS
    v_status wallets.wallet_status%TYPE;
BEGIN
    -- Láº¥y tráº¡ng thÃ¡i vÃ­
    SELECT wallet_status
    INTO v_status
    FROM wallets
    WHERE wallet_id = p_wallet_id;

    -- Kiá»ƒm tra tráº¡ng thÃ¡i
    IF v_status = 'ACTIVE' THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
END;
/
-- FUNCTION 4: Tính toán số tiền phí thực tế phải thu dựa trên loại giao dịch, số tiền và biểu phí hiện hành.

CREATE OR REPLACE FUNCTION fn_real_fee(
    p_type_id IN NUMBER,
    p_amount  IN NUMBER
) RETURN NUMBER IS

    v_fee_rate   NUMBER(5,4)  := 0;
    v_fee_fixed  NUMBER(18,4) := 0;
    v_min_fee    NUMBER(18,4) := 0;
    v_max_fee    NUMBER(18,4) := NULL;
    v_fee_amount NUMBER(18,4) := 0;

BEGIN
    IF p_amount IS NULL OR p_amount <= 0 THEN
        RETURN 0;
    END IF;

    BEGIN
        SELECT fee_rate, fee_fixed, min_fee, max_fee
        INTO   v_fee_rate, v_fee_fixed, v_min_fee, v_max_fee
        FROM (
            SELECT NVL(fee_rate, 0)  AS fee_rate,
                   NVL(fee_fixed, 0) AS fee_fixed,
                   NVL(min_fee, 0)   AS min_fee,
                   max_fee
            FROM   transaction_fees
            WHERE  type_id = p_type_id
              AND  TRUNC(SYSDATE) >= effective_from
              AND  (effective_to IS NULL OR TRUNC(SYSDATE) <= effective_to)
            ORDER BY effective_from DESC
        )
        WHERE ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 0;
    END;

    v_fee_amount := (p_amount * v_fee_rate) + v_fee_fixed;

    IF v_fee_amount < v_min_fee THEN
        v_fee_amount := v_min_fee;
    END IF;

    IF v_max_fee IS NOT NULL AND v_fee_amount > v_max_fee THEN
        v_fee_amount := v_max_fee;
    END IF;

    RETURN ROUND(v_fee_amount, 4);

END fn_real_fee;
/

CREATE OR REPLACE FUNCTION fn_check_transaction_limit(
    p_wallet_id IN NUMBER,
    p_type_id   IN NUMBER,
    p_amount    IN NUMBER
) RETURN NUMBER IS

    v_kyc_status         users.kyc_status%TYPE;
    v_kyc_level          VARCHAR2(20);
    v_max_per_trans      transaction_limits.max_amount_per_trans%TYPE;
    v_max_per_day        transaction_limits.max_amount_per_day%TYPE;
    v_max_trans_day      transaction_limits.max_trans_per_day%TYPE;
    v_total_today        NUMBER(18,4) := 0;
    v_count_today        NUMBER(10)   := 0;

BEGIN
    IF p_amount IS NULL OR p_amount <= 0 THEN
        RETURN 0;
    END IF;

    SELECT u.kyc_status
    INTO   v_kyc_status
    FROM   users u
    JOIN   wallets w ON u.user_id = w.user_id
    WHERE  w.wallet_id = p_wallet_id;

    v_kyc_level := CASE
                       WHEN v_kyc_status = 'VERIFIED' THEN 'VERIFIED'
                       ELSE 'UNVERIFIED'
                   END;

    SELECT max_amount_per_trans, max_amount_per_day, max_trans_per_day
    INTO   v_max_per_trans, v_max_per_day, v_max_trans_day
    FROM   transaction_limits
    WHERE  kyc_level = v_kyc_level
      AND  ROWNUM = 1;

    IF p_amount > v_max_per_trans THEN
        RETURN 0;
    END IF;

    SELECT NVL(SUM(amount), 0), COUNT(*)
    INTO   v_total_today, v_count_today
    FROM   transactions
    WHERE  sender_wallet_id = p_wallet_id
      AND  type_id           = p_type_id
      AND  status            IN ('COMPLETED', 'PENDING')
      AND  TRUNC(created_at) = TRUNC(SYSDATE);

    IF v_total_today + p_amount > v_max_per_day THEN
        RETURN 0;
    END IF;

    IF v_count_today + 1 > v_max_trans_day THEN
        RETURN 0;
    END IF;

    RETURN 1;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;

END fn_check_transaction_limit;
/

CREATE OR REPLACE FUNCTION fn_validate_voucher(
    p_voucher_code IN VARCHAR2,
    p_amount       IN NUMBER
) RETURN NUMBER IS

    v_count NUMBER(10) := 0;

BEGIN
    IF p_voucher_code IS NULL OR p_amount IS NULL OR p_amount <= 0 THEN
        RETURN 0;
    END IF;

    SELECT COUNT(*)
    INTO   v_count
    FROM   vouchers
    WHERE  code            = p_voucher_code
      AND  is_active       = 1
      AND  amount_vouchers > 0
      AND  (valid_until IS NULL OR valid_until >= SYSTIMESTAMP)
      AND  (min_order_value IS NULL OR p_amount >= min_order_value);

    IF v_count > 0 THEN
        RETURN 1;
    END IF;

    RETURN 0;

END fn_validate_voucher;
/

CREATE OR REPLACE FUNCTION fn_voucher_discount(
    p_voucher_code IN VARCHAR2,
    p_amount       IN NUMBER
) RETURN NUMBER IS

    v_discount_type   vouchers.discount_type%TYPE;
    v_discount_value  vouchers.discount_value%TYPE;
    v_max_discount    vouchers.max_discount%TYPE;
    v_discount_amount NUMBER(18,4) := 0;

BEGIN
    IF fn_validate_voucher(p_voucher_code, p_amount) = 0 THEN
        RETURN 0;
    END IF;

    SELECT discount_type, discount_value, max_discount
    INTO   v_discount_type, v_discount_value, v_max_discount
    FROM   vouchers
    WHERE  code = p_voucher_code;

    IF v_discount_type = 'PERCENTAGE' THEN
        v_discount_amount := p_amount * NVL(v_discount_value, 0) / 100;
    ELSE
        v_discount_amount := NVL(v_discount_value, 0);
    END IF;

    IF v_max_discount IS NOT NULL AND v_discount_amount > v_max_discount THEN
        v_discount_amount := v_max_discount;
    END IF;

    IF v_discount_amount > p_amount THEN
        v_discount_amount := p_amount;
    END IF;

    RETURN ROUND(v_discount_amount, 4);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;

END fn_voucher_discount;
/

CREATE OR REPLACE FUNCTION fn_risk_score(
    p_wallet_id IN NUMBER,
    p_type_id   IN NUMBER,
    p_amount    IN NUMBER
) RETURN NUMBER IS

    v_kyc_status         users.kyc_status%TYPE;
    v_kyc_level          VARCHAR2(20);
    v_max_per_trans      NUMBER(18,4) := 0;
    v_max_per_day        NUMBER(18,4) := 0;
    v_max_trans_day      NUMBER(10)   := 0;
    v_total_today        NUMBER(18,4) := 0;
    v_count_today        NUMBER(10)   := 0;
    v_last_created_at    TIMESTAMP;
    v_minutes_from_last  NUMBER(18,4);
    v_risk_score         NUMBER(4,2)  := 0;

BEGIN
    IF p_amount IS NULL OR p_amount <= 0 THEN
        RETURN 0;
    END IF;

    SELECT u.kyc_status
    INTO   v_kyc_status
    FROM   users u
    JOIN   wallets w ON u.user_id = w.user_id
    WHERE  w.wallet_id = p_wallet_id;

    v_kyc_level := CASE
                       WHEN v_kyc_status = 'VERIFIED' THEN 'VERIFIED'
                       ELSE 'UNVERIFIED'
                   END;

    SELECT max_amount_per_trans, max_amount_per_day, max_trans_per_day
    INTO   v_max_per_trans, v_max_per_day, v_max_trans_day
    FROM   transaction_limits
    WHERE  kyc_level = v_kyc_level
      AND  ROWNUM = 1;

    SELECT NVL(SUM(amount), 0), COUNT(*), MAX(created_at)
    INTO   v_total_today, v_count_today, v_last_created_at
    FROM   transactions
    WHERE  sender_wallet_id = p_wallet_id
      AND  type_id           = p_type_id
      AND  status            IN ('COMPLETED', 'PENDING')
      AND  TRUNC(created_at) = TRUNC(SYSDATE);

    IF v_max_per_trans > 0 AND p_amount >= v_max_per_trans * 0.8 THEN
        v_risk_score := v_risk_score + 0.25;
    END IF;

    IF v_max_per_day > 0 AND (v_total_today + p_amount) >= v_max_per_day * 0.8 THEN
        v_risk_score := v_risk_score + 0.20;
    END IF;

    IF v_max_trans_day > 0 AND (v_count_today + 1) >= v_max_trans_day * 0.8 THEN
        v_risk_score := v_risk_score + 0.20;
    END IF;

    IF v_kyc_status != 'VERIFIED' THEN
        v_risk_score := v_risk_score + 0.20;
    END IF;

    IF v_last_created_at IS NOT NULL THEN
        v_minutes_from_last :=
            (CAST(SYSTIMESTAMP AS DATE) - CAST(v_last_created_at AS DATE)) * 24 * 60;

        IF v_minutes_from_last <= 5 THEN
            v_risk_score := v_risk_score + 0.15;
        END IF;
    END IF;

    IF v_risk_score > 1 THEN
        v_risk_score := 1;
    END IF;

    RETURN ROUND(v_risk_score, 2);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;

END fn_risk_score;
/

CREATE OR REPLACE FUNCTION fn_remaining_money(
    p_wallet_id IN NUMBER,
    p_type_id   IN NUMBER
) RETURN NUMBER IS

    v_kyc_status         VARCHAR2(20);
    v_kyc_level          VARCHAR2(20);
    v_max_amount_per_day NUMBER(18,4);
    v_max_trans_per_day  NUMBER(10);
    v_total_amount_today NUMBER(18,4) := 0;
    v_count_today        NUMBER(10)   := 0;
    v_remaining          NUMBER(18,4);

BEGIN
    SELECT u.kyc_status
    INTO   v_kyc_status
    FROM   users u
    JOIN   wallets w ON u.user_id = w.user_id
    WHERE  w.wallet_id = p_wallet_id;

    v_kyc_level := CASE
                       WHEN v_kyc_status = 'VERIFIED' THEN 'VERIFIED'
                       ELSE 'UNVERIFIED'
                   END;

    SELECT max_amount_per_day, max_trans_per_day
    INTO   v_max_amount_per_day, v_max_trans_per_day
    FROM   transaction_limits
    WHERE  kyc_level = v_kyc_level
      AND  ROWNUM = 1;

    SELECT NVL(SUM(amount), 0), COUNT(*)
    INTO   v_total_amount_today, v_count_today
    FROM   transactions
    WHERE  sender_wallet_id = p_wallet_id
      AND  type_id           = p_type_id
      AND  status            IN ('COMPLETED', 'PENDING')
      AND  TRUNC(created_at) = TRUNC(SYSDATE);

    IF v_count_today >= v_max_trans_per_day THEN
        RETURN 0;
    END IF;

    v_remaining := v_max_amount_per_day - v_total_amount_today;

    IF v_remaining < 0 THEN
        v_remaining := 0;
    END IF;

    RETURN ROUND(v_remaining, 4);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;

END fn_remaining_money;
/

CREATE OR REPLACE FUNCTION fn_generate_code(
    p_prefix IN VARCHAR2
) RETURN VARCHAR2 IS

    v_ref_date DATE;
    v_ref_seq  NUMBER(10);

BEGIN
    v_ref_date := TRUNC(SYSDATE);

    BEGIN
        INSERT INTO transaction_ref_sequences (ref_date, current_value, updated_at)
        VALUES (v_ref_date, 1, SYSTIMESTAMP)
        RETURNING current_value INTO v_ref_seq;
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            UPDATE transaction_ref_sequences
            SET    current_value = current_value + 1,
                   updated_at    = SYSTIMESTAMP
            WHERE  ref_date = v_ref_date
            RETURNING current_value INTO v_ref_seq;
    END;

    RETURN p_prefix || '-' || TO_CHAR(v_ref_date, 'YYYYMMDD') || '-' || LPAD(v_ref_seq, 6, '0');

END fn_generate_code;
/

CREATE OR REPLACE FUNCTION fnc_wallet_transactable(
    p_wallet_id IN wallets.wallet_id%TYPE
)
RETURN NUMBER
AS
    v_status wallets.wallet_status%TYPE;
BEGIN
    SELECT wallet_status
      INTO v_status
      FROM wallets
     WHERE wallet_id = p_wallet_id;
 
    IF v_status = 'ACTIVE' THEN
        RETURN 1;   
    ELSE
        RETURN 0;   
    END IF;
 
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN -1;  
END fnc_wallet_transactable;
/

