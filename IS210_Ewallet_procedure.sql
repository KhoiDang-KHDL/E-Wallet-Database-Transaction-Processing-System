-- 1. Tạo mới tài khoản người dùng (người dùng + ví điện tử)
CREATE OR REPLACE PROCEDURE proc_create_user_with_wallet (
    p_full_name     IN users.full_name%TYPE,
    p_email         IN users.email%TYPE,
    p_phone         IN users.phone%TYPE,
    p_password_hash IN users.password_hash%TYPE, -- Nhận chuỗi hash từ Back-end
    p_pin_code      IN wallets.pin_code%TYPE,    
    p_currency      IN wallets.currency%TYPE DEFAULT 'VND'
) AS
    v_user_id users.user_id%TYPE;
BEGIN
    -- 1. Thêm mới thông tin người dùng vào bảng USERS
    -- Các trường kyc_status, is_active, created_at sẽ lấy giá trị DEFAULT đã cấu hình ở bảng
    INSERT INTO users (full_name, email, phone, password_hash)
    VALUES (p_full_name, p_email, p_phone, p_password_hash)
    RETURNING user_id INTO v_user_id; -- Lấy ID tự động sinh ra để dùng cho bảng WALLETS

    INSERT INTO wallets (user_id, balance, currency, wallet_status, pin_code)
    VALUES (v_user_id, 0, p_currency, 'ACTIVE', p_pin_code);

    COMMIT;
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20101, 'Lỗi hệ thống khi tạo tài khoản và ví: ' || SQLERRM);
END;
/
-- 2. Cập nhật thông tin người dùng
CREATE OR REPLACE PROCEDURE proc_update_user_info (
    p_user_id   IN users.user_id%TYPE,
    p_full_name IN users.full_name%TYPE,
    p_email     IN users.email%TYPE,
    p_phone     IN users.phone%TYPE
) AS
BEGIN
    -- Thực hiện cập nhật các trường thông tin cơ bản
    UPDATE users
    SET full_name = p_full_name,
        email     = p_email,
        phone     = p_phone
    WHERE user_id = p_user_id;

    -- Kiểm tra xem ID người dùng truyền vào có tồn tại hay không
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20102, 'Không tìm thấy người dùng với ID đã cung cấp: ' || p_user_id);
    END IF;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

-- 3. Thay đổi mật khẩu người dùng
CREATE OR REPLACE PROCEDURE proc_change_user_password (
    p_user_id           IN users.user_id%TYPE,
    p_new_password_hash IN users.password_hash%TYPE -- Chuỗi hash mới từ Back-end
) AS
BEGIN
    -- Cập nhật mật khẩu mới
    UPDATE users
    SET password_hash = p_new_password_hash
    WHERE user_id = p_user_id;

    -- Kiểm tra sự tồn tại của người dùng
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20103, 'Không thể đổi mật khẩu. Không tìm thấy người dùng có ID: ' || p_user_id);
    END IF;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/
-- 7. Thêm thông tin liên kết giữa ví và tài khoản ngân hàng
CREATE OR REPLACE PROCEDURE proc_link_bank_account (
    p_wallet_id     IN wallets.wallet_id%TYPE,
    p_provider_name IN payment_methods.provider_name%TYPE, 
    p_masked_number IN payment_methods.masked_number%TYPE, 
    p_is_default    IN payment_methods.is_default%TYPE DEFAULT 0 -- Có đặt làm mặc định không (1: Có, 0: Không)
) AS
    v_user_id       wallets.user_id%TYPE;
    v_wallet_status wallets.wallet_status%TYPE;
BEGIN
    -- 1. Kiểm tra sự tồn tại của ví và lấy thông tin user_id cùng trạng thái ví
    BEGIN
        SELECT user_id, wallet_status
        INTO v_user_id, v_wallet_status
        FROM wallets
        WHERE wallet_id = p_wallet_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20110, 'Lỗi: Không tìm thấy ví điện tử với ID đã cung cấp.');
    END;

    -- 2. Kiểm tra điều kiện trạng thái ví (Chỉ ví ACTIVE mới được thao tác liên kết)
    IF v_wallet_status != 'ACTIVE' THEN
        RAISE_APPLICATION_ERROR(-20111, 'Lỗi: Ví điện tử đang bị khóa hoặc đóng, không thể liên kết ngân hàng.');
    END IF;

    -- 3. Xử lý logic đặt làm mặc định
    -- Nếu người dùng chọn phương thức này làm mặc định (p_is_default = 1),
    -- hệ thống sẽ tự động gỡ bỏ trạng thái mặc định của các tài khoản/thẻ cũ trước đó 
    -- để không vi phạm ràng buộc UNIQUE INDEX (uq_pm_default).
    IF p_is_default = 1 THEN
        UPDATE payment_methods
        SET is_default = 0
        WHERE user_id = v_user_id AND is_default = 1;
    END IF;

    -- 4. Thêm mới bản ghi liên kết ngân hàng vào bảng PAYMENT_METHODS
    INSERT INTO payment_methods (
        user_id, 
        method_type, 
        provider_name, 
        masked_number, 
        is_default, 
        is_verified, 
        is_active
    ) VALUES (
        v_user_id, 
        'BANK_ACCOUNT',-- Cố định loại phương thức là tài khoản ngân hàng
        p_provider_name, 
        p_masked_number, 
        p_is_default, 
        1, -- Mặc định đặt bằng 1 (Đã xác thực thành công với phía ngân hàng)
        1  -- Trạng thái hoạt động kích hoạt ngay
    );

    -- 5. Xác nhận hoàn thành giao dịch an toàn
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        -- Hoàn tác nếu gặp bất kỳ lỗi xung đột dữ liệu nào khác
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20112, 'Lỗi hệ thống khi liên kết tài khoản ngân hàng: ' || SQLERRM);
END;
/
--8. Thiết lập một phương thức thanh toán làm mặc định cho các giao dịch nạp và rút tiền.
CREATE OR REPLACE PROCEDURE pr_set_default_payment_method (
    p_user_id       IN NUMBER,
    p_provider_name IN VARCHAR2,
    p_method_type   IN VARCHAR2
)
AS
    v_count NUMBER;
