// src/app/update_password.tsx
import { Ionicons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import { useState } from 'react';
import { ActivityIndicator, Alert, KeyboardAvoidingView, Platform, ScrollView, StyleSheet, Text, TextInput, TouchableOpacity, View } from 'react-native';

import { API_URL } from '../utils/api';
import { getToken } from '../utils/auth_storage';

export default function UpdatePasswordScreen() {
  const router = useRouter();
  const [currentPassword, setCurrentPassword] = useState(''); 
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  
  const [secureOld, setSecureOld] = useState(true);
  const [secureNew, setSecureNew] = useState(true);
  const [secureConfirm, setSecureConfirm] = useState(true);
  const [submitting, setSubmitting] = useState(false);

  const handleUpdatePasswordAPI = async () => {
    if (!currentPassword || !newPassword || !confirmPassword) {
      Alert.alert("Thông báo", "Vui lòng nhập đầy đủ các trường thông tin mật khẩu!");
      return;
    }
    if (newPassword !== confirmPassword) {
      Alert.alert("Lỗi xác nhận", "Mật khẩu mới và xác nhận mật khẩu không trùng khớp!");
      return;
    }
    if (newPassword.length < 6) {
      Alert.alert("Thông báo", "Mật khẩu mới phải có độ dài từ 6 ký tự trở lên!");
      return;
    }

    setSubmitting(true);
    const token = getToken();
    try {
      // Gọi đến đúng endpoint @router.put("/password") của nhóm bạn
      const res = await fetch(`${API_URL}/profile/password`, { 
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({
          current_password: currentPassword, 
          new_password: newPassword
        })
      });

      if (res.ok) {
        Alert.alert("Thành công", "Mật khẩu đăng nhập đã được thay đổi thành công!");
        router.back();
      } else {
        const err = await res.json();
        Alert.alert("Thất bại", err.detail || "Mật khẩu hiện tại không chính xác.");
      }
    } catch (error) {
      Alert.alert("Lỗi", "Không thể kết nối máy chủ đổi mật khẩu.");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : 'height'} style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity style={styles.backButton} onPress={() => router.back()}>
          <Ionicons name="arrow-back" size={24} color="#1F2937" />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Đổi mật khẩu đăng nhập</Text>
        <View style={{ width: 32 }} />
      </View>

      <ScrollView contentContainerStyle={styles.subScreenBody} keyboardShouldPersistTaps="handled">
        <Text style={styles.stepTitle}>Cập nhật mật khẩu mới</Text>
        <Text style={styles.stepSubtitle}>Mật khẩu mạnh bảo vệ an toàn cho tài khoản ví điện tử khỏi đăng nhập lạ.</Text>

        <Text style={styles.inputLabel}>Mật khẩu hiện tại</Text>
        <View style={styles.passwordInputWrapper}>
          <TextInput
            style={styles.passwordInput}
            placeholder="Nhập mật khẩu cũ"
            placeholderTextColor="#9CA3AF"
            secureTextEntry={secureOld}
            value={currentPassword}
            onChangeText={setCurrentPassword}
          />
          <TouchableOpacity onPress={() => setSecureOld(!secureOld)}>
            <Ionicons name={secureOld ? "eye-off-outline" : "eye-outline"} size={20} color="#9CA3AF" />
          </TouchableOpacity>
        </View>

        <Text style={styles.inputLabel}>Mật khẩu đăng nhập mới</Text>
        <View style={styles.passwordInputWrapper}>
          <TextInput
            style={styles.passwordInput}
            placeholder="Tối thiểu 6 chữ hoặc số"
            placeholderTextColor="#9CA3AF"
            secureTextEntry={secureNew}
            value={newPassword}
            onChangeText={setNewPassword}
          />
          <TouchableOpacity onPress={() => setSecureNew(!secureNew)}>
            <Ionicons name={secureNew ? "eye-off-outline" : "eye-outline"} size={20} color="#9CA3AF" />
          </TouchableOpacity>
        </View>

        <Text style={styles.inputLabel}>Xác nhận mật khẩu mới</Text>
        <View style={styles.passwordInputWrapper}>
          <TextInput
            style={styles.passwordInput}
            placeholder="Gõ lại mật khẩu mới"
            placeholderTextColor="#9CA3AF"
            secureTextEntry={secureConfirm}
            value={confirmPassword}
            onChangeText={setConfirmPassword}
          />
          <TouchableOpacity onPress={() => setSecureConfirm(!secureConfirm)}>
            <Ionicons name={secureConfirm ? "eye-off-outline" : "eye-outline"} size={20} color="#9CA3AF" />
          </TouchableOpacity>
        </View>

        <TouchableOpacity 
          style={[styles.submitButton, submitting && { opacity: 0.7 }]} 
          onPress={handleUpdatePasswordAPI}
          disabled={submitting}
        >
          {submitting ? <ActivityIndicator color="#FFFFFF" /> : <Text style={styles.submitButtonText}>Cập nhật mật khẩu</Text>}
        </TouchableOpacity>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#F9FAFB' },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingHorizontal: 16, height: 80, backgroundColor: '#FFFFFF', borderBottomWidth: 1, borderColor: '#E5E7EB', paddingTop: Platform.OS === 'ios' ? 0 : 20 },
  backButton: { padding: 4 },
  headerTitle: { fontSize: 17, fontWeight: '700', color: '#1F2937' },
  subScreenBody: { padding: 24, alignItems: 'center', paddingTop: 30 },
  stepTitle: { fontSize: 18, fontWeight: '800', color: '#1F2937', marginBottom: 8, textAlign: 'center' },
  stepSubtitle: { fontSize: 13, color: '#6B7280', textAlign: 'center', marginBottom: 32, paddingHorizontal: 12, lineHeight: 18 },
  inputLabel: { width: '100%', fontSize: 13, fontWeight: '600', color: '#4B5563', marginBottom: 8, marginTop: 14, paddingHorizontal: 2 },
  passwordInputWrapper: { flexDirection: 'row', alignItems: 'center', backgroundColor: '#FFFFFF', borderRadius: 14, paddingHorizontal: 14, height: 50, borderWidth: 1, borderColor: '#E5E7EB', width: '100%' },
  passwordInput: { flex: 1, fontSize: 14, color: '#1F2937', fontWeight: '500', height: '100%' },
  submitButton: { backgroundColor: '#2563EB', borderRadius: 16, height: 50, justifyContent: 'center', alignItems: 'center', width: '100%', marginTop: 32 },
  submitButtonText: { color: '#FFFFFF', fontSize: 15, fontWeight: '700' }
});