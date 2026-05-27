// src/app/update_info.tsx
import { Ionicons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import { useEffect, useState } from 'react';
import { ActivityIndicator, Alert, KeyboardAvoidingView, Platform, ScrollView, StyleSheet, Text, TextInput, TouchableOpacity, View } from 'react-native';

import { API_URL } from '../utils/api';
import { getToken } from '../utils/auth_storage';

export default function UpdateInfoScreen() {
  const router = useRouter();

  // Quản lý dữ liệu người dùng
  const [fullName, setFullName] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);

  const token = getToken();
  const headers = {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`
  };

  // 1. Tải thông tin hiện tại của tài khoản để hiển thị lên form
  useEffect(() => {
    async function fetchCurrentProfile() {
      try {
        const res = await fetch(`${API_URL}/me`, { method: 'GET', headers });
        if (res.ok) {
          const data = await res.json();
          setFullName(data.full_name || '');
          setEmail(data.email || '');
          setPhone(data.phone || '');
        }
      } catch (error) {
        console.error("Lỗi tải profile thông tin:", error);
      } finally {
        setLoading(false);
      }
    }
    fetchCurrentProfile();
  }, []);

  // 2. Gọi API PUT gửi cấu hình thay đổi lên Oracle DB
  const handleUpdateProfile = async () => {
    if (!fullName.trim() && !email.trim() && !phone.trim()) {
      Alert.alert("Thông báo", "Vui lòng không để trống tất cả các trường thông tin!");
      return;
    }

    setSubmitting(true);
    try {
      // Gọi đúng endpoint định tuyến @router.put("") của bạn
      const res = await fetch(`${API_URL}/me`, { // Kiểm tra lại tiền tố route gốc của bạn (ví dụ /profile hoặc /users)
        method: 'PUT',
        headers,
        body: JSON.stringify({
          full_name: fullName.trim() || null,
          email: email.trim() || null,
          phone: phone.trim() || null,
        })
      });

      const data = await res.json();

      if (res.ok) {
        Alert.alert("Thành công", "Thông tin cá nhân tài khoản đã được cập nhật!");
        router.back(); // Quay về màn hình cấu hình trước đó
      } else {
        Alert.alert("Thất bại", data.detail || "Không thể cập nhật thông tin.");
      }
    } catch (error) {
      Alert.alert("Lỗi kết nối", "Không thể gửi yêu cầu chỉnh sửa đến máy chủ.");
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#2563EB" />
        <Text style={styles.loadingText}>Đang lấy dữ liệu hồ sơ...</Text>
      </View>
    );
  }

  return (
    <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : 'height'} style={styles.container}>

      <ScrollView contentContainerStyle={styles.body} keyboardShouldPersistTaps="handled">
        <Text style={styles.stepTitle}>Cập nhật thông tin cá nhân</Text>
        <Text style={styles.stepSubtitle}>Chỉnh sửa các trường thông tin bên dưới để đồng bộ hồ sơ ví thành viên của bạn.</Text>

        {/* TRƯỜNG HỌ TÊN */}
        <Text style={styles.inputLabel}>Họ và tên</Text>
        <View style={styles.inputWrapper}>
          <Ionicons name="person-outline" size={18} color="#9CA3AF" style={{ marginRight: 10 }} />
          <TextInput
            style={styles.textInput}
            placeholder="Nhập họ và tên của bạn"
            placeholderTextColor="#9CA3AF"
            value={fullName}
            onChangeText={setFullName}
          />
        </View>

        {/* TRƯỜNG EMAIL */}
        <Text style={styles.inputLabel}>Địa chỉ Email</Text>
        <View style={styles.inputWrapper}>
          <Ionicons name="mail-outline" size={18} color="#9CA3AF" style={{ marginRight: 10 }} />
          <TextInput
            style={styles.textInput}
            placeholder="example@domain.com"
            placeholderTextColor="#9CA3AF"
            keyboardType="email-address"
            autoCapitalize="none"
            value={email}
            onChangeText={setEmail}
          />
        </View>

        {/* TRƯỜNG SỐ ĐIỆN THOẠI */}
        <Text style={styles.inputLabel}>Số điện thoại</Text>
        <View style={styles.inputWrapper}>
          <Ionicons name="phone-portrait-outline" size={18} color="#9CA3AF" style={{ marginRight: 10 }} />
          <TextInput
            style={styles.textInput}
            placeholder="Nhập số điện thoại đăng ký"
            placeholderTextColor="#9CA3AF"
            keyboardType="phone-pad"
            value={phone}
            onChangeText={setPhone}
          />
        </View>

        {/* NÚT XÁC NHẬN */}
        <TouchableOpacity 
          style={[styles.submitButton, submitting && { opacity: 0.7 }]} 
          onPress={handleUpdateProfile}
          disabled={submitting}
        >
          {submitting ? (
            <ActivityIndicator color="#FFFFFF" />
          ) : (
            <Text style={styles.submitButtonText}>Lưu thay đổi</Text>
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
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingHorizontal: 16, height: 80, backgroundColor: '#FFFFFF', borderBottomWidth: 1, borderColor: '#E5E7EB', paddingTop: Platform.OS === 'ios' ? 0 : 20 },
  backButton: { padding: 4 },
  headerTitle: { fontSize: 17, fontWeight: '700', color: '#1F2937' },
  body: { padding: 24, alignItems: 'center', paddingTop: 30 },
  stepTitle: { fontSize: 18, fontWeight: '800', color: '#1F2937', marginBottom: 8, textAlign: 'center' },
  stepSubtitle: { fontSize: 13, color: '#6B7280', textAlign: 'center', marginBottom: 24, paddingHorizontal: 12, lineHeight: 18 },
  inputLabel: { width: '100%', fontSize: 13, fontWeight: '600', color: '#4B5563', marginBottom: 8, marginTop: 14, paddingHorizontal: 2 },
  inputWrapper: { flexDirection: 'row', alignItems: 'center', backgroundColor: '#FFFFFF', borderRadius: 14, paddingHorizontal: 14, height: 50, borderWidth: 1, borderColor: '#E5E7EB', width: '100%' },
  textInput: { flex: 1, fontSize: 14, color: '#1F2937', fontWeight: '500', height: '100%' },
  submitButton: { backgroundColor: '#2563EB', borderRadius: 16, height: 50, justifyContent: 'center', alignItems: 'center', width: '100%', marginTop: 36 },
  submitButtonText: { color: '#FFFFFF', fontSize: 15, fontWeight: '700' }
});