BEGIN
    -- 1. Kiểm tra phương thức thanh toán có tồn tại theo đúng thông tin cung cấp, đã xác thực và đang hoạt động không
    SELECT COUNT(*)
    INTO v_count
    FROM payment_methods
    WHERE user_id = p_user_id
      AND provider_name = p_provider_name
      AND method_type = p_method_type
      AND is_verified = 1
      AND is_active = 1;

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20113, 'Lỗi: Phương thức thanh toán không hợp lệ, chưa xác thực hoặc đã bị vô hiệu hóa.');
    END IF;

    -- 2. Bỏ mặc định cũ (chỉ cập nhật bản ghi nào đang là mặc định của user đó)
    UPDATE payment_methods
    SET is_default = 0
    WHERE user_id = p_user_id 
      AND is_default = 1;

    -- 3. Đặt mặc định mới dựa trên ngân hàng và loại phương thức được chọn
    UPDATE payment_methods
    SET is_default = 1
    WHERE user_id = p_user_id
      AND provider_name = p_provider_name
      AND method_type = p_method_type;

    -- 4. Xác nhận giao dịch thành công
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        -- Hoàn tác nếu có lỗi bất ngờ xảy ra
        ROLLBACK;
        RAISE;
END;
/


--9. Thiết lập hạn mức giao dịch cho ví
CREATE OR REPLACE PROCEDURE pr_update_transaction_limit (
    p_kyc_level IN VARCHAR2,
    p_max_amount_per_trans IN NUMBER,
    p_max_amount_per_day IN NUMBER,
    p_max_trans_per_day IN NUMBER
)
AS
    v_count NUMBER;

BEGIN
    -- Kiểm tra kyc level tồn tại
    SELECT COUNT(*)
    INTO v_count
    FROM transaction_limits
    WHERE kyc_level = p_kyc_level;

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20116, 'KYC level không tồn tại');
    END IF;

    -- Update hạn mức
    UPDATE transaction_limits
    SET max_amount_per_trans = p_max_amount_per_trans,
        max_amount_per_day = p_max_amount_per_day,
        max_trans_per_day = p_max_trans_per_day
    WHERE kyc_level = p_kyc_level;

    COMMIT;

END;
/


--10. Lưu lịch sử các hoạt động liên quan đến tài khoản 
CREATE OR REPLACE PROCEDURE pr_create_login_session (
    p_user_id     IN NUMBER,
    p_device_info IN VARCHAR2,
    p_ip_address  IN VARCHAR2
)
AS
    -- Khai báo ngoại lệ cho lỗi vi phạm khóa ngoại (Foreign Key Violation)
    e_fk_violation EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_fk_violation, -2291);
BEGIN
    INSERT INTO login_sessions (user_id, device_info, ip_address, is_active)
    VALUES (p_user_id, p_device_info, p_ip_address, 1);

    COMMIT;
EXCEPTION
    WHEN e_fk_violation THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20117, 'Lỗi: User không tồn tại.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

-- 11. Cập nhật mã PIN, bắt buộc kiểm tra PIN cũ
CREATE OR REPLACE PROCEDURE pr_update_pin_code(
    p_user_id  IN users.user_id%TYPE,
    p_old_pin  IN wallets.pin_code%TYPE,
    p_new_pin  IN wallets.pin_code%TYPE
)
AS
    v_wallet_id     wallets.wallet_id%TYPE;
    v_wallet_status wallets.wallet_status%TYPE;
    v_current_pin   wallets.pin_code%TYPE;
    v_is_active     users.is_active%TYPE;
    v_wallet_check  NUMBER;
BEGIN
    IF p_new_pin IS NULL THEN
        RAISE_APPLICATION_ERROR(-20120, 'Mã PIN mới không được để trống.');
    END IF;

    IF NOT REGEXP_LIKE(p_new_pin, '^\d{6}$') THEN
        RAISE_APPLICATION_ERROR(-20121, 'Mã PIN mới không hợp lệ. PIN phải có đúng 6 chữ số.');
    END IF;

    BEGIN
        SELECT is_active
        INTO v_is_active
        FROM users
        WHERE user_id = p_user_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20122, 'Không tìm thấy người dùng với user_id = ' || TO_CHAR(p_user_id));
    END;

    IF v_is_active = 0 THEN
        RAISE_APPLICATION_ERROR(-20123, 'Tài khoản người dùng đã bị vô hiệu hóa. Không thể cập nhật PIN.');
    END IF;

    BEGIN
        SELECT wallet_id, wallet_status, pin_code
        INTO v_wallet_id, v_wallet_status, v_current_pin
        FROM wallets
        WHERE user_id = p_user_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20124, 'Không tìm thấy ví điện tử của người dùng.');
    END;

    v_wallet_check := fnc_wallet_transactable(v_wallet_id);

    IF v_wallet_check = 0 THEN
        RAISE_APPLICATION_ERROR(-20125, 'Chỉ ví ACTIVE mới được cập nhật PIN. Trạng thái hiện tại: ' || v_wallet_status);
    ELSIF v_wallet_check = -1 THEN
        RAISE_APPLICATION_ERROR(-20126, 'Không thể xác nhận trạng thái ví.');
    END IF;

    IF p_old_pin IS NULL THEN
        RAISE_APPLICATION_ERROR(-20127, 'Mã PIN cũ không được để trống.');
    END IF;

    IF v_current_pin IS NOT NULL AND v_current_pin <> p_old_pin THEN
        RAISE_APPLICATION_ERROR(-20128, 'Mã PIN cũ không chính xác.');
    END IF;

    IF v_current_pin IS NOT NULL AND p_new_pin = v_current_pin THEN
        RAISE_APPLICATION_ERROR(-20129, 'Mã PIN mới không được trùng với mã PIN hiện tại.');
    END IF;

    UPDATE wallets
    SET pin_code = p_new_pin
    WHERE wallet_id = v_wallet_id;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END pr_update_pin_code;
/

CREATE OR REPLACE PROCEDURE sp_top_up_wallet(
    p_wallet_id           IN  NUMBER,
    p_method_id           IN  NUMBER,
    p_amount              IN  NUMBER,
    p_idempotency_key     IN  VARCHAR2,
    p_gateway_success     IN  NUMBER,
    p_gateway_ref         IN  VARCHAR2 DEFAULT NULL,
    p_description         IN  VARCHAR2 DEFAULT NULL,
    p_out_order_id        OUT NUMBER,
    p_out_transaction_id  OUT NUMBER,
    p_out_status          OUT VARCHAR2
) IS

    -- thông tin ví
    v_wallet_status       wallets.wallet_status%TYPE;
    v_wallet_balance      wallets.balance%TYPE;
    v_wallet_user_id      wallets.user_id%TYPE;

    -- thông tin payment method
    v_method_user_id      payment_methods.user_id%TYPE;
    v_method_verified     payment_methods.is_verified%TYPE;
    v_method_active       payment_methods.is_active%TYPE;

    -- Idempotency
    v_existing_order_id   fund_orders.order_id%TYPE;
    v_existing_status     fund_orders.status%TYPE;

    -- Giao dá»‹ch
    v_order_id            fund_orders.order_id%TYPE;
    v_type_id             transaction_types.type_id%TYPE;
    v_transaction_id      transactions.transaction_id%TYPE;
    v_reference_code      transactions.reference_code%TYPE;
    v_balance_before      wallets.balance%TYPE;
    v_balance_after       wallets.balance%TYPE;
    v_description         transactions.description%TYPE;

