// src/app/(transaction)/transfer.tsx
import { Ionicons } from '@expo/vector-icons';
import { useLocalSearchParams, useNavigation, useRouter } from 'expo-router';
import { useEffect, useState } from 'react';
import { ActivityIndicator, Alert, BackHandler, KeyboardAvoidingView, Platform, ScrollView, StyleSheet, Text, TextInput, TouchableOpacity, View } from 'react-native';
import { Colors } from '../../../src/constants/Colors';

// Import cấu hình API và token xác thực
import { API_URL } from '../../utils/api';
import { getToken } from '../../utils/auth_storage';

export default function TransferScreen() {
  const router = useRouter();
  const navigation = useNavigation(); // Khởi tạo navigation để can thiệp header layout
  
  // 🌟 LẤY THAM SỐ TRẢ VỀ TỪ TRANG VOUCHER (Nếu user chọn xong và quay lại)
  const searchParams = useLocalSearchParams<{ voucher_code?: string; amount?: string }>();
  
  // Các trạng thái UI/UX
  const [isBalanceVisible, setIsBalanceVisible] = useState(true);
  const [myBalance, setMyBalance] = useState<number>(0);
  const [loadingBalance, setLoadingBalance] = useState(true);
  const [estimating, setEstimating] = useState(false);

  // Input fields
  const [amount, setAmount] = useState('');
  const [recipientPhone, setRecipientPhone] = useState('');
  const [recipientName, setRecipientName] = useState(''); 
  const [searchingRecipient, setSearchingRecipient] = useState(false);
  const [message, setMessage] = useState('');
  
  // State lưu mã Voucher được áp dụng
  const [selectedVoucher, setSelectedVoucher] = useState<string | null>(null);

  // Xử lý dứt điểm luồng điều hướng Back về thẳng Home
  useEffect(() => {
    // 1. Ép nút Back trên Header của cả iOS và Android về thẳng Home
    navigation.setOptions({
      headerLeft: () => (
        <TouchableOpacity onPress={() => router.replace('/(tabs)')} style={{ padding: 8, marginLeft: -8 }}>
          <Ionicons name="arrow-back" size={24} color="#1F2937" />
        </TouchableOpacity>
      ),
    });

    // 2. Ép nút Back cứng hoặc cử chỉ vuốt cạnh của Android về thẳng Home
    const backAction = () => {
      router.replace('/(tabs)');
      return true; // Chặn không cho hệ thống lùi stack tự do
    };

    const backHandler = BackHandler.addEventListener('hardwareBackPress', backAction);

    return () => backHandler.remove(); // Hủy lắng nghe khi unmount tránh leak bộ nhớ
  }, [navigation]);

  // Đồng bộ voucher và giữ lại số tiền cũ khi đi từ trang list_voucher quay về
  useEffect(() => {
    if (searchParams.voucher_code) {
      setSelectedVoucher(searchParams.voucher_code);
    }
    if (searchParams.amount) {
      setAmount(searchParams.amount);
    }
  }, [searchParams.voucher_code, searchParams.amount]);

  // Lấy token
  const token = getToken();
  const headers = {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`
  };

  // 1. Tải số dư ví thực tế của user khi vào trang
  useEffect(() => {
    async function fetchWalletBalance() {
      try {
        const res = await fetch(`${API_URL}/wallet`, { method: 'GET', headers });
        if (res.ok) {
          const wallet = await res.json();
          setMyBalance(wallet.balance);
        }
      } catch (err) {
        console.error("Lỗi lấy số dư:", err);
      } finally {
        setLoadingBalance(false);
      }
    }
    fetchWalletBalance();
  }, []);

  // 2. Tra cứu người nhận tự động khi gõ đủ số điện thoại
  useEffect(() => {
    if (recipientPhone.length >= 10) {
      lookupRecipient();
    } else {
      setRecipientName(''); 
    }
  }, [recipientPhone]);

  const lookupRecipient = async () => {
    setSearchingRecipient(true);
    try {
      const res = await fetch(`${API_URL}/wallet/lookup?phone=${recipientPhone}`, { method: 'GET', headers });
      const data = await res.json();
      
      if (res.ok && data) {
        setRecipientName(data.full_name); 
      } else {
        setRecipientName('Không tìm thấy người dùng này');
      }
    } catch (err) {
      setRecipientName('');
    } finally {
      setSearchingRecipient(false);
    }
  };

  const formatCurrency = (val: number | string) => {
    const num = typeof val === 'string' ? parseInt(val) : val;
    if (isNaN(num)) return '0';
    return num.toLocaleString('vi-VN');
  };

  // 3. Xử lý Ước tính phí & Chuyển dữ liệu sang màn hình xác nhận
  const handleTransfer = async () => {
    if (!amount || !recipientPhone) {
      Alert.alert('Thông báo', 'Vui lòng nhập đầy đủ Số điện thoại và Số tiền!');
      return;
    }

    if (!recipientName || recipientName.includes('Không tìm thấy')) {
      Alert.alert('Lỗi', 'Người nhận không hợp lệ, vui lòng kiểm tra lại!');
      return;
    }

    const numAmount = parseInt(amount);
    if (numAmount > myBalance) {
      Alert.alert('Lỗi', 'Số dư ví không đủ để thực hiện giao dịch!');
      return;
    }

    setEstimating(true);

    try {
      const res = await fetch(`${API_URL}/transactions/estimate`, {
        method: 'POST',
        headers,
        body: JSON.stringify({
          type_code: "TRANSFER",
          amount: numAmount,
          voucher_code: selectedVoucher || null 
        })
      });

      const estimateData = await res.json();

      if (res.ok) {
        router.push({
          pathname: "/(transaction)/confirm",
          params: {
            type: 'transfer',
            phone: recipientPhone,
            name: recipientName,
            amount: estimateData.amount.toString(),
            fee_amount: estimateData.fee_amount.toString(),
            discount_amount: estimateData.discount_amount.toString(),
            net_fee: estimateData.net_fee.toString(),
            total_deduct: estimateData.total_deduct.toString(), 
            description: message || "Chuyển tiền qua ứng dụng E-Wallet",
            voucher_code: selectedVoucher || ""
          }
        });
      } else {
        Alert.alert('Lỗi tính phí', estimateData.detail || 'Không thể ước tính giao dịch.');
      }
    } catch (error) {
      Alert.alert('Lỗi kết nối', 'Không thể kết nối đến hệ thống kiểm tra phí.');
    } finally {
      setEstimating(false);
    }
  };

  return (
    <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : 'height'} style={styles.container}>
      <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
        
        {/* 2. WALLET INFO CARD */}
        <View style={styles.walletCard}>
          <View style={styles.walletHeader}>
            <Text style={styles.walletLabel}>Số dư ví khả dụng</Text>
            <TouchableOpacity onPress={() => setIsBalanceVisible(!isBalanceVisible)}>
              <Ionicons 
                name={isBalanceVisible ? "eye-outline" : "eye-off-outline"} 
                size={20} 
                color="#fff" 
              />
            </TouchableOpacity>
          </View>
          {loadingBalance ? (
            <ActivityIndicator color="#fff" size="small" style={{ alignSelf: 'flex-start' }} />
          ) : (
            <Text style={styles.balanceValue}>
              {isBalanceVisible ? `${formatCurrency(myBalance)} VNĐ` : "******** đ"}
            </Text>
          )}
        </View>

        {/* 3. RECIPIENT INPUT */}
        <View style={styles.section}>
          <Text style={styles.sectionLabel}>Người nhận tiền (Số điện thoại)</Text>
          <View style={styles.inputWrapper}>
            <Ionicons name="phone-portrait-outline" size={20} color="#9CA3AF" />
            <TextInput
              style={styles.textInput}
              placeholder="Nhập số điện thoại người nhận"
              keyboardType="phone-pad"
              value={recipientPhone}
              onChangeText={setRecipientPhone}
            />
            {searchingRecipient && <ActivityIndicator size="small" color={Colors.primary} />}
          </View>
          {recipientName ? (
            <Text style={[styles.recipientNameText, recipientName.includes('Không tìm thấy') && { color: '#EF4444' }]}>
              {recipientName.includes('Không tìm thấy') ? '' : '👤 Tên người nhận: '}{recipientName}
            </Text>
          ) : null}
        </View>

        {/* 4. AMOUNT INPUT */}
        <View style={styles.section}>
          <Text style={styles.sectionLabel}>Số tiền chuyển</Text>
          <View style={styles.amountInputBox}>
            <TextInput
              style={styles.bigAmountInput}
              placeholder="0"
              keyboardType="number-pad"
              value={amount}
              onChangeText={(text) => setAmount(text.replace(/[^0-9]/g, ''))}
            />
            <Text style={styles.currencyLabel}>VNĐ</Text>
          </View>
        </View>

        {/* 🌟 5. VOUCHER SELECTION (ĐÃ CHÈN LOGIC TRUYỀN AMOUNT SANG TRANG LIST_VOUCHER) */}
        <TouchableOpacity 
          style={[
            styles.voucherCard, 
            selectedVoucher ? styles.voucherCardActive : null
          ]} 
          onPress={() => {
            // Đẩy kèm cả số tiền hiện tại qua URL để trang list lọc điều kiện min_order_value
            router.push({
              pathname: '/list_vouchers',
              params: {
                referrer: 'transfer',
                amount: amount || '0'
              }
            });
          }}
        >
          <View style={styles.voucherLeft}>
            <Ionicons 
              name={selectedVoucher ? "checkmark-circle" : "pricetag-outline"} 
              size={22} 
              color={selectedVoucher ? '#10B981' : Colors.primary} 
            />
            <Text style={[
              styles.voucherText,
              selectedVoucher ? { color: '#10B981', fontWeight: '700' } : null
            ]}>
              {selectedVoucher ? `Đã chọn mã: ${selectedVoucher}` : 'Chọn Voucher giảm phí'}
            </Text>
          </View>
          <View style={styles.voucherRight}>
            {selectedVoucher ? (
              <TouchableOpacity onPress={(e) => {
                e.stopPropagation(); 
                setSelectedVoucher(null);
                router.setParams({ voucher_code: '', amount: amount });
              }}>
                <Text style={styles.cancelVoucherText}>Hủy áp dụng</Text>
              </TouchableOpacity>
            ) : (
              <>
                <Text style={styles.voucherNote}>Khả dụng</Text>
                <Ionicons name="chevron-forward" size={18} color="#9CA3AF" />
              </>
            )}
          </View>
        </TouchableOpacity>

        {/* 6. MESSAGE INPUT */}
        <View style={styles.section}>
          <Text style={styles.sectionLabel}>Lời nhắn (Không bắt buộc)</Text>
          <TextInput
            style={styles.messageInput}
            placeholder="Nhập nội dung chuyển tiền..."
            multiline
            value={message}
            onChangeText={setMessage}
          />
        </View>

        <TouchableOpacity 
          style={[styles.submitButton, estimating && { opacity: 0.7 }]} 
          onPress={handleTransfer}
          disabled={estimating}
        >
          {estimating ? (
            <ActivityIndicator color="#fff" />
          ) : (
            <Text style={styles.submitButtonText}>Tiếp tục</Text>
          )}
        </TouchableOpacity>

      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#F9FAFB' },
  scrollContent: { padding: 20 },
  walletCard: { backgroundColor: '#1F2937', borderRadius: 20, padding: 20, marginBottom: 24 },
  walletHeader: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: 8 },
  walletLabel: { color: '#9CA3AF', fontSize: 13, fontWeight: '500' },
  balanceValue: { color: '#fff', fontSize: 24, fontWeight: '700' },
  section: { marginBottom: 20 },
  sectionLabel: { fontSize: 14, fontWeight: '600', color: '#4B5563', marginBottom: 8 },
  inputWrapper: { flexDirection: 'row', alignItems: 'center', backgroundColor: '#fff', borderRadius: 12, borderWidth: 1, borderColor: '#E5E7EB', paddingHorizontal: 12, height: 52 },
  textInput: { flex: 1, marginLeft: 10, fontSize: 15, color: '#1F2937' },
  recipientNameText: { marginTop: 6, fontSize: 13, color: '#10B981', fontWeight: '600', paddingLeft: 4 },
  amountInputBox: { flexDirection: 'row', alignItems: 'center', backgroundColor: '#fff', borderRadius: 12, borderWidth: 1, borderColor: '#E5E7EB', paddingHorizontal: 16, height: 70 },
  bigAmountInput: { flex: 1, fontSize: 28, fontWeight: '700', color: '#1F2937' },
  currencyLabel: { fontSize: 16, fontWeight: '700', color: '#4B5563' },
  voucherCard: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', backgroundColor: '#fff', padding: 16, borderRadius: 12, borderWidth: 1, borderColor: '#E5E7EB', marginBottom: 24 },
  voucherCardActive: { borderColor: '#10B981', backgroundColor: '#ECFDF5', borderWidth: 1.5 },
  voucherLeft: { flexDirection: 'row', alignItems: 'center' },
  voucherText: { marginLeft: 10, fontSize: 15, fontWeight: '600', color: '#1F2937' },
  voucherRight: { flexDirection: 'row', alignItems: 'center' },
  voucherNote: { marginRight: 5, color: Colors.primary, fontSize: 13, fontWeight: '600' },
  cancelVoucherText: { color: '#EF4444', fontSize: 13, fontWeight: '700', paddingHorizontal: 4 },
  messageInput: { backgroundColor: '#fff', borderRadius: 12, borderWidth: 1, borderColor: '#E5E7EB', padding: 12, height: 80, textAlignVertical: 'top' },
  submitButton: { backgroundColor: Colors.primary, borderRadius: 16, height: 56, justifyContent: 'center', alignItems: 'center', marginTop: 10, marginBottom: 30 },
  submitButtonText: { color: '#fff', fontSize: 16, fontWeight: '700' },
});