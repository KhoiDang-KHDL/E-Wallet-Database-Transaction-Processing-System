// src/app/login.tsx
import { useRouter } from 'expo-router';
import { useState } from 'react';
import { Alert, Image, KeyboardAvoidingView, Platform, ScrollView, StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import { Button } from '../components/button';
import { InputField } from '../components/input_field';
import { setToken } from '../utils/auth_storage';

// Import cấu hình API thật từ file api.ts của bạn
import { API_URL } from '../utils/api';

export default function LoginScreen() {
  const router = useRouter();
  const [phone, setPhone] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);

  const handleLogin = async () => {
    // 1. Kiểm tra validation cơ bản phía Client
    if (!phone || !password) {
      Alert.alert('Thông báo', 'Vui lòng nhập đầy đủ Số điện thoại và Mật khẩu!');
      return;
    }
    
    setLoading(true);

    // 2. Chuẩn bị Request Payload khớp với Pydantic Model của Backend
    const requestPayload = {
      phone: phone,
      password: password,
    };
    
    // --- IN LOG CONSOLE: THEO DÕI REQUEST ---
    console.log('================ [API REQUEST] ================');
    console.log(`URL: ${API_URL}/auth/login`);
    console.log('Method: POST');
    console.log('Payload gửi đi:', JSON.stringify(requestPayload, null, 2));
    console.log('===============================================');

    // 3. Gọi API thật tới FastAPI Backend
    try {
      const response = await fetch(`${API_URL}/auth/login`, {
        method: 'POST',
        headers: { 
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: JSON.stringify(requestPayload),
      });

      const data = await response.json();

      // --- IN LOG CONSOLE: THEO DÕI RESPONSE ---
      console.log('================ [API RESPONSE] ================');
      console.log(`Status Code: ${response.status}`);
      console.log('Dữ liệu Backend trả về:', JSON.stringify(data, null, 2));
      console.log('================================================');

      if (response.ok) {
        // ĐĂNG NHẬP THÀNH CÔNG
        console.log('👉 Đăng nhập thành công! Token:', data.access_token);
        
        // CẤT TOKEN VÀO KHO LƯU TRỮ TẠM THỜI
        setToken(data.access_token); 
        
        // Điều hướng vào màn hình chính của App
        router.replace('/(tabs)');
      } else {
        // ĐĂNG NHẬP THẤT BẠI (Backend trả về lỗi 400, 401, 422...)
        // FastAPI mặc định trả lỗi qua trường 'detail'
        const errorMsg = data.detail || 'Số điện thoại hoặc mật khẩu không chính xác!';
        Alert.alert('Đăng nhập thất bại', errorMsg);
      }
    } catch (error) {
      // LỖI MẠNG HOẶC SAI IP
      console.error('Lỗi kết nối API:', error);
      Alert.alert(
        'Lỗi kết nối', 
        'Không thể kết nối tới máy chủ Backend.\n\nHãy chắc chắn rằng:\n1. Bạn đã sửa API_URL thành IPv4 máy tính.\n2. Điện thoại và máy tính chạy chung 1 cục Wi-Fi.'
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <KeyboardAvoidingView 
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'} 
      style={styles.container}
    >
      <ScrollView contentContainerStyle={styles.scrollContainer} showsVerticalScrollIndicator={false}>
        {/* Khu vực Logo / Header */}
        <View style={styles.logoContainer}>
          <Image
            source={require('../../assets/images/logo_app.png')}
            style={styles.logo}
            resizeMode="contain"
          />
          <Text style={styles.appName}>E-Wallet App</Text>
          <Text style={styles.appSubtitle}>Thanh toán nhanh chóng, an toàn</Text>
        </View>

        {/* Khu vực Form Nhập liệu */}
        <View style={styles.formContainer}>
            <InputField
                label="Số điện thoại"
                placeholder="Nhập số điện thoại của bạn"
                required
                keyboardType="phone-pad"
                value={phone}
                onChangeText={setPhone}
            />

            <InputField
                label="Mật khẩu"
                placeholder="Nhập mật khẩu"
                required
                isPassword={true} 
                value={password}
                onChangeText={setPassword}
            />

            <Button 
                title="ĐĂNG NHẬP" 
                onPress={handleLogin} 
                loading={loading}
                style={styles.loginButton}
            />

            {/* Link chuyển hướng sang màn hình Đăng ký */}
            <View style={styles.registerRedirectContainer}>
              <Text style={styles.registerRedirectText}>Chưa có tài khoản? </Text>
              <TouchableOpacity onPress={() => router.push('/register')}>
                <Text style={styles.registerActionText}>Đăng ký ngay</Text>
              </TouchableOpacity>
            </View>
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#ffffff' },
  scrollContainer: { flexGrow: 1, justifyContent: 'center', paddingHorizontal: 24 },
  logoContainer: { alignItems: 'center', marginBottom: 40 },
  logo: { width: 130, height: 130, marginBottom: 16 },
  appName: { fontSize: 24, fontWeight: '800', color: '#1F2937', marginBottom: 4 },
  appSubtitle: { fontSize: 14, color: '#6B7280' },
  formContainer: { width: '100%' },
  loginButton: { marginTop: 8, backgroundColor: '#2563EB' },
  registerRedirectContainer: { flexDirection: 'row', justifyContent: 'center', alignItems: 'center', marginTop: 24 },
  registerRedirectText: { fontSize: 14, color: '#6B7280' },
  registerActionText: { fontSize: 14, color: '#2563EB', fontWeight: '700' },
});