BEGIN
    -- 1. Kiểm tra input
    IF p_amount IS NULL OR p_amount <= 0 THEN
        RAISE_APPLICATION_ERROR(-20200, 'Số tiền nạp phải lớn hơn 0.');
    END IF;

    IF p_idempotency_key IS NULL THEN
        RAISE_APPLICATION_ERROR(-20201, 'idempotency_key không được để trống khi nạp tiền.');
    END IF;

    -- 2. Kiểm tra idempotency_key đã tồn tại chưa.
    BEGIN
        SELECT order_id, status
        INTO   v_existing_order_id, v_existing_status
        FROM   fund_orders
        WHERE  idempotency_key = p_idempotency_key;

        p_out_order_id := v_existing_order_id;
        p_out_status   := v_existing_status;

        -- Vì fund_orders hiện chưa có transaction_id, tìm lại transaction qua mô tả kỹ thuật
        BEGIN
            SELECT transaction_id
            INTO   p_out_transaction_id
            FROM   transactions
            WHERE  receiver_wallet_id = p_wallet_id
              AND  description LIKE '%TOP_UP_ORDER_ID=' || v_existing_order_id || '%'
              AND  ROWNUM = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                p_out_transaction_id := NULL;
        END;

        RETURN;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END;

    -- 3. Kiá»ƒm tra wallet tá»“n táº¡i vÃ  ACTIVE.
    SELECT wallet_status, balance, user_id
    INTO   v_wallet_status, v_wallet_balance, v_wallet_user_id
    FROM   wallets
    WHERE  wallet_id = p_wallet_id;

    IF v_wallet_status != 'ACTIVE' THEN
        RAISE_APPLICATION_ERROR(-20202, 'Ví nhận tiền không ở trạng thái ACTIVE.');
    END IF;

    -- 4. Kiểm tra payment_method tồn tại, cùng user, đã verified và active.
    SELECT user_id, is_verified, is_active
    INTO   v_method_user_id, v_method_verified, v_method_active
    FROM   payment_methods
    WHERE  method_id = p_method_id;

    IF v_method_user_id != v_wallet_user_id THEN
        RAISE_APPLICATION_ERROR(-20203, 'Payment method không thuộc cùng user với wallet.');
    END IF;

    IF v_method_verified != 1 THEN
        RAISE_APPLICATION_ERROR(-20204, 'Payment method chưa được xác thực.');
    END IF;

    IF v_method_active != 1 THEN
        RAISE_APPLICATION_ERROR(-20205, 'Payment method đang không active.');
    END IF;

    -- 5. Tạo fund_order status PENDING.
    INSERT INTO fund_orders (
        wallet_id, method_id, order_type, amount,
        status, idempotency_key, gateway_ref, created_at
    ) VALUES (
        p_wallet_id, p_method_id, 'TOP_UP', p_amount,
        'PENDING', p_idempotency_key, p_gateway_ref, SYSTIMESTAMP
    ) RETURNING order_id INTO v_order_id;

    -- 6. Nếu gateway thất bại thì cập nhật fund_order FAILED và kết thúc.
    IF NVL(p_gateway_success, 0) != 1 THEN
        UPDATE fund_orders
        SET    status      = 'FAILED',
               gateway_ref = p_gateway_ref
        WHERE  order_id    = v_order_id;

        p_out_order_id       := v_order_id;
        p_out_transaction_id := NULL;
        p_out_status         := 'FAILED';
        RETURN;
    END IF;

    -- 7. Gateway thành công: lock wallet FOR UPDATE.
    SELECT balance, wallet_status
    INTO   v_balance_before, v_wallet_status
    FROM   wallets
    WHERE  wallet_id = p_wallet_id
    FOR UPDATE;

    IF v_wallet_status != 'ACTIVE' THEN
        RAISE_APPLICATION_ERROR(-20206, 'Ví bị đổi trạng thái, không thể cộng tiền.');
    END IF;

    -- 8. Sinh mã giao dịch và lấy type TOP_UP.
    SELECT type_id
    INTO   v_type_id
    FROM   transaction_types
    WHERE  type_code = 'TOP_UP';

    v_reference_code := fn_generate_code('TOPUP');
    v_description    := NVL(p_description, 'Nạp tiền vào ví') || ' | TOP_UP_ORDER_ID=' || v_order_id;

    -- 9. Cộng tiền vào ví.
    UPDATE wallets
    SET    balance = balance + p_amount
    WHERE  wallet_id = p_wallet_id;

    v_balance_after := v_balance_before + p_amount;

    -- 10. Tạo transaction TOP_UP.
    INSERT INTO transactions (
        type_id,
        sender_wallet_id,
        receiver_wallet_id,
        amount,
        fee_amount,
        status,
        reference_code,
        step,
        description,
        created_at
    ) VALUES (
        v_type_id,
        NULL,
        p_wallet_id,
        p_amount,
        0,
        'COMPLETED',
        v_reference_code,
        TO_NUMBER(TO_CHAR(SYSTIMESTAMP, 'HH24')),
        v_description,
        SYSTIMESTAMP
    ) RETURNING transaction_id INTO v_transaction_id;

    -- 11. Ghi audit_logs CREDIT.
    INSERT INTO audit_logs (
        transaction_id, wallet_id, action_type,
        balance_before, balance_after, delta
    ) VALUES (
        v_transaction_id, p_wallet_id, 'CREDIT',
        v_balance_before, v_balance_after, p_amount
    );

    -- 12. Update fund_order SUCCESS.
    UPDATE fund_orders
    SET    status      = 'SUCCESS',
           gateway_ref = p_gateway_ref
    WHERE  order_id    = v_order_id;

    -- 13. Tráº£ káº¿t quáº£.
    p_out_order_id       := v_order_id;
    p_out_transaction_id := v_transaction_id;
    p_out_status         := 'SUCCESS';

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20209, 'Không tìm thấy wallet/payment method/transaction type phù hợp.');
    WHEN OTHERS THEN
        RAISE;

