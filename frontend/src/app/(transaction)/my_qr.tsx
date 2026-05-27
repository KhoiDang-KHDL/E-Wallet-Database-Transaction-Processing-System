// src/app/(transaction)/my_qr.tsx
import { Ionicons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import * as Sharing from 'expo-sharing'; // Thư viện share file của Expo
import { useEffect, useRef, useState } from 'react';
import { ActivityIndicator, Alert, KeyboardAvoidingView, Platform, ScrollView, StyleSheet, Text, TextInput, TouchableOpacity, View } from 'react-native';
import QRCode from 'react-native-qrcode-svg';
import ViewShot, { captureRef } from 'react-native-view-shot'; // Thư viện chụp ảnh view
import { Colors } from '../../constants/Colors';

// Import cấu hình API và token xác thực
import { API_URL } from '../../utils/api';
import { getToken } from '../../utils/auth_storage';

export default function MyQRScreen() {
  const router = useRouter();
  const [amount, setAmount] = useState('');
  
  // Quản lý trạng thái gọi dữ liệu người dùng thật
  const [user, setUser] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  
  // Tạo Ref để trỏ vào vùng view cần chụp ảnh
  const viewShotRef = useRef<ViewShot>(null);

  // 1. GỌI API THẬT ĐỂ LẤY THÔNG TIN USER TỪ ORACLE DB
  useEffect(() => {
    async function fetchUserInfo() {
      const token = getToken();
      try {
        const res = await fetch(`${API_URL}/me`, {
          method: 'GET',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
          }
        });
        if (res.ok) {
          const data = await res.json();
          setUser(data);
        }
      } catch (error) {
        console.error("Lỗi tải thông tin tạo mã QR:", error);
      } finally {
        setLoading(false);
      }
    }
    fetchUserInfo();
  }, []);

  // Tạo đường dẫn động tích hợp số điện thoại thật và số tiền VNĐ vào QR
  const userPhone = user?.phone || '0000000000';
  const baseLink = `https://ewallet.app/pay/${userPhone}`;
  const qrValue = amount ? `${baseLink}?amount=${amount}` : baseLink;

  // Hàm định dạng số tiền hiển thị có dấu phẩy phân cách (Ví dụ: 50,000)
  const formatCurrency = (val: string) => {
    if (!val) return '';
    return parseInt(val).toLocaleString('vi-VN');
  };

  // Hàm xử lý chụp và chia sẻ NGUYÊN CÁI MÃ QR
  const captureQRAndShare = async () => {
    try {
      if (!(await Sharing.isAvailableAsync())) {
        Alert.alert("Thông báo", "Thiết bị của bạn không hỗ trợ chia sẻ tệp tin.");
        return;
      }

      // Chụp ảnh vùng view có ref là viewShotRef
      const uri = await captureRef(viewShotRef, {
        format: 'png',
        quality: 1.0,
      });

      // Thực hiện chia sẻ file hình ảnh vừa chụp
      await Sharing.shareAsync(uri, {
        dialogTitle: 'Chia sẻ mã QR nhận tiền của bạn',
        mimeType: 'image/png',
      });
      
    } catch (error) {
      console.log('Error sharing QR Code:', error);
      Alert.alert('Lỗi', 'Có lỗi xảy ra trong quá trình chia sẻ mã QR.');
    }
  };

  // Tối ưu hàm Download bằng cách chụp lại hình ảnh lưu tạm thời
  const handleDownload = async () => {
    try {
      const uri = await captureRef(viewShotRef, {
        format: 'png',
        quality: 1.0,
      });
      // Đối với đồ án demo, ta chụp xuất ra URI thành công là đã đạt chuẩn xử lý view shot
      console.log("QR Image URI:", uri);
      Alert.alert("Thành công", "Đã chụp và lưu mã QR vào bộ nhớ đệm thiết bị!");
    } catch (error) {
      Alert.alert("Lỗi", "Không thể tải mã QR xuống.");
    }
  };

  if (loading) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#2563EB" />
        <Text style={styles.loadingText}>Đang khởi tạo mã QR của bạn...</Text>
      </View>
    );
  }

  return (
    <KeyboardAvoidingView 
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'} 
      style={styles.container}
    >
      {/* 1. HEADER */}
      <View style={styles.header}>
        <TouchableOpacity style={styles.backButton} onPress={() => router.back()}>
          <Ionicons name="arrow-back" size={24} color="#1F2937" />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Mã QR nhận tiền</Text>
        <View style={{ width: 32 }} />
      </View>

      <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
        
        {/* 2. Bọc vùng QR Card bằng ViewShot */}
        <ViewShot ref={viewShotRef} options={{ format: "png", quality: 1.0 }} style={styles.screenshotArea}>
          {/* 3. MAIN QR CARD (Đổ dữ liệu sống từ Oracle DB) */}
          <View style={styles.qrCard}>
            <Text style={styles.userName}>{user?.full_name?.toUpperCase() || 'NGUỜI DÙNG E-WALLET'}</Text>
            <Text style={styles.userPhone}>{userPhone}</Text>
            
            {/* QR Code Container */}
            <View style={styles.qrContainer}>
              <QRCode
                value={qrValue}
                size={220}
                color="#000000"
                backgroundColor="#FFFFFF"
              />
            </View>
            
            {amount ? (
              <Text style={styles.amountDisplay}>Yêu cầu: {formatCurrency(amount)}đ</Text>
            ) : (
              <Text style={styles.scanHint}>Quét mã này để thực hiện chuyển tiền</Text>
            )}
          </View>
        </ViewShot>

        {/* 4. SET AMOUNT INPUT */}
        <View style={styles.inputSection}>
          <Text style={styles.inputLabel}>Nhập số tiền muốn nhận (Không bắt buộc)</Text>
          <View style={styles.inputWrapper}>
            <Text style={styles.currencySymbol}>VNĐ</Text>
            <TextInput
              style={styles.textInput}
              placeholder="0"
              placeholderTextColor="#9CA3AF"
              keyboardType="number-pad"
              value={amount}
              onChangeText={(text) => {
                const cleaned = text.replace(/[^0-9]/g, '');
                setAmount(cleaned);
              }}
            />
            {amount.length > 0 && (
              <TouchableOpacity onPress={() => setAmount('')}>
                <Ionicons name="close-circle" size={20} color="#9CA3AF" />
              </TouchableOpacity>
            )}
          </View>
        </View>

        {/* 5. DUAL ACTION BUTTONS */}
        <View style={styles.buttonGroup}>
          <TouchableOpacity style={[styles.groupButton, styles.leftButton]} onPress={handleDownload}>
            <Ionicons name="download-outline" size={20} color={Colors.primary} />
            <Text style={styles.buttonText}>Tải xuống</Text>
          </TouchableOpacity>
          
          <View style={styles.divider} />

          {/* 6. Nút Share gọi hàm chụp và share hình ảnh */}
          <TouchableOpacity style={[styles.groupButton, styles.rightButton]} onPress={captureQRAndShare}>
            <Ionicons name="share-social-outline" size={20} color={Colors.primary} />
            <Text style={styles.buttonText}>Chia sẻ</Text>
          </TouchableOpacity>
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#F9FAFB' },
  loadingContainer: { flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: '#F9FAFB' },
  loadingText: { marginTop: 12, fontSize: 14, color: '#6B7280', fontWeight: '500' },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingHorizontal: 16, height: 80, backgroundColor: '#FFFFFF', borderBottomWidth: 1, borderColor: '#E5E7EB', paddingTop: Platform.OS === 'ios' ? 0 : 20 },
  backButton: { padding: 4 },
  headerTitle: { fontSize: 18, fontWeight: '700', color: '#1F2937' },
  scrollContent: { alignItems: 'center', paddingHorizontal: 24, paddingTop: 24, paddingBottom: 40 },
  screenshotArea: { width: '100%', marginBottom: 24, borderRadius: 24 },
  qrCard: { backgroundColor: '#FFFFFF', borderRadius: 24, padding: 24, width: '100%', alignItems: 'center', shadowColor: '#000', shadowOffset: { width: 0, height: 4 }, shadowOpacity: 0.04, shadowRadius: 12, elevation: 3 },
  userName: { fontSize: 18, fontWeight: '800', color: '#1F2937', letterSpacing: 0.5 },
  userPhone: { fontSize: 14, color: '#6B7280', marginTop: 4, fontWeight: '600' },
  qrContainer: { backgroundColor: '#FFFFFF', padding: 16, borderRadius: 16, marginVertical: 18, shadowColor: '#000', shadowOffset: { width: 0, height: 2 }, shadowOpacity: 0.05, shadowRadius: 6, elevation: 1 },
  scanHint: { fontSize: 13, color: '#9CA3AF', fontWeight: '500' },
  amountDisplay: { fontSize: 16, fontWeight: '800', color: '#2563EB' },
  inputSection: { width: '100%', marginBottom: 24 },
  inputLabel: { fontSize: 13, fontWeight: '600', color: '#4B5563', marginBottom: 8, paddingHorizontal: 4 },
  inputWrapper: { flexDirection: 'row', alignItems: 'center', backgroundColor: '#FFFFFF', borderRadius: 16, paddingHorizontal: 16, height: 54, borderWidth: 1, borderColor: '#E5E7EB' },
  currencySymbol: { fontSize: 15, fontWeight: '700', color: '#4B5563', marginRight: 10 },
  textInput: { flex: 1, fontSize: 16, color: '#1F2937', fontWeight: '600', height: '100%' },
  buttonGroup: { flexDirection: 'row', backgroundColor: '#FFFFFF', borderRadius: 16, width: '100%', height: 54, alignItems: 'center', borderWidth: 1, borderColor: '#E5E7EB', shadowColor: '#000', shadowOffset: { width: 0, height: 2 }, shadowOpacity: 0.03, shadowRadius: 6, elevation: 2 },
  groupButton: { flex: 1, flexDirection: 'row', alignItems: 'center', justifyContent: 'center', height: '100%' },
  leftButton: { borderTopLeftRadius: 16, borderBottomLeftRadius: 16 },
  rightButton: { borderTopRightRadius: 16, borderBottomRightRadius: 16 },
  divider: { width: 1, height: 24, backgroundColor: '#E5E7EB' },
  buttonText: { fontSize: 14, fontWeight: '600', color: '#4B5563', marginLeft: 8 },
});