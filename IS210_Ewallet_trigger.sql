CREATE OR REPLACE TRIGGER trg_validate_transaction_rules
BEFORE INSERT OR UPDATE ON transactions
FOR EACH ROW
DECLARE
    v_type_code       transaction_types.type_code%TYPE;
    v_wallet_status   wallets.wallet_status%TYPE;
    v_kyc_status      users.kyc_status%TYPE;
    v_max_amount      transaction_limits.max_amount_per_trans%TYPE;
BEGIN
    ----------------------------------------------------------------------------
    -- A. KIỂM TRA ĐIỀU KIỆN THEO LOẠI GIAO DỊCH (Yêu cầu 11 & 13)
    ----------------------------------------------------------------------------
    IF :NEW.type_id IS NOT NULL THEN
        -- Lấy mã type_code (TRANSFER, WITHDRAW...) từ bảng transaction_types
        SELECT type_code INTO v_type_code
        FROM transaction_types
        WHERE type_id = :NEW.type_id;

        -- 11. Giao dịch TRANSFER phải có cả ví gửi và ví nhận.
        IF v_type_code = 'TRANSFER' THEN
            IF :NEW.sender_wallet_id IS NULL OR :NEW.receiver_wallet_id IS NULL THEN
                RAISE_APPLICATION_ERROR(-20011, 'Giao dịch TRANSFER yêu cầu phải có đầy đủ ví gửi và ví nhận.');
            END IF;
        END IF;

        -- 13. Giao dịch WITHDRAW có ví gửi nhưng không có ví nhận.
        IF v_type_code = 'WITHDRAW' THEN
            IF :NEW.sender_wallet_id IS NULL OR :NEW.receiver_wallet_id IS NOT NULL THEN
                RAISE_APPLICATION_ERROR(-20013, 'Giao dịch WITHDRAW yêu cầu phải có ví gửi và KHÔNG ĐƯỢC có ví nhận.');
            END IF;
        END IF;
    END IF;

    ----------------------------------------------------------------------------
    -- B. KIỂM TRA TRẠNG THÁI VÍ VÀ HẠN MỨC KYC (Yêu cầu 10 & 15)
    ----------------------------------------------------------------------------
    -- Chỉ kiểm tra nếu giao dịch có phát sinh từ một ví gửi
    IF :NEW.sender_wallet_id IS NOT NULL THEN
        
        -- Lấy trạng thái của ví gửi và cấp độ KYC của người dùng sở hữu ví đó
        SELECT w.wallet_status, u.kyc_status
        INTO v_wallet_status, v_kyc_status
        FROM wallets w
        JOIN users u ON w.user_id = u.user_id
        WHERE w.wallet_id = :NEW.sender_wallet_id;

        -- 10. Chỉ ví ACTIVE mới được gửi tiền.
        IF v_wallet_status != 'ACTIVE' THEN
            RAISE_APPLICATION_ERROR(-20010, 'Giao dịch từ chối: Chỉ ví ở trạng thái ACTIVE mới được phép gửi hoặc rút tiền.');
        END IF;

        -- 15. Giao dịch không được vượt hạn mức KYC.
        -- Trigger này kiểm tra hạn mức trên MỖI giao dịch (max_amount_per_trans)
        BEGIN
            SELECT max_amount_per_trans
            INTO v_max_amount
            FROM transaction_limits
            WHERE kyc_level = v_kyc_status;

            IF :NEW.amount > v_max_amount THEN
                RAISE_APPLICATION_ERROR(-20015, 
                    'Số tiền giao dịch (' || :NEW.amount || 
                    ') vượt quá hạn mức tối đa cho phép/giao dịch đối với cấp độ KYC ' || 
                    v_kyc_status || ' (Giới hạn: ' || v_max_amount || ').');
            END IF;
            
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20016, 'Hệ thống chưa cấu hình hạn mức giao dịch cho cấp độ KYC: ' || v_kyc_status);
        END;
    END IF;
END;
/
--16. Tổng số tiền giao dịch trong ngày không vượt hạn mức ngày  --  17. Số lượng giao dịch trong ngày không vượt số lần tối đa.
CREATE OR REPLACE TRIGGER trg_check_daily_limits
BEFORE INSERT OR UPDATE ON transactions
FOR EACH ROW
DECLARE
    v_user_id NUMBER;
    v_kyc_status VARCHAR2(20);

    v_max_amount_day NUMBER;
    v_max_trans_day NUMBER;

    v_total_amount_today NUMBER(18,4);
    v_total_trans_today  NUMBER;

