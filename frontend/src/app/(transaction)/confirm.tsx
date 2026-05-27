// src/app/(transaction)/confirm.tsx
import { Ionicons } from '@expo/vector-icons';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { useRef, useState } from 'react';
import { ActivityIndicator, Alert, KeyboardAvoidingView, Modal, Platform, ScrollView, StyleSheet, Text, TextInput, TouchableOpacity, View } from 'react-native';

// Import cấu hình API và token xác thực
import { API_URL } from '../../utils/api';
import { getToken } from '../../utils/auth_storage';

export default function ConfirmScreen() {
  const router = useRouter();
  
  // Nhận toàn bộ tham số tính toán từ API /estimate
  const params = useLocalSearchParams<{ 
    type: 'deposit' | 'withdraw' | 'transfer'; 
    amount: string; 
    fee_amount: string;
    discount_amount: string;
    net_fee: string;
    total_deduct: string;
    description: string;
    voucher_code?: string;
    
    // Thêm các tham số riêng cho Chuyển tiền (Transfer)
    phone?: string;
    name?: string;
    
    // Thêm các tham số riêng cho Nạp tiền / Rút tiền (Deposit / Withdraw)
    bank?: string;            // Tên ngân hàng liên kết (để hiển thị UI)
    method_id?: string;       // ID ngân hàng (để gửi xuống API Backend)
    idempotency_key?: string; // Khóa chống trùng giao dịch
  }>();

  // Quản lý trạng thái Pop-up PIN và Loading
  const [isModalVisible, setIsModalVisible] = useState(false);
  const [submitting, setSubmitting] = useState(false);

  // Mảng chứa giá trị của 6 ô PIN độc lập
  const [pin, setPin] = useState(['', '', '', '', '', '']);
  
  // Tạo mảng tham chiếu (Refs) để điều khiển auto-focus chuyển ô
  const inputRefs = useRef<Array<TextInput | null>>([]);

  const formatVNĐ = (val: string | number) => {
    const num = typeof val === 'string' ? parseInt(val || '0') : val;
    return num.toLocaleString('vi-VN') + ' VNĐ';
  };

  const getLabelDetails = () => {
    switch (params.type) {
      case 'deposit': return { icon: 'wallet-outline', color: '#10B981', label: 'Nguồn tiền' };
      case 'withdraw': return { icon: 'business-outline', color: '#EF4444', label: 'Rút về tài khoản' };
      default: return { icon: 'paper-plane-outline', color: '#2563EB', label: 'Người nhận' };
    }
  };

  const info = getLabelDetails();

  // Xử lý khi người dùng gõ vào từng ô PIN
  const handlePinChange = (text: string, index: number) => {
    const cleanText = text.replace(/[^0-9]/g, '');
    const newPin = [...pin];
    newPin[index] = cleanText;
    setPin(newPin);

    // Nếu gõ xong 1 số, tự động focus sang ô kế tiếp bên phải
    if (cleanText && index < 5) {
      inputRefs.current[index + 1]?.focus();
    }

    // Nếu đã điền đủ cả 6 số, kích hoạt gọi API luôn
    const fullPin = newPin.join('');
    if (fullPin.length === 6 && index === 5) {
      executePayment(fullPin);
    }
  };

  // Xử lý nút xóa ngược (Backspace)
  const handleKeyPress = (e: any, index: number) => {
    if (e.nativeEvent.key === 'Backspace' && !pin[index] && index > 0) {
      // Nếu ô hiện tại rỗng mà bấm xóa, tự nhảy ngược về ô trước nó
      inputRefs.current[index - 1]?.focus();
      const newPin = [...pin];
      newPin[index - 1] = '';
      setPin(newPin);
    }
  };

  // Gọi API thật tương ứng với từng loại nghiệp vụ xuống Oracle DB
  const executePayment = async (completedPin: string) => {
    setSubmitting(true);
    const token = getToken();

    let endpoint = '';
    let bodyPayload = {};

    // RẼ NHÁNH TẠO PAYLOAD CHUẨN THEO ĐÚNG FASTAPI / ORACLE CỦA BẠN
    switch (params.type) {
      case 'deposit':
        endpoint = `${API_URL}/transactions/top-up`;
        bodyPayload = {
          method_id: parseInt(params.method_id || '1'),
          amount: parseInt(params.amount),
          idempotency_key: params.idempotency_key || `topup_${Date.now()}`,
          gateway_success: true, // Khớp với logic: 1 if payload.gateway_success else 0
          gateway_ref: `GWAY_REF_${Date.now()}`, // Mã đối tác thanh toán giả lập thành công
          description: params.description || "Nạp tiền vào tài khoản ví"
        };
        break;

      case 'withdraw':
        endpoint = `${API_URL}/transactions/withdraw`;
        bodyPayload = {
          method_id: parseInt(params.method_id || '1'),
          amount: parseInt(params.amount),
          pin_code: completedPin, // Bắt buộc truyền mã PIN để sp_withdraw_request verify
          idempotency_key: params.idempotency_key || `withdraw_${Date.now()}`,
          description: params.description || "Rút tiền từ ví về ngân hàng"
        };
        break;

      case 'transfer':
      default:
        endpoint = `${API_URL}/transactions/transfer`;
        bodyPayload = {
          receiver_phone: params.phone || null,
          receiver_wallet_id: null,
          amount: parseInt(params.amount),
          pin_code: completedPin, // Bắt buộc mã PIN xác thực chuyển tiền
          voucher_code: params.voucher_code || null,
          description: params.description || "Chuyển tiền ví điện tử"
        };
        break;
    }

    try {
      console.log(`Gửi Request lên endpoint: ${endpoint}`);
      console.log('Payload thực tế:', JSON.stringify(bodyPayload, null, 2));

      const response = await fetch(endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify(bodyPayload)
      });

      const data = await response.json();

      console.log('============= [BACKEND ORACLE RESPONSE] =============');
      console.log(JSON.stringify(data, null, 2));
      console.log('=====================================================');

      if (response.ok) {
        setIsModalVisible(false); // Đóng pop-up mã PIN thành công
        
        // Trích xuất mã giao dịch động (Bởi vì Top-up trả ra order_id, còn Transfer/Withdraw trả ra reference_code)
        let displayRefCode = 'N/A';
        if (data.reference_code) displayRefCode = data.reference_code;
        else if (data.order_id) displayRefCode = `ORD_${data.order_id}`;
        else if (data.transaction_id) displayRefCode = `TX_${data.transaction_id}`;

        // Đẩy sang trang kết quả xịn sò
        router.replace({
          pathname: "/(transaction)/result",
          params: {
            status: 'success',
            amount: params.amount,
            name: params.type === 'deposit' 
              ? `Nạp từ ${params.bank}` 
              : params.type === 'withdraw' 
                ? `Rút về ${params.bank}` 
                : params.name,
            refCode: displayRefCode, 
            msg: params.description
          }
        });
      } else {
        // GIAO DỊCH THẤT BẠI (Sai mã PIN, lỗi số dư, lỗi Stored Procedure...)
        setIsModalVisible(false);
        setPin(['', '', '', '', '', '']); // Xóa trắng mảng mã PIN

        router.replace({
          pathname: "/(transaction)/result",
          params: {
            status: 'failed',
            amount: params.amount,
            name: params.type === 'deposit' 
              ? `Nạp từ ${params.bank}` 
              : params.type === 'withdraw' 
                ? `Rút về ${params.bank}` 
                : params.name,
            refCode: 'N/A',
            msg: data.detail || 'Bị từ chối bởi hệ thống quản trị Oracle'
          }
        });
      }
    } catch (error) {
      console.error("Lỗi crash giao dịch tại màn hình Confirm:", error);
      setIsModalVisible(false);
      Alert.alert('Lỗi kết nối', 'Không thể gửi yêu cầu xác thực giao dịch đến máy chủ Backend.');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <View style={styles.container}>
      <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
        
        {/* 1. SỐ TIỀN CHÍNH */}
        <View style={styles.centerSection}>
          <View style={[styles.iconCircle, { backgroundColor: info.color + '15' }]}>
            <Ionicons name={info.icon as any} size={40} color={info.color} />
          </View>
          <Text style={styles.mainAmount}>{formatVNĐ(params.amount)}</Text>
          <Text style={styles.subLabel}>Số tiền giao dịch</Text>
        </View>

        {/* 2. CHI TIẾT TỜ HÓA ĐƠN */}
        <View style={styles.receiptCard}>
          <View style={styles.receiptRow}>
            <Text style={styles.rowLabel}>{info.label}</Text>
            <Text style={styles.rowValue}>{params.name ? `${params.name} (${params.phone})` : 'Tài khoản liên kết'}</Text>
          </View>
          
          <View style={styles.divider} />

          <View style={styles.receiptRow}>
            <Text style={styles.rowLabel}>Phí giao dịch</Text>
            <Text style={styles.rowValue}>{formatVNĐ(params.fee_amount)}</Text>
          </View>

          <View style={styles.receiptRow}>
            <Text style={styles.rowLabel}>Voucher giảm phí</Text>
            <Text style={[styles.rowValue, { color: '#10B981' }]}>-{formatVNĐ(params.discount_amount)}</Text>
          </View>

          <View style={styles.receiptRow}>
            <Text style={styles.rowLabel}>Nội dung</Text>
            <Text style={[styles.rowValue, { color: '#4B5563', fontSize: 13 }]} numberOfLines={2}>{params.description}</Text>
          </View>

          <View style={styles.thickDivider} />

          <View style={styles.receiptRow}>
            <Text style={styles.totalLabel}>Tổng tiền thanh toán</Text>
            <Text style={[styles.totalValue, { color: info.color }]}>{formatVNĐ(params.total_deduct)}</Text>
          </View>
        </View>

        {/* NÚT BẤM MỞ POPUP PIN */}
        <TouchableOpacity 
          style={[styles.confirmButton, { backgroundColor: info.color }]} 
          onPress={() => {
            setPin(['', '', '', '', '', '']); // Clear PIN cũ nếu có
            setIsModalVisible(true);
          }}
        >
          <Text style={styles.confirmButtonText}>Xác nhận thanh toán</Text>
        </TouchableOpacity>

      </ScrollView>

      {/* 🌟 3. POP-UP MODAL NHẬP MÃ PIN (MỚI BỔ SUNG) */}
      <Modal
        visible={isModalVisible}
        transparent={true}
        animationType="slide"
        onRequestClose={() => !submitting && setIsModalVisible(false)}
      >
        <KeyboardAvoidingView 
          behavior={Platform.OS === 'ios' ? 'padding' : 'height'} 
          style={styles.modalOverlay}
        >
          <View style={styles.modalContent}>
            
            {/* Header của Pop-up */}
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Nhập mã PIN an toàn</Text>
              <TouchableOpacity 
                disabled={submitting} 
                onPress={() => setIsModalVisible(false)}
                style={styles.closeButton}
              >
                <Ionicons name="close" size={22} color="#4B5563" />
              </TouchableOpacity>
            </View>
            
            <Text style={styles.modalSubtitle}>Vui lòng điền 6 số PIN để xác thực ví</Text>

            {/* Vùng chứa 6 ô vuông PIN rời nhau */}
            <View style={styles.otpContainer}>
              {pin.map((digit, index) => (
                <TextInput
                  key={index}
                  style={styles.otpInput}
                  keyboardType="number-pad"
                  maxLength={1}
                  secureTextEntry={true} // Hiện dấu chấm bảo mật thay vì lộ số
                  value={digit}
                  onChangeText={(text) => handlePinChange(text, index)}
                  onKeyPress={(e) => handleKeyPress(e, index)}
                  ref={(ref) => {
                    inputRefs.current[index] = ref;
                  }}
                  autoFocus={index === 0} // Tự động mở bàn phím ở ô đầu tiên
                  editable={!submitting}
                />
              ))}
            </View>

            {submitting && (
              <View style={styles.loadingWrapper}>
                <ActivityIndicator size="small" color={info.color} />
                <Text style={[styles.loadingText, { color: info.color }]}>Đang kiểm tra số dư & PIN...</Text>
              </View>
            )}

          </View>
        </KeyboardAvoidingView>
      </Modal>

    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#F9FAFB' },
  scrollContent: { padding: 24, alignItems: 'center' },
  centerSection: { alignItems: 'center', marginTop: 16 },
  iconCircle: { width: 80, height: 80, borderRadius: 40, justifyContent: 'center', alignItems: 'center', marginBottom: 16 },
  mainAmount: { fontSize: 32, fontWeight: '700', color: '#1F2937' },
  subLabel: { fontSize: 14, color: '#9CA3AF', marginBottom: 24, fontWeight: '500' },
  receiptCard: { backgroundColor: '#FFFFFF', borderRadius: 20, padding: 20, width: '100%', borderWidth: 1, borderColor: '#E5E7EB', marginBottom: 40 },
  receiptRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginVertical: 8 },
  rowLabel: { fontSize: 13, color: '#6B7280', fontWeight: '500' },
  rowValue: { fontSize: 14, color: '#1F2937', fontWeight: '700', textAlign: 'right', flex: 1, marginLeft: 16 },
  divider: { height: 1, backgroundColor: '#F3F4F6', marginVertical: 6 },
  thickDivider: { height: 1, borderStyle: 'dashed', borderWidth: 1, borderColor: '#E5E7EB', marginVertical: 12 },
  totalLabel: { fontSize: 15, color: '#1F2937', fontWeight: '700' },
  totalValue: { fontSize: 16, color: '#1F2937', fontWeight: '800' },
  confirmButton: { width: '100%', height: 56, borderRadius: 16, justifyContent: 'center', alignItems: 'center', marginTop: 10 },
  confirmButtonText: { color: '#FFFFFF', fontSize: 16, fontWeight: '700' },
  
  // 🌟 STYLES MỚI DÀNH CHO POP-UP MODAL PIN:
  modalOverlay: { flex: 1, backgroundColor: 'rgba(0, 0, 0, 0.5)', justifyContent: 'flex-end' },
  modalContent: { backgroundColor: '#FFFFFF', borderTopLeftRadius: 28, borderTopRightRadius: 28, padding: 24, minHeight: 280, width: '100%' },
  modalHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 6 },
  modalTitle: { fontSize: 18, fontWeight: '700', color: '#1F2937' },
  closeButton: { padding: 4 },
  modalSubtitle: { fontSize: 14, color: '#6B7280', marginBottom: 28 },
  
  // Container bọc 6 ô nhập liệu
  otpContainer: { flexDirection: 'row', justifyContent: 'space-between', width: '100%', paddingHorizontal: 4 },
  otpInput: {
    width: 46,
    height: 52,
    borderWidth: 1.5,
    borderColor: '#E5E7EB',
    borderRadius: 12,
    textAlign: 'center',
    fontSize: 22,
    fontWeight: '700',
    backgroundColor: '#F9FAFB',
    color: '#1F2937'
  },
  loadingWrapper: { flexDirection: 'row', justifyContent: 'center', alignItems: 'center', marginTop: 24 },
  loadingText: { marginLeft: 8, fontSize: 14, fontWeight: '600' }
});