END sp_top_up_wallet;
/
-- PROCEDURE 2: Tạo yêu cầu rút tiền.
CREATE OR REPLACE PROCEDURE sp_withdraw_request(
    p_wallet_id           IN  NUMBER,
    p_method_id           IN  NUMBER,
    p_amount              IN  NUMBER,
    p_pin_code            IN  VARCHAR2,
    p_idempotency_key     IN  VARCHAR2 DEFAULT NULL,
    p_description         IN  VARCHAR2 DEFAULT NULL,
    p_out_order_id        OUT NUMBER,
    p_out_transaction_id  OUT NUMBER,
    p_out_reference_code  OUT VARCHAR2,
    p_out_status          OUT VARCHAR2
) IS

    -- thông tin ví
    v_wallet_status       wallets.wallet_status%TYPE;
    v_wallet_balance      wallets.balance%TYPE;
    v_wallet_user_id      wallets.user_id%TYPE;
    v_wallet_pin          wallets.pin_code%TYPE;

    -- thông tin user
    v_user_is_active      users.is_active%TYPE;
    v_kyc_status          users.kyc_status%TYPE;
    v_kyc_level           VARCHAR2(20);

    -- thông tin payment method
    v_method_user_id      payment_methods.user_id%TYPE;
    v_method_verified     payment_methods.is_verified%TYPE;
    v_method_active       payment_methods.is_active%TYPE;

    v_limit_id            transaction_limits.limit_id%TYPE;

    v_fee_amount          NUMBER(18,4) := 0;
    v_total_amount        NUMBER(18,4) := 0;
    v_risk_score          NUMBER(4,2)  := 0;

    -- Idempotency
    v_existing_order_id   fund_orders.order_id%TYPE;
    v_existing_status     fund_orders.status%TYPE;

    v_type_id             transaction_types.type_id%TYPE;
    v_order_id            fund_orders.order_id%TYPE;
    v_transaction_id      transactions.transaction_id%TYPE;
    v_reference_code      transactions.reference_code%TYPE;
    v_description         transactions.description%TYPE;

BEGIN
    -- 1. kiểm tra input.
    IF p_amount IS NULL OR p_amount <= 0 THEN
        RAISE_APPLICATION_ERROR(-20220, 'Số tiền rút phải lớn hơn 0.');
    END IF;

    -- 2. Nếu có idempotency_key thì kiểm tra trước.
    IF p_idempotency_key IS NOT NULL THEN
        BEGIN
            SELECT order_id, status
            INTO   v_existing_order_id, v_existing_status
            FROM   fund_orders
            WHERE  idempotency_key = p_idempotency_key;

            p_out_order_id := v_existing_order_id;
            p_out_status   := v_existing_status;

            BEGIN
                SELECT transaction_id, reference_code
                INTO   p_out_transaction_id, p_out_reference_code
                FROM   transactions
                WHERE  sender_wallet_id = p_wallet_id
                  AND  description LIKE '%WITHDRAW_ORDER_ID=' || v_existing_order_id || '%'
                  AND  ROWNUM = 1;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    p_out_transaction_id := NULL;
                    p_out_reference_code := NULL;
            END;

            RETURN;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
        END;
    END IF;

    -- 3. Lock wallet FOR UPDATE.
    SELECT balance, wallet_status, user_id, pin_code
    INTO   v_wallet_balance, v_wallet_status, v_wallet_user_id, v_wallet_pin
    FROM   wallets
    WHERE  wallet_id = p_wallet_id
    FOR UPDATE;

    -- 4. Kiểm tra wallet ACTIVE.
    IF v_wallet_status != 'ACTIVE' THEN
        RAISE_APPLICATION_ERROR(-20221, 'Ví rút tiền không ở trạng thái ACTIVE.');
    END IF;

    -- 5. Kiểm tra PIN giao dịch.
    IF v_wallet_pin IS NULL OR v_wallet_pin != p_pin_code THEN
        RAISE_APPLICATION_ERROR(-20222, 'Mã PIN giao dịch không đúng.');
    END IF;

    -- 6. Kiểm tra user active và KYC.
    SELECT is_active, kyc_status
    INTO   v_user_is_active, v_kyc_status
    FROM   users
    WHERE  user_id = v_wallet_user_id;

    IF v_user_is_active != 1 THEN
        RAISE_APPLICATION_ERROR(-20223, 'Tài khoản user đang không active.');
    END IF;

    v_kyc_level := CASE
                       WHEN v_kyc_status = 'VERIFIED' THEN 'VERIFIED'
                       ELSE 'UNVERIFIED'
                   END;

    -- 7. Kiểm tra payment_method thuộc cùng user, verified và active.
    SELECT user_id, is_verified, is_active
    INTO   v_method_user_id, v_method_verified, v_method_active
    FROM   payment_methods
    WHERE  method_id = p_method_id;

    IF v_method_user_id != v_wallet_user_id THEN
        RAISE_APPLICATION_ERROR(-20224, 'Payment method không thuộc cùng user với wallet.');
    END IF;

    IF v_method_verified != 1 THEN
        RAISE_APPLICATION_ERROR(-20225, 'Payment method chưa được xác thực.');
    END IF;

    IF v_method_active != 1 THEN
        RAISE_APPLICATION_ERROR(-20226, 'Payment method đang không active.');
    END IF;

   -- 8. Lấy type WITHDRAW và limit_id.
    SELECT type_id
    INTO   v_type_id
    FROM   transaction_types
    WHERE  type_code = 'WITHDRAW';

    SELECT limit_id
    INTO   v_limit_id
    FROM   transaction_limits
    WHERE  kyc_level = v_kyc_level
      AND  ROWNUM = 1;
    v_fee_amount   := fn_real_fee(v_type_id, p_amount);
    v_total_amount := p_amount + v_fee_amount;

    -- 10. kiểm tra balance >= total_amount.
    IF v_wallet_balance < v_total_amount THEN
        RAISE_APPLICATION_ERROR(
            -20227,
            'Số dư ví không đủ để rút tiền. Số dư: ' || v_wallet_balance ||
            ', cần: ' || v_total_amount
        );
    END IF;

    -- 11. Kiểm tra hạn mức KYC.
    IF fn_check_transaction_limit(p_wallet_id, v_type_id, p_amount) = 0 THEN
        RAISE_APPLICATION_ERROR(-20228, 'Giao dá»‹ch rÃºt tiá»n vÆ°á»£t háº¡n má»©c KYC/ngÃ y.');
    END IF;

    -- 12. Tính risk_score heuristic để ghi vào mô tả xử lý.
    v_risk_score := fn_risk_score(p_wallet_id, v_type_id, p_amount);

   -- 13. Tạo fund_order PENDING
    INSERT INTO fund_orders (
        wallet_id, method_id, order_type, amount,
        status, idempotency_key, created_at
    ) VALUES (
        p_wallet_id, p_method_id, 'WITHDRAW', p_amount,
        'PENDING', p_idempotency_key, SYSTIMESTAMP
    ) RETURNING order_id INTO v_order_id;

    -- 14. Sinh mã giao dịch
    v_reference_code := fn_generate_code('WDR');
    v_description    := NVL(p_description, 'Yêu cầu rút tiền') ||
                        ' | WITHDRAW_ORDER_ID=' || v_order_id ||
                        ' | RISK_SCORE=' || TO_CHAR(v_risk_score);

    -- 15. Tạo transaction WITHDRAW status PENDING.
    INSERT INTO transactions (
        type_id,
        sender_wallet_id,
        receiver_wallet_id,
        limit_id,
        amount,
        fee_amount,
        status,
        reference_code,
        step,
        description,
        created_at
    ) VALUES (
        v_type_id,
        p_wallet_id,
        NULL,
        v_limit_id,
        p_amount,
        v_fee_amount,
        'PENDING',
        v_reference_code,
        TO_NUMBER(TO_CHAR(SYSTIMESTAMP, 'HH24')),
        v_description,
        SYSTIMESTAMP
    ) RETURNING transaction_id INTO v_transaction_id;

    -- 16. Trừ tiền ví, bao gồm amount + fee_amount.
    UPDATE wallets
    SET    balance = balance - v_total_amount
    WHERE  wallet_id = p_wallet_id;

    -- 17. Ghi audit_logs DEBIT.
    INSERT INTO audit_logs (
        transaction_id, wallet_id, action_type,
        balance_before, balance_after, delta
    ) VALUES (
        v_transaction_id, p_wallet_id, 'DEBIT',
        v_wallet_balance,
        v_wallet_balance - v_total_amount,
        v_total_amount
    );

    -- 18. Trả kết quả.
    p_out_order_id       := v_order_id;
    p_out_transaction_id := v_transaction_id;
    p_out_reference_code := v_reference_code;
    p_out_status         := 'PENDING';

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20229, 'Không tìm thấy dữ liệu cần thiết cho yêu cầu rút tiền.');
    WHEN OTHERS THEN
        RAISE;

