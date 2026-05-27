// src/app/_layout.tsx
import { Stack } from 'expo-router';
import { useEffect, useState } from 'react';
import { ActivityIndicator, StyleSheet, Text, View } from 'react-native';

// Biến toàn cục để lưu Token dùng xuyên suốt các trang mà không cần tạo Context
export let USER_TOKEN = { current: '' };
export const API_BASE_URL = 'http://10.0.2.2:8000'; // Đổi IP máy tính của bạn ở đây nếu test điện thoại thật

export default function RootLayout() {
  const [isServerOk, setIsServerOk] = useState<boolean | null>(null);

  useEffect(() => {
    // Gọi API /health của Backend để check nội bộ giữa Backend và Oracle DB
    const checkHealth = async () => {
      try {
        const response = await fetch(`${API_BASE_URL}/health`);
        const data = await response.json();
        if (response.ok && data.status === 'ok' && data.database === true) {
          setIsServerOk(true);
        } else {
          setIsServerOk(false);
        }
      } catch (error) {
        setIsServerOk(false);
      }
    };
    checkHealth();
  }, []);

  // 1. Trong lúc đợi API phản hồi (mấy mili-giây đầu), hiện vòng xoay loading chào mừng
  if (isServerOk === null) {
    return (
      <View style={styles.center}>
        <ActivityIndicator size="large" color="#2563EB" />
        <Text style={styles.text}>Đang kết nối hệ thống E-Wallet...</Text>
      </View>
    );
  }

  // 2. Nếu Backend hoặc Database Oracle chưa bật, chặn lại báo bảo trì luôn
  if (isServerOk === false) {
    return (
      <View style={styles.center}>
        <Text style={[styles.text, { fontWeight: '800', color: '#EF4444', fontSize: 18, marginBottom: 8 }]}>Hệ thống bảo trì</Text>
        <Text style={[styles.text, { textAlign: 'center', paddingHorizontal: 20, marginTop: 0 }]}>
          Không thể kết nối đến Máy chủ hoặc Database Oracle. Vui lòng bật Uvicorn và Oracle DB!
        </Text>
      </View>
    );
  }

  // 3. Nếu mọi thứ OK, mở cụm điều hướng Stack xịn sò của bạn ra để chuyển trang mượt mà
  return (
    <Stack screenOptions={{ headerShown: false }}>
      {/* Màn hình mặc định khi mở app là Đăng nhập */}
      <Stack.Screen name="login" options={{ title: 'Đăng Nhập' }} />
      <Stack.Screen name="register" options={{ title: 'Đăng ký' }} />
      <Stack.Screen name="register_pin" options={{ title: 'Tạo mã PIN' }} /> {/* Nhớ khai báo thêm trang PIN mới tạo nữa nha */}
      
      {/* Cụm điều hướng chính (Menu Đáy) */}
      <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
      
      {/* Các màn hình phụ dạng Stack đè lên trên */}
      <Stack.Screen name="settings" options={{ headerShown: true, title: 'Cài Đặt' }} />
      <Stack.Screen name="update_info" options={{ headerShown: true, title: 'Chỉnh sửa thông tin cá nhân' }} />
      <Stack.Screen name="update_pin1" options={{ headerShown: true, title: 'Thay đổi mã PIN' }} />
      <Stack.Screen name="update_pin2" options={{ headerShown: true, title: 'Thay đổi mã PIN' }} />
      <Stack.Screen name="update_password" options={{ headerShown: true, title: 'Thay đổi mật khẩu' }} />
      <Stack.Screen name="linked_methods" options={{ headerShown: true, title: 'Danh sách liên kết' }} />
      
      {/* Cụm các màn hình giao dịch */}
      <Stack.Screen name="(transaction)/transfer" options={{ headerShown: true, title: 'Chuyển Tiền' }} />
      <Stack.Screen name="(transaction)/deposit" options={{ headerShown: true, title: 'Nạp Tiền' }} />
      <Stack.Screen name="(transaction)/withdraw" options={{ headerShown: true, title: 'Rút Tiền' }} />
      <Stack.Screen name="(transaction)/confirm" options={{ headerShown: true, title: 'Xác Nhận Giao Dịch' }} />
      <Stack.Screen name="(transaction)/result" options={{ headerShown: false }} />
      <Stack.Screen name="(transaction)/my_qr" options={{ headerShown: false }} />
    </Stack>
  );
}

const styles = StyleSheet.create({
  center: { flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: '#ffffff' },
  text: { marginTop: 12, fontSize: 14, color: '#6B7280' },
});