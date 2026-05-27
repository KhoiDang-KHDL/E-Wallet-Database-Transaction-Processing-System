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
    
--Ràng buộc 31: Tổng tiền giao dịch thực tế không được âm.  
CREATE OR REPLACE TRIGGER trg_total_not_negative
BEFORE INSERT OR UPDATE OF amount, fee_amount ON transactions
FOR EACH ROW
BEGIN
    IF (:NEW.amount + :NEW.fee_amount) < 0 THEN
        RAISE_APPLICATION_ERROR(
            -20031,
            'Tổng tiên giao dịch(amount + fee_amount = '
            || TO_CHAR(:NEW.amount + :NEW.fee_amount)
            || ') không được âm nha bạn.'
        );
    END IF;
END;
/

--Ràng buộc 32: Thuộc tính phone trong bảng USERS là duy nhất.
CREATE OR REPLACE TRIGGER trg_phone_unique
BEFORE INSERT OR UPDATE OF phone ON users
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    IF :NEW.phone IS NOT NULL THEN
        IF INSERTING THEN
            SELECT COUNT(*)
              INTO v_count
              FROM users
             WHERE phone = :NEW.phone;
        ELSE  -- UPDATING
            SELECT COUNT(*)
              INTO v_count
              FROM users
             WHERE phone    = :NEW.phone
               AND user_id <> :OLD.user_id;
        END IF;
 
        IF v_count > 0 THEN
            RAISE_APPLICATION_ERROR(
                -20032,
                'Số điện thoại "' || :NEW.phone
                || '" đã tồn tại trong hệ thống nha bạn.'
            );
        END IF;
    END IF;
END;
/

--Ràng buộc 33: fee_rate nằm trong khoảng [0; 1].
CREATE OR REPLACE TRIGGER trg_fee_rate_range
BEFORE INSERT OR UPDATE OF fee_rate ON transaction_fees
FOR EACH ROW
BEGIN
    IF :NEW.fee_rate < 0 OR :NEW.fee_rate > 1 THEN
        RAISE_APPLICATION_ERROR(
            -20033,
            'fee_rate = ' || TO_CHAR(:NEW.fee_rate)
            || ' phải nằm trong khoảng [0, 1].'
        );
    END IF;
END;
/

--Ràng buộc 34: Các giá trị phí trong TRANSACTION_FEES không được âm.
CREATE OR REPLACE TRIGGER trg_fee_not_negative
BEFORE INSERT OR UPDATE OF fee_rate, fee_fixed, min_fee, max_fee
    ON transaction_fees
FOR EACH ROW
BEGIN
    IF :NEW.fee_rate < 0 THEN
        RAISE_APPLICATION_ERROR(
            -20034,
            'fee_rate = ' || TO_CHAR(:NEW.fee_rate)
            || ' không được âm nha bạn.'
        );
    END IF;
 
    IF :NEW.fee_fixed < 0 THEN
        RAISE_APPLICATION_ERROR(
            -20034,
            'fee_fixed = ' || TO_CHAR(:NEW.fee_fixed)
            || ' không được âm nha bạn.'
        );
    END IF;
 
    IF :NEW.min_fee < 0 THEN
        RAISE_APPLICATION_ERROR(
            -20034,
            'min_fee = ' || TO_CHAR(:NEW.min_fee)
            || ' không được âm nha bạn.'
        );
    END IF;
 
    IF :NEW.max_fee IS NOT NULL AND :NEW.max_fee < 0 THEN
        RAISE_APPLICATION_ERROR(
            -20034,
            'max_fee = ' || TO_CHAR(:NEW.max_fee)
            || ' không được âm nha bạn.'
        );
    END IF;
END;
/

--Ràng buộc 35: Hạn mức giao dịch phải là số dương. 
CREATE OR REPLACE TRIGGER trg_limit_positive
BEFORE INSERT OR UPDATE OF max_amount_per_trans, max_amount_per_day,
    max_trans_per_day ON transaction_limits
FOR EACH ROW
BEGIN
    IF :NEW.max_amount_per_trans <= 0 THEN
        RAISE_APPLICATION_ERROR(
            -20035,
            'max_amount_per_trans = '
            || TO_CHAR(:NEW.max_amount_per_trans)
            || ' phải lớn hơn 0 nha bạn.'
        );
    END IF;
 
    IF :NEW.max_amount_per_day <= 0 THEN
        RAISE_APPLICATION_ERROR(
            -20035,
            'max_amount_per_day = '
            || TO_CHAR(:NEW.max_amount_per_day)
            || ' phải lớn hơn 0 nha bạn.'
        );
    END IF;
 
    IF :NEW.max_trans_per_day <= 0 THEN
        RAISE_APPLICATION_ERROR(
            -20035,
            'max_trans_per_day = '
            || TO_CHAR(:NEW.max_trans_per_day)
            || ' phải lớn hơn 0 nha bạn.'
        );
    END IF;
END;
/

--Ràng buộc 36: Hạn mức mỗi giao dịch không vượt quá hạn mức mỗi ngày. 
CREATE OR REPLACE TRIGGER trg_limit_not_exceed_limit_per_day
BEFORE INSERT OR UPDATE OF max_amount_per_trans, max_amount_per_day
    ON transaction_limits
FOR EACH ROW
BEGIN
    IF :NEW.max_amount_per_trans > :NEW.max_amount_per_day THEN
        RAISE_APPLICATION_ERROR(
            -20036,
            'max_amount_per_trans ('
            || TO_CHAR(:NEW.max_amount_per_trans)
            || ') không được vượt quá max_amount_per_day ('
            || TO_CHAR(:NEW.max_amount_per_day) || ').'
        );
    END IF;
END;
/