END sp_withdraw_request;
/
-- PROCEDURE 3: Xác nhận kết quả rút tiền từ gateway/bank.
-- Nếu thành công: fund_order SUCCESS, transaction COMPLETED.
-- Nếu thất bại: hoàn tiền ví, fund_order FAILED, transaction FAILED, ghi audit CREDI
CREATE OR REPLACE PROCEDURE sp_confirm_withdraw(
    p_order_id         IN  NUMBER,
    p_transaction_id   IN  NUMBER,
    p_gateway_success  IN  NUMBER,
    p_gateway_ref      IN  VARCHAR2 DEFAULT NULL,
    p_out_status       OUT VARCHAR2
) IS

    -- Fund order
    v_order_wallet_id   fund_orders.wallet_id%TYPE;
    v_order_amount      fund_orders.amount%TYPE;
    v_order_status      fund_orders.status%TYPE;

    -- Transaction
    v_trans_wallet_id   transactions.sender_wallet_id%TYPE;
    v_trans_amount      transactions.amount%TYPE;
    v_trans_fee         transactions.fee_amount%TYPE;
    v_trans_status      transactions.status%TYPE;
    v_refund_amount     NUMBER(18,4) := 0;

    -- Wallet
    v_wallet_balance    wallets.balance%TYPE;
    v_balance_after     wallets.balance%TYPE;

BEGIN
    -- 1. Lock fund_order.
    SELECT wallet_id, amount, status
    INTO   v_order_wallet_id, v_order_amount, v_order_status
    FROM   fund_orders
    WHERE  order_id = p_order_id
    FOR UPDATE;

    -- 2. Lock transaction.
    SELECT sender_wallet_id, amount, fee_amount, status
    INTO   v_trans_wallet_id, v_trans_amount, v_trans_fee, v_trans_status
    FROM   transactions
    WHERE  transaction_id = p_transaction_id
    FOR UPDATE;

    -- 3. Kiểm tra order và transaction khớp nhau.
    IF v_order_wallet_id != v_trans_wallet_id THEN
        RAISE_APPLICATION_ERROR(-20240, 'fund_order và transaction không cùng wallet.');
    END IF;

    IF v_order_amount != v_trans_amount THEN
        RAISE_APPLICATION_ERROR(-20241, 'Số tiền fund_order và transaction không khớp.');
    END IF;

    -- 4. Nếu đã được xử lý trước đó thì trả trạng thái hiện tại, tránh hoàn tiền/cập nhật trùng.
    IF v_order_status != 'PENDING' OR v_trans_status != 'PENDING' THEN
        p_out_status := v_trans_status;
        RETURN;
    END IF;

    -- 5. Gateway/bank thành công.
    IF NVL(p_gateway_success, 0) = 1 THEN
        UPDATE fund_orders
        SET    status      = 'SUCCESS',
               gateway_ref = p_gateway_ref
        WHERE  order_id    = p_order_id;

        UPDATE transactions
        SET    status = 'COMPLETED'
        WHERE  transaction_id = p_transaction_id;

        p_out_status := 'COMPLETED';
        RETURN;
    END IF;

    -- 6. Gateway/bank thất bại: hoàn lại amount + fee_amount
    v_refund_amount := v_trans_amount + NVL(v_trans_fee, 0);

    SELECT balance
    INTO   v_wallet_balance
    FROM   wallets
    WHERE  wallet_id = v_trans_wallet_id
    FOR UPDATE;

    UPDATE wallets
    SET    balance = balance + v_refund_amount
    WHERE  wallet_id = v_trans_wallet_id;

    v_balance_after := v_wallet_balance + v_refund_amount;

    -- 7. Ghi audit_logs CREDIT cho phần hoàn lại.
    INSERT INTO audit_logs (
        transaction_id, wallet_id, action_type,
        balance_before, balance_after, delta
    ) VALUES (
        p_transaction_id, v_trans_wallet_id, 'CREDIT',
        v_wallet_balance, v_balance_after, v_refund_amount
    );

    -- 8. Update status FAILED.
    UPDATE fund_orders
    SET    status      = 'FAILED',
           gateway_ref = p_gateway_ref
    WHERE  order_id    = p_order_id;

    UPDATE transactions
    SET    status = 'FAILED'
    WHERE  transaction_id = p_transaction_id;

    p_out_status := 'FAILED';

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20249, 'Không tìm thấy fund_order/transaction/wallet khi xác nhận rút tiền.');
    WHEN OTHERS THEN
        RAISE;

