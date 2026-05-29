// src/app/register.tsx
import { useRouter } from 'expo-router';
import { useState } from 'react';
import { Image, KeyboardAvoidingView, Platform, ScrollView, StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import { Button } from '../components/button';
import { InputField } from '../components/input_field';

export default function RegisterScreen() {
  const router = useRouter();
  const [fullName, setFullName] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [loading, setLoading] = useState(false);

  const handleRegister = () => {
    // 1. Kiểm tra validation cơ bản
    if (!fullName || !email || !phone || !password || !confirmPassword) {
      alert('Vui lòng nhập đầy đủ tất cả các thông tin!');
      return;
    }

    // Kiểm tra định dạng Email cơ bản bằng Regex
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      alert('Định dạng email không hợp lệ!');
      return;
    }

    if (password !== confirmPassword) {
      alert('Mật khẩu xác nhận không trùng khớp!');
      return;
    }

    if (password.length < 6) {
      alert('Mật khẩu phải có ít nhất 6 ký tự!');
      return;
    }
    
    // BẬT LOGIC ĐIỀU HƯỚNG MỚI: 
    router.push({
      pathname: '/register_pin',
      // THÊM email VÀO PARAMS ĐỂ TRUYỀN SANG TRANG SAU
      params: { fullName, email, phone, password } 
    });
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
          <Text style={styles.appName}>Đăng Ký Tài Khoản</Text>
          <Text style={styles.appSubtitle}>Khởi đầu trải nghiệm thanh toán thông minh</Text>
        </View>

        {/* Khu vực Form Nhập liệu */}
        <View style={styles.formContainer}>
            <InputField
                label="Họ và tên"
                placeholder="Nhập họ và tên của bạn"
                required
                value={fullName}
                onChangeText={setFullName}
            />

            {/* ---> THÊM Ô NHẬP LIỆU EMAIL VÀO ĐÂY <--- */}
            <InputField
                label="Địa chỉ Email"
                placeholder="example@gmail.com"
                required
                keyboardType="email-address"
                autoCapitalize="none"
                value={email}
                onChangeText={setEmail}
            />

            <InputField
                label="Số điện thoại"
                placeholder="Nhập số điện thoại đăng ký"
                required
                keyboardType="phone-pad"
                value={phone}
                onChangeText={setPhone}
            />

            <InputField
                label="Mật khẩu"
                placeholder="Tạo mật khẩu (tối thiểu 6 ký tự)"
                required
                isPassword={true} 
                value={password}
                onChangeText={setPassword}
            />

            <InputField
                label="Xác nhận mật khẩu"
                placeholder="Nhập lại mật khẩu"
                required
                isPassword={true} 
                value={confirmPassword}
                onChangeText={setConfirmPassword}
            />

            <Button 
                title="TIẾP TỤC (TẠO MÃ PIN)" 
                onPress={handleRegister} 
                loading={loading}
                style={styles.registerButton}
            />

            {/* Điều hướng quay lại Đăng nhập nếu đã có tài khoản */}
            <View style={styles.loginRedirectContainer}>
              <Text style={styles.loginRedirectText}>Bạn đã có tài khoản? </Text>
              <TouchableOpacity onPress={() => router.push('/login')}>
                <Text style={styles.loginActionText}>Đăng nhập</Text>
              </TouchableOpacity>
            </View>
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#ffffff',
  },
  scrollContainer: {
    flexGrow: 1,
    justifyContent: 'center',
    paddingHorizontal: 24,
    paddingVertical: 40,
  },
  logoContainer: {
    alignItems: 'center',
    marginBottom: 32,
  },
  logo: {
    width: 100,
    height: 100,
    marginBottom: 12,
  },
  appName: {
    fontSize: 24,
    fontWeight: '800',
    color: '#1F2937',
    marginBottom: 4,
  },
  appSubtitle: {
    fontSize: 14,
    color: '#6B7280',
    textAlign: 'center',
  },
  formContainer: {
    width: '100%',
  },
  registerButton: {
    marginTop: 16,
    backgroundColor: '#2563EB'
  },
  loginRedirectContainer: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: 24,
  },
  loginRedirectText: {
    fontSize: 14,
    color: '#6B7280',
  },
  loginActionText: {
    fontSize: 14,
    color: '#2563EB',
    fontWeight: '700',
  },
});