BEGIN
    -- Kiểm tra khi transaction chuẩn bị SUCCESS
    IF :NEW.status = 'SUCCESS' THEN
    
        -- Tìm user từ sender wallet
        SELECT u.user_id, u.kyc_status
        INTO v_user_id, v_kyc_status
        FROM wallets w
        JOIN users u
            ON w.user_id = u.user_id
        WHERE w.wallet_id = :NEW.sender_wallet_id;

        -- Lấy hạn mức theo KYC
        SELECT max_amount_per_day, max_trans_per_day
        INTO v_max_amount_day, v_max_trans_day
        FROM transaction_limits
        WHERE kyc_level = v_kyc_status;

        -- #### Tính tổng số tiền giao dịch SUCCESS trong ngày ####
        SELECT NVL(SUM(t.amount), 0)
        INTO v_total_amount_today
        FROM transactions t
        JOIN wallets w
          ON t.sender_wallet_id = w.wallet_id
        WHERE w.user_id = v_user_id
          AND TRUNC(t.created_at) =
              TRUNC(NVL(:NEW.created_at, SYSTIMESTAMP))
          AND t.status = 'SUCCESS'
          AND t.transaction_id != NVL(:NEW.transaction_id, -1);

        -- #### Tính số lượng giao dịch SUCCESS trong ngày ####
        SELECT COUNT(*)
        INTO v_total_trans_today
        FROM transactions t
        JOIN wallets w
          ON t.sender_wallet_id = w.wallet_id
        WHERE w.user_id = v_user_id
          AND TRUNC(t.created_at) =
              TRUNC(NVL(:NEW.created_at, SYSTIMESTAMP))
          AND t.status = 'SUCCESS'
          AND t.transaction_id != NVL(:NEW.transaction_id, -1);

        -- Kiểm tra tổng số tiền giao dịch trong ngày
        IF (v_total_amount_today + :NEW.amount) > v_max_amount_day THEN
            RAISE_APPLICATION_ERROR(-20017, 'Vượt hạn mức tổng số tiền giao dịch tối đa trong ngày');
        END IF;

        -- Kiểm tra số lượng giao dịch trong ngày
        IF (v_total_trans_today + 1) > v_max_trans_day THEN
            RAISE_APPLICATION_ERROR(-20018, 'Vượt số lượng giao dịch tối đa trong ngày');
        END IF;
    END IF;
END;
/


--18. Voucher chỉ được dùng khi còn hạn.
CREATE OR REPLACE TRIGGER trg_check_voucher_valid
BEFORE INSERT OR UPDATE ON transactions
FOR EACH ROW
DECLARE
    v_valid_until TIMESTAMP;

BEGIN
    -- Kiểm tra transaction có voucher không
    IF :NEW.voucher_id IS NOT NULL THEN
    
        -- Lấy thời gian hết hạn voucher
        SELECT valid_until
        INTO v_valid_until
        FROM vouchers
        WHERE voucher_id = :NEW.voucher_id;

        -- #### Kiểm tra voucher còn hạn ####
        IF v_valid_until < NVL(:NEW.created_at, SYSTIMESTAMP) THEN
            RAISE_APPLICATION_ERROR(-20019, 'Voucher đã hết hạn');
        END IF;
    END IF;
END;
/


--20. Ngày giao dịch phải lớn hơn hoặc bằng ngày tạo ví liên quan.
CREATE OR REPLACE TRIGGER trg_check_transaction_date
BEFORE INSERT OR UPDATE ON transactions
FOR EACH ROW
DECLARE
    v_sender_created_at TIMESTAMP;
    v_receiver_created_at TIMESTAMP;

BEGIN
    -- #### Kiểm tra ví gửi ####
    IF :NEW.sender_wallet_id IS NOT NULL THEN

        SELECT created_at
        INTO v_sender_created_at
        FROM wallets
        WHERE wallet_id = :NEW.sender_wallet_id;

        IF NVL(:NEW.created_at, SYSTIMESTAMP) < v_sender_created_at THEN
            RAISE_APPLICATION_ERROR(-20020, 'Ngày giao dịch nhỏ hơn ngày tạo ví gửi');
        END IF;
    END IF;

    -- #### Kiểm tra ví nhận ####
    IF :NEW.receiver_wallet_id IS NOT NULL THEN

        SELECT created_at
        INTO v_receiver_created_at
        FROM wallets
        WHERE wallet_id = :NEW.receiver_wallet_id;

        IF NVL(:NEW.created_at, SYSTIMESTAMP) < v_receiver_created_at THEN
            RAISE_APPLICATION_ERROR(-20021, 'Ngày giao dịch nhỏ hơn ngày tạo ví nhận');
        END IF;
    END IF;
END;
/