END sp_confirm_withdraw;
/
-- PROCEDURE 13: Xử lý chuyển tiền
CREATE OR REPLACE PROCEDURE sp_transfer_money(
    p_sender_wallet_id   IN  NUMBER,
    p_receiver_wallet_id IN  NUMBER,
    p_amount             IN  NUMBER,
    p_pin_code           IN  VARCHAR2,
    p_voucher_code       IN  VARCHAR2 DEFAULT NULL,
    p_description        IN  VARCHAR2 DEFAULT NULL,
    p_out_transaction_id OUT NUMBER,
    p_out_reference_code OUT VARCHAR2,
    p_out_status         OUT VARCHAR2
) IS

    v_sender_status     wallets.wallet_status%TYPE;
    v_sender_balance    wallets.balance%TYPE;
    v_sender_user_id    wallets.user_id%TYPE;
    v_sender_pin        wallets.pin_code%TYPE;
    v_receiver_status   wallets.wallet_status%TYPE;
    v_receiver_balance  wallets.balance%TYPE;
    v_receiver_user_id  wallets.user_id%TYPE;

    v_sender_is_active  users.is_active%TYPE;
    v_kyc_status        users.kyc_status%TYPE;
    v_kyc_level         VARCHAR2(20);

    v_fee_amount        NUMBER(18,4) := 0;
    v_net_fee           NUMBER(18,4) := 0;   -- Phí sau khi trừ voucher giảm giá
    v_discount_amount   NUMBER(18,4) := 0;
    v_total_deduct      NUMBER(18,4);        

    -- Voucher
    v_voucher_id        vouchers.voucher_id%TYPE;
    v_discount_type     vouchers.discount_type%TYPE;
    v_discount_value    vouchers.discount_value%TYPE;
    v_min_order_value   vouchers.min_order_value%TYPE;
    v_max_discount      vouchers.max_discount%TYPE;

    v_limit_id          transaction_limits.limit_id%TYPE;
    v_max_per_trans     transaction_limits.max_amount_per_trans%TYPE;
    v_max_per_day       transaction_limits.max_amount_per_day%TYPE;
    v_max_trans_day     transaction_limits.max_trans_per_day%TYPE;
    v_total_today       NUMBER(18,4) := 0;
    v_count_today       NUMBER(10)   := 0;

    v_transaction_id    transactions.transaction_id%TYPE;
    v_reference_code    transactions.reference_code%TYPE;

    -- Hằng số‘ TRANSFER 
    C_TYPE_TRANSFER     CONSTANT NUMBER(5) := 3;

