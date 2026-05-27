// src/app/(transaction)/withdraw.tsx
import { Ionicons } from '@expo/vector-icons';
import { useLocalSearchParams, useNavigation, useRouter } from 'expo-router';
import { useEffect, useState } from 'react';
import { ActivityIndicator, Alert, BackHandler, KeyboardAvoidingView, Platform, ScrollView, StyleSheet, Text, TextInput, TouchableOpacity, View } from 'react-native';
import { Colors } from '../../../src/constants/Colors';

// Import cấu hình API và token xác thực
import { API_URL } from '../../utils/api';
import { getToken } from '../../utils/auth_storage';

const QUICK_AMOUNTS = ['100000', '200000', '500000', '1000000'];

export default function WithdrawScreen() {
  const router = useRouter();
  const navigation = useNavigation();

  // Đón nhận dữ liệu đồng bộ nếu có đi qua màn hình phụ
  const searchParams = useLocalSearchParams<{ voucher_code?: string; amount?: string }>();

  // Quản lý dữ liệu thật từ Oracle DB
  const [bankMethods, setBankMethods] = useState<any[]>([]);
  const [selectedBank, setSelectedBank] = useState<any>(null);
  const [loadingBanks, setLoadingBanks] = useState(true);

  const [amount, setAmount] = useState('');
  const [showBankList, setShowBankList] = useState(false);
  const [estimating, setEstimating] = useState(false);

  // 🌟 1. CỐ ĐỊNH LUỒNG ĐIỀU HƯỚNG BACK PHI THẲNG VỀ HOME
  useEffect(() => {
    navigation.setOptions({
      headerLeft: () => (
        <TouchableOpacity onPress={() => router.replace('/(tabs)')} style={{ padding: 8, marginLeft: -8 }}>
          <Ionicons name="arrow-back" size={24} color="#1F2937" />
        </TouchableOpacity>
      ),
    });

    const backAction = () => {
      router.replace('/(tabs)');
      return true;
    };

    const backHandler = BackHandler.addEventListener('hardwareBackPress', backAction);
    return () => backHandler.remove();
  }, [navigation]);

  // Đồng bộ số tiền cũ nếu có quay lại từ màn hình khác
  useEffect(() => {
    if (searchParams.amount) {
      setAmount(searchParams.amount);
    }
  }, [searchParams.amount]);

  const token = getToken();
  const headers = {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`
  };

  // 🌟 2. LẤY TÀI KHOẢN NGÂN HÀNG NHẬN TIỀN THẬT TỪ DATABASE ORACLE
  useEffect(() => {
    async function fetchPaymentMethods() {
      try {
        const res = await fetch(`${API_URL}/payment-methods`, { method: 'GET', headers });
        if (res.ok) {
          const data = await res.json();
          // Chỉ lấy ngân hàng đang hoạt động để rút tiền về
          const activeMethods = Array.isArray(data) ? data.filter((m: any) => m.is_active) : [];
          setBankMethods(activeMethods);
          
          if (activeMethods.length > 0) {
            setSelectedBank(activeMethods[0]);
          }
        }
      } catch (error) {
        console.error("🔴 Lỗi tải danh sách ngân hàng rút tiền:", error);
      } finally {
        setLoadingBanks(false);
      }
    }
    fetchPaymentMethods();
  }, []);

  const formatCurrency = (val: string) => {
    if (!val) return '0';
    return parseInt(val).toLocaleString('vi-VN');
  };

  // 🌟 3. CHE SỐ TÀI KHOẢN AN TOÀN TRÊN UI
  const maskBankAccount = (accountNumber: string | number) => {
    if (!accountNumber) return '•••• ••••';
    const str = accountNumber.toString().replace(/\s/g, '');
    if (str.length <= 4) return str;
    const lastFourDigits = str.slice(-4);
    return `•••• ${lastFourDigits}`;
  };

  const getBankColor = (providerName: string) => {
    const name = providerName?.toLowerCase() || '';
    if (name.includes('vietcombank') || name.includes('vcb')) return '#2563EB';
    if (name.includes('techcombank') || name.includes('tcb')) return '#EF4444';
    if (name.includes('vietinbank')) return '#0284C7';
    return '#4B5563';
  };

  // 🌟 4. GỌI ESTIMATE TÍNH PHÍ RÚT VÀ ĐẨY SANG CONFIRM
  const handleNext = async () => {
    if (!selectedBank) {
      Alert.alert('Thông báo', 'Vui lòng liên kết ngân hàng trước khi thực hiện rút tiền!');
      return;
    }

    if (!amount || parseInt(amount) <= 0) {
      Alert.alert('Thông báo', 'Vui lòng nhập số tiền hợp lệ!');
      return;
    }

    const numAmount = parseInt(amount);
    if (numAmount < 10000) {
      Alert.alert('Thông báo', 'Số tiền rút tối thiểu là 10.000 VNĐ');
      return;
    }

    setEstimating(true);

    try {
      // Gọi API estimate tính toán phí rút tiền thực tế từ Oracle
      const res = await fetch(`${API_URL}/transactions/estimate`, {
        method: 'POST',
        headers,
        body: JSON.stringify({
          type_code: "WITHDRAW",
          amount: numAmount,
          voucher_code: null // Nghiệp vụ rút tiền mặc định không xài voucher
        })
      });

      const estimateData = await res.json();

      if (res.ok) {
        // Sinh ngẫu nhiên mã idempotency_key cho phiên rút tiền
        const randomIdempotencyKey = `withdraw_${Date.now()}_${Math.floor(Math.random() * 1000)}`;

        router.push({
          pathname: "/(transaction)/confirm",
          params: {
            type: 'withdraw',
            amount: estimateData.amount.toString(),
            fee_amount: estimateData.fee_amount.toString(),
            discount_amount: estimateData.discount_amount.toString(),
            net_fee: estimateData.net_fee.toString(),
            total_deduct: estimateData.total_deduct.toString(), // Tổng tiền ví sẽ bị trừ (Tiền rút + Phí)
            bank: selectedBank.provider_name,
            method_id: selectedBank.method_id.toString(), // Gửi method_id thật xuống sp_withdraw_request
            idempotency_key: randomIdempotencyKey,
            description: `Rut tien ve tai khoan ${selectedBank.provider_name}`
          }
        });
      } else {
        Alert.alert('Lỗi hệ thống', estimateData.detail || 'Không thể ước tính giao dịch rút tiền.');
      }
    } catch (error) {
      Alert.alert('Lỗi kết nối', 'Không thể kết nối đến máy chủ Backend.');
    } finally {
      setEstimating(false);
    }
  };

  if (loadingBanks) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#2563EB" />
        <Text style={styles.loadingText}>Đang kiểm tra tài khoản liên kết...</Text>
      </View>
    );
  }

  return (
    <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : 'height'} style={styles.container}>
      <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
        
        {/* SECTION 1: BANK SELECTION */}
        <Text style={styles.sectionLabel}>Rút về tài khoản ngân hàng</Text>
        {bankMethods.length === 0 ? (
          <TouchableOpacity style={styles.noBankCard} onPress={() => router.push('../linked_methods')}>
            <Ionicons name="add-circle-outline" size={24} color="#2563EB" />
            <Text style={styles.noBankText}>Chưa có tài khoản nhận tiền. Bấm liên kết ngay!</Text>
          </TouchableOpacity>
        ) : (
          <>
            <TouchableOpacity 
              style={styles.bankCard} 
              onPress={() => setShowBankList(!showBankList)}
              activeOpacity={0.8}
            >
              <View style={styles.bankInfoLeft}>
                <View style={styles.bankIconBg}>
                  <Ionicons name="business" size={24} color={getBankColor(selectedBank?.provider_name)} />
                </View>
                <View>
                  <Text style={styles.bankName}>{selectedBank?.provider_name}</Text>
                  <Text style={styles.bankDetail}>{maskBankAccount(selectedBank?.masked_number)}</Text>
                </View>
              </View>
              <Ionicons name={showBankList ? "chevron-up" : "chevron-down"} size={20} color="#9CA3AF" />
            </TouchableOpacity>

            {/* BANK DROPDOWN */}
            {showBankList && (
              <View style={styles.bankDropdown}>
                {bankMethods.map((bank) => {
                  const isCurrent = bank.method_id === selectedBank?.method_id;
                  return (
                    <TouchableOpacity
                      key={bank.method_id}
                      style={[styles.dropdownItem, isCurrent && styles.activeDropdownItem]}
                      onPress={() => {
                        setSelectedBank(bank);
                        setShowBankList(false);
                      }}
                    >
                      <View style={styles.bankInfoLeft}>
                        <View style={styles.bankIconBg}>
                          <Ionicons name="business" size={20} color={getBankColor(bank.provider_name)} />
                        </View>
                        <View>
                          <Text style={styles.bankName}>{bank.provider_name}</Text>
                          <Text style={styles.bankDetail}>{maskBankAccount(bank.masked_number)}</Text>
                        </View>
                      </View>
                      {isCurrent && <Ionicons name="checkmark" size={20} color={Colors.primary} />}
                    </TouchableOpacity>
                  );
                })}
              </View>
            )}
          </>
        )}

        {/* SECTION 2: AMOUNT INPUT */}
        <Text style={styles.sectionLabel}>Số tiền muốn rút</Text>
        <View style={styles.amountInputBox}>
          <View style={styles.inputWrapper}>
            <TextInput
              style={styles.textInput}
              placeholder="0"
              placeholderTextColor="#9CA3AF"
              keyboardType="number-pad"
              value={amount}
              onChangeText={(text) => setAmount(text.replace(/[^0-9]/g, ''))}
            />
            <Text style={styles.currencySuffix}>VNĐ</Text>
          </View>
          {amount.length > 0 && (
            <TouchableOpacity style={styles.clearButton} onPress={() => setAmount('')}>
              <Text style={styles.clearText}>Xóa</Text>
            </TouchableOpacity>
          )}
        </View>

        {/* QUICK AMOUNTS */}
        <View style={styles.quickAmountGrid}>
          {QUICK_AMOUNTS.map((item) => (
            <TouchableOpacity key={item} style={styles.quickActionItem} onPress={() => setAmount(item)}>
              <Text style={styles.quickActionText}>+{formatCurrency(item)}đ</Text>
            </TouchableOpacity>
          ))}
        </View>

        {/* SUBMIT BUTTON */}
        <TouchableOpacity 
          style={[styles.submitButton, estimating && { opacity: 0.7 }]} 
          onPress={handleNext}
          disabled={estimating || bankMethods.length === 0}
        >
          {estimating ? (
            <ActivityIndicator color="#FFFFFF" />
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
  loadingContainer: { flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: '#F9FAFB' },
  loadingText: { marginTop: 12, fontSize: 14, color: '#6B7280', fontWeight: '500' },
  scrollContent: { paddingHorizontal: 20, paddingTop: 24 },
  sectionLabel: { fontSize: 13, fontWeight: '600', color: '#4B5563', marginBottom: 10, paddingHorizontal: 2 },
  bankCard: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', backgroundColor: '#FFFFFF', padding: 16, borderRadius: 16, borderWidth: 1, borderColor: '#E5E7EB', marginBottom: 24 },
  noBankCard: { flexDirection: 'row', justifyContent: 'center', alignItems: 'center', backgroundColor: '#EFF6FF', padding: 18, borderRadius: 16, borderWidth: 1, borderStyle: 'dashed', borderColor: '#2563EB', marginBottom: 24 },
  noBankText: { marginLeft: 8, color: '#2563EB', fontSize: 14, fontWeight: '600' },
  bankInfoLeft: { flexDirection: 'row', alignItems: 'center' },
  bankIconBg: { width: 44, height: 44, borderRadius: 12, backgroundColor: '#F3F4F6', justifyContent: 'center', alignItems: 'center', marginRight: 14 },
  bankName: { fontSize: 15, fontWeight: '600', color: '#1F2937' },
  bankDetail: { fontSize: 13, color: '#9CA3AF', marginTop: 2 },
  bankDropdown: { backgroundColor: '#FFFFFF', borderRadius: 16, borderWidth: 1, borderColor: '#E5E7EB', paddingHorizontal: 8, marginBottom: 24, shadowColor: '#000', shadowOffset: { width: 0, height: 2 }, shadowOpacity: 0.02, shadowRadius: 4, elevation: 2, maxHeight: 200 },
  dropdownItem: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', padding: 12, borderRadius: 12, marginVertical: 4 },
  activeDropdownItem: { backgroundColor: '#F3F4F6' },
  amountInputBox: { backgroundColor: '#FFFFFF', borderRadius: 16, paddingHorizontal: 16, paddingVertical: 12, borderWidth: 1, borderColor: '#E5E7EB', marginBottom: 16, flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  inputWrapper: { flexDirection: 'row', alignItems: 'center', flex: 1 },
  textInput: { fontSize: 24, fontWeight: '700', color: '#1F2937', flex: 1, padding: 0 },
  currencySuffix: { fontSize: 16, fontWeight: '700', color: '#4B5563', marginLeft: 8 },
  clearButton: { backgroundColor: '#F3F4F6', paddingVertical: 6, paddingHorizontal: 10, borderRadius: 8 },
  clearText: { fontSize: 12, color: '#6B7280', fontWeight: '600' },
  quickAmountGrid: { flexDirection: 'row', flexWrap: 'wrap', justifyContent: 'space-between', marginBottom: 32 },
  quickActionItem: { backgroundColor: '#FFFFFF', borderWidth: 1, borderColor: '#E5E7EB', borderRadius: 12, width: '48%', paddingVertical: 14, alignItems: 'center', marginBottom: 12 },
  quickActionText: { fontSize: 14, fontWeight: '600', color: '#4B5563' },
  submitButton: { backgroundColor: Colors.primary, borderRadius: 16, height: 54, justifyContent: 'center', alignItems: 'center', marginTop: 10 },
  submitButtonText: { color: '#FFFFFF', fontSize: 16, fontWeight: '700' },
});