--Ràng buộc 37: Ví gửi và ví nhận không được trùng nhau 
CREATE OR REPLACE TRIGGER trg_wallet_not_same
BEFORE INSERT OR UPDATE OF sender_wallet_id, receiver_wallet_id
    ON transactions
FOR EACH ROW
BEGIN
    IF     :NEW.sender_wallet_id   IS NOT NULL
       AND :NEW.receiver_wallet_id IS NOT NULL
       AND :NEW.sender_wallet_id   =  :NEW.receiver_wallet_id
    THEN
        RAISE_APPLICATION_ERROR(
            -20037,
            'Ví gửi (sender_wallet_id = '
            || TO_CHAR(:NEW.sender_wallet_id)
            || ') và ví nhận không được trùng nhau.'
        );
    END IF;
END;
/

--Ràng buộc 38: Chỉ ví ACTIVE mới được gửi tiền. 
--kiểm tra khi thêm sửa
CREATE OR REPLACE TRIGGER trg_active_sender_wallet
BEFORE INSERT OR UPDATE OF sender_wallet_id ON transactions
FOR EACH ROW
DECLARE
    v_status wallets.wallet_status%TYPE;
BEGIN
    IF :NEW.sender_wallet_id IS NOT NULL THEN
        BEGIN
            SELECT wallet_status
              INTO v_status
              FROM wallets
             WHERE wallet_id = :NEW.sender_wallet_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(
                    -20038,
                    'Ví gửi (wallet_id = '
                    || TO_CHAR(:NEW.sender_wallet_id)
                    || ') không tồn tại nha bạn.'
                );
        END;
 
        IF v_status <> 'ACTIVE' THEN
            RAISE_APPLICATION_ERROR(
                -20038,
                'Ví gửi (wallet_id = '
                || TO_CHAR(:NEW.sender_wallet_id)
                || ') đang ở trạng thái "' || v_status
                || '". Chỉ ví ACTIVE mới được gửi tiền nha bạn.'
            );
        END IF;
    END IF;
END;
/
--kiểm tra khi đổi trạng thái ví
CREATE OR REPLACE TRIGGER trg_active_sender_wallet_status
BEFORE UPDATE OF wallet_status ON wallets
FOR EACH ROW
DECLARE
    v_pending_count NUMBER;
BEGIN
    IF :OLD.wallet_status = 'ACTIVE'
       AND :NEW.wallet_status <> 'ACTIVE'
    THEN
        SELECT COUNT(*)
          INTO v_pending_count
          FROM transactions
         WHERE sender_wallet_id = :NEW.wallet_id
           AND status           = 'PENDING';
 
        IF v_pending_count > 0 THEN
            RAISE_APPLICATION_ERROR(
                -20038,
                'Không thể chuyển ví (wallet_id = '
                || TO_CHAR(:NEW.wallet_id)
                || ') sang trạng thái "' || :NEW.wallet_status
                || '" ví con ' || TO_CHAR(v_pending_count)
                || ' giao dịch PENDING đang sử dụng ví này để gửi tiền nha bạn.'
            );
        END IF;
    END IF;
END;
/

--Ràng buộc 39: Giao dịch TRANSFER phải có cả ví gửi và ví nhận. 
-- kiểm tra khi thêm hoặc sửa
CREATE OR REPLACE TRIGGER trg_transfer_wallets
BEFORE INSERT OR UPDATE OF type_id, sender_wallet_id, receiver_wallet_id
    ON transactions
FOR EACH ROW
DECLARE
    v_type_code transaction_types.type_code%TYPE;
BEGIN
    IF :NEW.type_id IS NOT NULL THEN
        BEGIN
            SELECT type_code
              INTO v_type_code
              FROM transaction_types
             WHERE type_id = :NEW.type_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(
                    -20039,
                    'type_id = '
                    || TO_CHAR(:NEW.type_id)
                    || ' không tồn tại trong TRANSACTION_TYPES nha bạn.'
                );
        END;
 
        IF v_type_code = 'TRANSFER' THEN
            IF :NEW.sender_wallet_id IS NULL THEN
                RAISE_APPLICATION_ERROR(
                    -20039,
                    'Giao dịch TRANSFER (transaction_id = '
                    || NVL(TO_CHAR(:NEW.transaction_id), 'NEW')
                    || ') thiếu sender_wallet_id nha bạn.'
                );
            END IF;
 
            IF :NEW.receiver_wallet_id IS NULL THEN
                RAISE_APPLICATION_ERROR(
                    -20039,
                    'Giao dịch TRANSFER (transaction_id = '
                    || NVL(TO_CHAR(:NEW.transaction_id), 'NEW')
                    || ') thiếu receiver_wallet_id nha bạn.'
                );
            END IF;
        END IF;
    END IF;
END;
/
-- kiểm tra khi đổi type_code thành 'TRANSFER'
CREATE OR REPLACE TRIGGER trg_transfer_wallets_type_code
BEFORE UPDATE OF type_code ON transaction_types
FOR EACH ROW
DECLARE
    v_violate_count NUMBER;
BEGIN
    IF :NEW.type_code = 'TRANSFER' AND :OLD.type_code <> 'TRANSFER' THEN
        SELECT COUNT(*)
          INTO v_violate_count
          FROM transactions
         WHERE type_id = :NEW.type_id
           AND (sender_wallet_id IS NULL OR receiver_wallet_id IS NULL);
 
        IF v_violate_count > 0 THEN
            RAISE_APPLICATION_ERROR(
                -20039,
                'Có ' || TO_CHAR(v_violate_count)
                || ' giao dịch dùng type_id = '
                || TO_CHAR(:NEW.type_id)
                || ' đang thiếu sender hoặc receiver wallet nha bạn. '
                || 'Không thể đổi type_code sang TRANSFER nha bạn.'
            );
        END IF;
    END IF;
END;
/