BEGIN
    --1. Lấy thông tin ví gửi và ví nhận  
    SELECT balance, wallet_status, user_id, pin_code
    INTO   v_sender_balance, v_sender_status, v_sender_user_id, v_sender_pin
    FROM   wallets
    WHERE  wallet_id = p_sender_wallet_id;

    SELECT balance, wallet_status, user_id
    INTO   v_receiver_balance, v_receiver_status, v_receiver_user_id
    FROM   wallets
    WHERE  wallet_id = p_receiver_wallet_id;

    
    -- 2–3. SELECT ví gửi và ví nhận FOR UPDATE
    IF p_sender_wallet_id < p_receiver_wallet_id THEN
        -- Lock ví gửi trước
        SELECT balance, wallet_status
        INTO   v_sender_balance, v_sender_status
        FROM   wallets
        WHERE  wallet_id = p_sender_wallet_id
        FOR UPDATE;

        -- Lock ví nhận sau
        SELECT balance, wallet_status
        INTO   v_receiver_balance, v_receiver_status
        FROM   wallets
        WHERE  wallet_id = p_receiver_wallet_id
        FOR UPDATE;
    ELSE
        -- Lock ví nhận trước
        SELECT balance, wallet_status
        INTO   v_receiver_balance, v_receiver_status
        FROM   wallets
        WHERE  wallet_id = p_receiver_wallet_id
        FOR UPDATE;

        -- Lock ví gửi sau
        SELECT balance, wallet_status
        INTO   v_sender_balance, v_sender_status
        FROM   wallets
        WHERE  wallet_id = p_sender_wallet_id
        FOR UPDATE;
    END IF;

    -- 4. Kiểm tra ví gửi ACTIVE
    IF v_sender_status != 'ACTIVE' THEN
        RAISE_APPLICATION_ERROR(
            -20300,
            'Ví người gửi không ở trạng thái ACTIVE nha bạn. Trạng thái hiện tại: ' || v_sender_status
        );
    END IF;

    -- 5. Kiểm tra ví nhận ACTIVE
    IF v_receiver_status != 'ACTIVE' THEN
        RAISE_APPLICATION_ERROR(
            -20301,
            'Ví người nhận không ở trạng thái ACTIVE nha bạn. Trạng thái hiện tại: ' || v_receiver_status
        );
    END IF;

    -- 6. Kiểm tra sender_wallet_id <> receiver_wallet_id
    IF p_sender_wallet_id = p_receiver_wallet_id THEN
        RAISE_APPLICATION_ERROR(-20302, 'Ví gửi và ví nhận không được trùng nhau nha bạn.');
    END IF;

    -- 7. Kiểm tra PIN giao dịch
    IF v_sender_pin IS NULL OR v_sender_pin != p_pin_code THEN
        RAISE_APPLICATION_ERROR(-20303, 'Mã PIN không đúng nha bạn.');
    END IF;

    -- 8. Kiểm tra user active
    SELECT is_active, kyc_status
    INTO   v_sender_is_active, v_kyc_status
    FROM   users
    WHERE  user_id = v_sender_user_id;

    IF v_sender_is_active = 0 THEN
        RAISE_APPLICATION_ERROR(-20304, 'Tài khoản người gửi đã bị khóa rồi nha bạn.');
    END IF;

     -- 9. Tính fee_amount dựa trên transaction_fees 
    v_fee_amount := fn_real_fee(C_TYPE_TRANSFER, p_amount);

    -- 10. Kiểm tra voucher 
    v_discount_amount := 0;
    v_voucher_id      := NULL;

    IF p_voucher_code IS NOT NULL THEN
        -- Thông tin voucher hợp lệ là còn hạn, còn lượt và active
        BEGIN
            SELECT voucher_id, discount_type, discount_value,
                   min_order_value, max_discount
            INTO   v_voucher_id, v_discount_type, v_discount_value,
                   v_min_order_value, v_max_discount
            FROM   vouchers
            WHERE  code            = p_voucher_code
              AND  is_active       = 1
              AND  amount_vouchers > 0
              AND  (valid_until IS NULL OR valid_until >= SYSTIMESTAMP);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20305, 'Voucher không hợp lệ hoặc đã hết hạn hoặc đã hết lượt sử dụng nha bạn.');
        END;

        -- Kiểm tra số đơn hàng tối thiểu để áp dụng voucher
        IF v_min_order_value IS NOT NULL AND p_amount < v_min_order_value THEN
            RAISE_APPLICATION_ERROR(
                -20306,
                'Số tiền giao dịch (' || p_amount || ') chưa đạt giá trị tối thiểu để dùng voucher nha bạn (' || v_min_order_value || ').'
            );
        END IF;

        -- Tính giảm giá theo loại voucher
        IF v_discount_type = 'PERCENTAGE' THEN
            v_discount_amount := p_amount * v_discount_value;  
        ELSE                                                     
            v_discount_amount := v_discount_value;
        END IF;

        -- Giới hạn giảm giá tối đa
        IF v_max_discount IS NOT NULL AND v_discount_amount > v_max_discount THEN
            v_discount_amount := v_max_discount;
        END IF;

        IF v_discount_amount > v_fee_amount THEN
            v_discount_amount := v_fee_amount;
        END IF;
    END IF;

    -- 11. Tính total_amount = amount + fee_amount - discount_amount (voucher).
    v_net_fee      := v_fee_amount - v_discount_amount;
    v_total_deduct := p_amount + v_net_fee;

     -- 12. Kiểm tra balance ví gửi >= total_amount
    IF v_sender_balance < v_total_deduct THEN
        RAISE_APPLICATION_ERROR(
            -20307,
            'Số dư ví không đủ. Số dư hiện tại: ' || v_sender_balance ||
            ', cần thanh toán: ' || v_total_deduct
        );
    END IF;

    -- 13. Kiểm tra hạn mức KYC
    v_kyc_level := CASE WHEN v_kyc_status = 'VERIFIED' THEN 'VERIFIED' ELSE 'UNVERIFIED' END;

    SELECT limit_id, max_amount_per_trans, max_amount_per_day, max_trans_per_day
    INTO   v_limit_id, v_max_per_trans, v_max_per_day, v_max_trans_day
    FROM   transaction_limits
    WHERE  kyc_level = v_kyc_level
      AND  ROWNUM    = 1;

    IF p_amount > v_max_per_trans THEN
        RAISE_APPLICATION_ERROR(
            -20308,
            'Số tiền vượt hạn mức tối đa mỗi giao dịch: ' || v_max_per_trans
        );
    END IF;

    -- Tổng giao dịch TRANSFER trong ngày hôm nay của ví gửi
    SELECT NVL(SUM(amount), 0), COUNT(*)
    INTO   v_total_today, v_count_today
    FROM   transactions
    WHERE  sender_wallet_id = p_sender_wallet_id
      AND  type_id           = C_TYPE_TRANSFER
      AND  status            IN ('COMPLETED', 'PENDING')
      AND  TRUNC(created_at) = TRUNC(SYSDATE);

    -- Kiểm tra tổng giao dịch ngày + amount <= max_amount_per_day
    IF v_total_today + p_amount > v_max_per_day THEN
        RAISE_APPLICATION_ERROR(
            -20310,
            'Vượt hạn mức giao dịch ngày nha bạn. Còn có thể giao dịch: ' ||
            GREATEST(v_max_per_day - v_total_today, 0)
        );
    END IF;

    -- Kiểm tra số giao dịch ngày + 1 <= max_trans_per_day 
    IF v_count_today + 1 > v_max_trans_day THEN
        RAISE_APPLICATION_ERROR(
            -20311,
            'Đã đạt giới hạn số lượng giao dịch trong ngày nha bạn (' || v_max_trans_day || ' láº§n).'
        );
    END IF;

    -- 14. Sinh reference_code
    v_reference_code := fn_generate_code('TXN');

    -- 15. Tạo transaction status PROCESSING hoặc COMPLETED. 
    INSERT INTO transactions (
        type_id,
        sender_wallet_id,
        receiver_wallet_id,
        limit_id,
        voucher_id,
        amount,
        fee_amount,
        status,
        reference_code,
        description,
        created_at
    ) VALUES (
        C_TYPE_TRANSFER,
        p_sender_wallet_id,
        p_receiver_wallet_id,
        v_limit_id,
        v_voucher_id,
        p_amount,
        v_net_fee,
        'COMPLETED',
        v_reference_code,
        p_description,
        SYSTIMESTAMP
    ) RETURNING transaction_id INTO v_transaction_id;

    -- 16. Trừ tiền ví gửi 
    UPDATE wallets
    SET    balance = balance - v_total_deduct
    WHERE  wallet_id = p_sender_wallet_id;

    -- 17. Cộng tiền ví nhận 
    UPDATE wallets
    SET    balance = balance + p_amount
    WHERE  wallet_id = p_receiver_wallet_id;

    -- 18. Ghi audit log DEBIT cho ví gửi
    INSERT INTO audit_logs (
        transaction_id, wallet_id, action_type,
        balance_before, balance_after, delta
    ) VALUES (
        v_transaction_id, p_sender_wallet_id, 'DEBIT',
        v_sender_balance,
        v_sender_balance - v_total_deduct,
        v_total_deduct
    );

    -- 19. Ghi audit log CREDIT cho ví nhận
    INSERT INTO audit_logs (
        transaction_id, wallet_id, action_type,
        balance_before, balance_after, delta
    ) VALUES (
        v_transaction_id, p_receiver_wallet_id, 'CREDIT',
        v_receiver_balance,
        v_receiver_balance + p_amount,
        p_amount
    );

    IF v_voucher_id IS NOT NULL THEN
        UPDATE vouchers
        SET    amount_vouchers = amount_vouchers - 1
        WHERE  voucher_id = v_voucher_id;
    END IF;

    -- 20. Kiểm tra fraud rule
    p_out_transaction_id := v_transaction_id;
    p_out_reference_code := v_reference_code;
    p_out_status         := 'COMPLETED';

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20309, 'Không tìm thấy ví nha bạn.');
    WHEN OTHERS THEN
        RAISE;   

END sp_transfer_money;
/
-- PROCEDURE 14: Xử lý đảo ngược giao dịch (Reversed) trong trường hợp có lỗi hệ thống hoặc yêu cầu hoàn tiền khẩn cấp, đảm bảo tính nguyên tử khi trả lại tiền cho người gửi và thu hồi từ người nhận.
CREATE OR REPLACE PROCEDURE sp_reversal(
    p_original_transaction_id IN  NUMBER,
    p_description             IN  VARCHAR2 DEFAULT NULL,
    p_out_transaction_id      OUT NUMBER,
    p_out_reference_code      OUT VARCHAR2,
    p_out_status              OUT VARCHAR2
) IS

    -- Giao dịch gốc
    v_orig_type_id            transactions.type_id%TYPE;
    v_orig_sender_wallet_id   transactions.sender_wallet_id%TYPE;
    v_orig_receiver_wallet_id transactions.receiver_wallet_id%TYPE;
    v_orig_amount             transactions.amount%TYPE;
    v_orig_status             transactions.status%TYPE;

    -- Ví của giao dịch đảo ngược
    v_rev_sender_wallet_id    NUMBER;
    v_rev_receiver_wallet_id  NUMBER;

    -- Số dư ví lúc lock
    v_rev_sender_balance      wallets.balance%TYPE;
    v_rev_receiver_balance    wallets.balance%TYPE;

    -- Kiểm tra coi đảo ngược chưa
    v_reversal_count          NUMBER(10);

    -- Kết quả
    v_transaction_id          transactions.transaction_id%TYPE;
    v_reference_code          transactions.reference_code%TYPE;

    -- Hằng số REVERSAL 
    C_TYPE_REVERSAL CONSTANT NUMBER(5) := 5;

