// src/app/register_pin.tsx
import { Ionicons } from '@expo/vector-icons';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { useEffect, useRef, useState } from 'react';
import { ActivityIndicator, Alert, KeyboardAvoidingView, Platform, StyleSheet, Text, TextInput, TouchableOpacity, View } from 'react-native';

// IMPORT CẤU HÌNH API VÀ CHẾ ĐỘ MOCK DÙNG CHUNG
import { API_URL } from '../utils/api';
const LOGIN_ROUTE = '/login'; 

export default function RegisterPinScreen() {
  const router = useRouter();
  const params = useLocalSearchParams<{ fullName?: string; email?: string; phone?: string; password?: string }>();
  
  const [pin, setPin] = useState('');
  const [loading, setLoading] = useState(false);
  const inputRef = useRef<TextInput>(null);

  // Tự động mở bàn phím khi vào trang
  useEffect(() => {
    setTimeout(() => inputRef.current?.focus(), 500);
  }, []);

  // Tự động gọi API đăng ký khi người dùng gõ đủ 6 số PIN
  useEffect(() => {
    if (pin.length === 6) {
      handleCompleteRegister(pin);
    }
  }, [pin]);

  const handleCompleteRegister = async (completedPin: string) => {
    if (loading) return; 
    setLoading(true);

    const finalData = {
      full_name: params.fullName,
      email: params.email,
      phone: params.phone,
      password: params.password,
      pin_code: completedPin,
      currency: 'VND' 
    };

    try {
      const response = await fetch(`${API_URL}/auth/register`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(finalData),
      });

      const data = await response.json();

      console.log('================ [API REGISTER RESPONSE] ================');
      console.log(`Status Code: ${response.status}`);
      console.log('Dữ liệu trả về:', JSON.stringify(data, null, 2));
      console.log('=========================================================');

      if (response.ok) {
        Alert.alert('Thành công', 'Chúc mừng! Tài khoản ví của bạn đã được tạo thành công trên hệ thống.', [
          { text: 'Đăng nhập', onPress: () => router.replace(LOGIN_ROUTE as any) }
        ]);
      } else {
        setPin(''); // Xóa mã PIN gõ sai
        const errorMsg = data.detail || 'Đăng ký thất bại. Số điện thoại hoặc Email có thể đã tồn tại!';
        Alert.alert('Lỗi đăng ký', errorMsg);
      }
    } catch (error) {
      setPin('');
      console.error('Lỗi kết nối API Đăng ký:', error);
      Alert.alert('Lỗi kết nối', 'Không thể gửi yêu cầu đăng ký đến máy chủ Backend.');
    } finally {
      setLoading(false);
    }
  };

  const renderPinInputs = () => {
    const inputs = [];
    for (let i = 0; i < 6; i++) {
      const char = pin[i] || '';
      const isFocused = pin.length === i;
      inputs.push(
        <View key={i} style={[styles.pinBox, isFocused && styles.pinBoxFocused]}>
          <Text style={styles.pinText}>{char ? '●' : ''}</Text>
        </View>
      );
    }
    return inputs;
  };

  return (
    <KeyboardAvoidingView 
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'} 
      style={styles.container}
    >
      <View style={styles.header}>
        <TouchableOpacity style={styles.backButton} onPress={() => router.back()} disabled={loading}>
          <Ionicons name="arrow-back" size={24} color="#1F2937" />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Bảo mật tài khoản</Text>
        <View style={{ width: 32 }} />
      </View>

      <View style={styles.content}>
        <Text style={styles.title}>Tạo mã PIN ví</Text>
        <Text style={styles.subtitle}>
          Mã PIN gồm 6 số giúp bạn bảo mật tài khoản và xác thực nhanh chóng mỗi khi thực hiện chuyển, rút tiền.
        </Text>

        {/* Khu vực hiển thị mã PIN */}
        <TouchableOpacity 
          activeOpacity={1} 
          onPress={() => !loading && inputRef.current?.focus()} 
          style={styles.pinContainer}
        >
          {renderPinInputs()}
        </TouchableOpacity>

        {/* Ô input ẩn */}
        <TextInput
          ref={inputRef}
          value={pin}
          onChangeText={(val) => {
            if (val.length <= 6 && /^\d*$/.test(val)) setPin(val);
          }}
          keyboardType="number-pad"
          style={styles.hiddenInput}
          maxLength={6}
          editable={!loading}
        />

        {loading && (
          <View style={styles.loadingWrapper}>
            <ActivityIndicator size="small" color="#2563EB" />
            <Text style={styles.loadingText}>Hệ thống đang khởi tạo ví...</Text>
          </View>
        )}
      </View>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#ffffff' },
  // Style cho Header thanh điều hướng mới thêm
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingHorizontal: 16, height: 80, backgroundColor: '#ffffff', borderBottomWidth: 1, borderColor: '#E5E7EB', paddingTop: Platform.OS === 'ios' ? 0 : 20 },
  backButton: { padding: 4 },
  headerTitle: { fontSize: 17, fontWeight: '700', color: '#1F2937' },
  
  content: { flex: 1, paddingHorizontal: 24, justifyContent: 'center', alignItems: 'center', marginTop: -40 },
  title: { fontSize: 24, fontWeight: '800', color: '#1F2937', marginBottom: 12 },
  subtitle: { fontSize: 14, color: '#6B7280', textAlign: 'center', lineHeight: 20, marginBottom: 40, paddingHorizontal: 10 },
  pinContainer: { flexDirection: 'row', justifyContent: 'space-between', width: '100%', paddingHorizontal: 12, marginBottom: 30 },
  pinBox: { width: 44, height: 54, borderWidth: 2, borderColor: '#E5E7EB', borderRadius: 12, justifyContent: 'center', alignItems: 'center', backgroundColor: '#F9FAFB' },
  pinBoxFocused: { borderColor: '#2563EB', backgroundColor: '#EFF6FF' },
  pinText: { fontSize: 14, color: '#1F2937' },
  hiddenInput: { position: 'absolute', width: 1, height: 1, opacity: 0 },
  loadingWrapper: { flexDirection: 'row', alignItems: 'center', marginTop: 20 },
  loadingText: { marginLeft: 8, fontSize: 14, color: '#2563EB', fontWeight: '600' }
});