BEGIN
    -- 1. Tìm transaction gốc
    BEGIN
        SELECT type_id, sender_wallet_id, receiver_wallet_id, amount, status
        INTO   v_orig_type_id, v_orig_sender_wallet_id, v_orig_receiver_wallet_id,
               v_orig_amount, v_orig_status
        FROM   transactions
        WHERE  transaction_id = p_original_transaction_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(
                -20330,
                'Không tìm thấy giao dịch gốc nha bạn: ' || p_original_transaction_id
            );
    END;

    -- 2. Kiểm tra transaction gốc status = COMPLETED
    IF v_orig_status != 'COMPLETED' THEN
        RAISE_APPLICATION_ERROR(
            -20331,
            'Chỉ có thể đảo ngược giao dịch có trạng thái COMPLETED nha bạn. ' ||
            'Trạng thái hiện tại:' || v_orig_status
        );
    END IF;

    -- 3. Kiểm tra transaction gốc chưa từng bị REVERSED
    SELECT COUNT(*)
    INTO   v_reversal_count
    FROM   transactions
    WHERE  original_transaction_id = p_original_transaction_id
      AND  type_id                 = C_TYPE_REVERSAL
      AND  status                  = 'COMPLETED';

    IF v_reversal_count > 0 THEN
        RAISE_APPLICATION_ERROR(
            -20332,
            'Giao dịch ID ' || p_original_transaction_id || ' đã được đảo ngược rồi nha bạn.'
        );
    END IF;

    -- 4. Lock các ví liên quan FOR UPDATE
    v_rev_sender_wallet_id   := v_orig_receiver_wallet_id;
    v_rev_receiver_wallet_id := v_orig_sender_wallet_id;

    -- Lock theo thứ tự ID
    IF v_rev_sender_wallet_id < v_rev_receiver_wallet_id THEN
        SELECT balance INTO v_rev_sender_balance
        FROM   wallets WHERE wallet_id = v_rev_sender_wallet_id   FOR UPDATE;

        SELECT balance INTO v_rev_receiver_balance
        FROM   wallets WHERE wallet_id = v_rev_receiver_wallet_id FOR UPDATE;
    ELSE
        SELECT balance INTO v_rev_receiver_balance
        FROM   wallets WHERE wallet_id = v_rev_receiver_wallet_id FOR UPDATE;

        SELECT balance INTO v_rev_sender_balance
        FROM   wallets WHERE wallet_id = v_rev_sender_wallet_id   FOR UPDATE;
    END IF;

    -- 5. Xác định dòng tiền đảo ngược
    --  - Nếu giao dịch gốc là TRANSFER:
    --   ví nhận cũ trở thành sender
    --   ví gửi cũ trở thành receiver
    --  - Nếu giao dịch gốc là WITHDRAW:
    --   hoàn lại tiền vào ví gửi
    --  - Nếu giao dịch gốc là PAYMENT:
    --   hoàn tiền từ merchant/user nhận về người trả
    v_rev_sender_wallet_id   := v_orig_receiver_wallet_id;
    v_rev_receiver_wallet_id := v_orig_sender_wallet_id;
    
    -- 6. Kiểm tra ví bị thu hồi có đủ tiền nếu cần
    IF v_rev_sender_balance < v_orig_amount THEN
        RAISE_APPLICATION_ERROR(
            -20333,
            'Ví người nhận (wallet_id=' || v_rev_sender_wallet_id || ') không đủ số dư để hoàn tiền nha. ' ||
            'Số dư: ' || v_rev_sender_balance || ', cần hoàn: ' || v_orig_amount
        );
    END IF;

    v_reference_code := fn_generate_code('REV');

    -- 7. Tạo transaction mới type REVERSAL hoặc REFUND.
    -- 8. original_transaction_id = transaction_id gốc
    INSERT INTO transactions (
        type_id,
        sender_wallet_id,
        receiver_wallet_id,
        original_transaction_id,
        amount,
        fee_amount,
        status,
        reference_code,
        description,
        created_at
    ) VALUES (
        C_TYPE_REVERSAL,
        v_rev_sender_wallet_id,
        v_rev_receiver_wallet_id,
        p_original_transaction_id,
        v_orig_amount,
        0,
        'COMPLETED',
        v_reference_code,
        NVL(p_description, 'Đảo ngược giao dịch #' || p_original_transaction_id),
        SYSTIMESTAMP
    ) RETURNING transaction_id INTO v_transaction_id;

    -- 9. Cập nhật số dư
    UPDATE wallets
    SET    balance = balance - v_orig_amount
    WHERE  wallet_id = v_rev_sender_wallet_id;

    UPDATE wallets
    SET    balance = balance + v_orig_amount
    WHERE  wallet_id = v_rev_receiver_wallet_id;

    -- 10. Ghi audit_logs
    INSERT INTO audit_logs (
        transaction_id, wallet_id, action_type,
        balance_before, balance_after, delta
    ) VALUES (
        v_transaction_id, v_rev_sender_wallet_id, 'DEBIT',
        v_rev_sender_balance,
        v_rev_sender_balance - v_orig_amount,
        v_orig_amount
    );

    INSERT INTO audit_logs (
        transaction_id, wallet_id, action_type,
        balance_before, balance_after, delta
    ) VALUES (
        v_transaction_id, v_rev_receiver_wallet_id, 'CREDIT',
        v_rev_receiver_balance,
        v_rev_receiver_balance + v_orig_amount,
        v_orig_amount
    );

    -- 11. Cập nhật transaction gốc status = REVERSED
    UPDATE transactions
    SET    status     = 'REVERSED',
           updated_at = SYSTIMESTAMP
    WHERE  transaction_id = p_original_transaction_id;



    p_out_transaction_id := v_transaction_id;
    p_out_reference_code := v_reference_code;
    p_out_status := 'COMPLETED';
EXCEPTION
    WHEN OTHERS THEN
        RAISE;  

END sp_reversal;
/

