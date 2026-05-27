// src/app/update_pin2.tsx
import { useLocalSearchParams, useRouter } from 'expo-router';
import { useRef, useState } from 'react';
import { ActivityIndicator, Alert, KeyboardAvoidingView, Platform, StyleSheet, Text, TextInput, View } from 'react-native';

import { API_URL } from '../utils/api';
import { getToken } from '../utils/auth_storage';

export default function UpdatePinStep2Screen() {
  const router = useRouter();
  const { old_pin_code } = useLocalSearchParams<{ old_pin_code: string }>();

  const [submitting, setSubmitting] = useState(false);
  const [internalStep, setInternalStep] = useState<2 | 3>(2); // 2: Nhập mới, 3: Re-enter
  
  const [newPin, setNewPin] = useState(['', '', '', '', '', '']);
  const [confirmPin, setConfirmPin] = useState(['', '', '', '', '', '']);
  const pinInputRefs = useRef<Array<TextInput | null>>([]);

  const getCurrentPinArray = () => internalStep === 2 ? newPin : confirmPin;

  const handlePinChange = (text: string, index: number) => {
    const cleanText = text.replace(/[^0-9]/g, '');
    let currentPin = [...getCurrentPinArray()];
    currentPin[index] = cleanText;

    if (internalStep === 2) setNewPin(currentPin);
    else setConfirmPin(currentPin);

    if (cleanText && index < 5) {
      pinInputRefs.current[index + 1]?.focus();
    }

    const fullPinStr = currentPin.join('');
    if (fullPinStr.length === 6 && index === 5) {
      if (internalStep === 2) {
        setInternalStep(3);
        pinInputRefs.current[0]?.focus();
      } else {
        const newPinStr = newPin.join('');
        if (fullPinStr !== newPinStr) {
          Alert.alert("Lỗi xác nhận", "Mã PIN nhập lại không khớp! Vui lòng thử lại.");
          setConfirmPin(['', '', '', '', '', '']);
          pinInputRefs.current[0]?.focus();
          return;
        }
        handleCommitToOracle();
      }
    }
  };

  const handlePinKeyPress = (e: any, index: number) => {
    if (e.nativeEvent.key === 'Backspace' && index > 0 && !getCurrentPinArray()[index]) {
      pinInputRefs.current[index - 1]?.focus();
      let currentPin = [...getCurrentPinArray()];
      currentPin[index - 1] = '';
      if (internalStep === 2) setNewPin(currentPin);
      else setConfirmPin(currentPin);
    }
  };

  const handleCommitToOracle = async () => {
    setSubmitting(true);
    const token = getToken();
    try {
      const res = await fetch(`${API_URL}/wallet/update-pin`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({
          old_pin_code: old_pin_code,
          new_pin_code: newPin.join('')
        })
      });

      if (res.ok) {
        Alert.alert("Thành công", "Mã PIN an toàn đã được cập nhật thành công!");
        router.dismissAll(); // Dọn dẹp hết stack quay lại màn settings sạch sẽ
        router.replace('/settings');
      } else {
        const err = await res.json();
        Alert.alert("Thất bại", err.detail || "Có lỗi từ hệ thống database Oracle.");
        router.back(); // Nếu sai PIN gốc, đẩy quay ngược lại trang 1
      }
    } catch (error) {
      Alert.alert("Lỗi mạng", "Không thể kết nối cập nhật dữ liệu.");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : 'height'} style={styles.container}>

      <View style={styles.body}>
        <Text style={styles.stepTitle}>
          {internalStep === 2 ? "Tạo mã PIN mới" : "Xác nhận mã PIN mới"}
        </Text>
        <Text style={styles.stepSubtitle}>
          {internalStep === 2 ? "Vui lòng nhập dãy 6 chữ số PIN mới của ví" : "Gõ lại mã PIN mới tạo thêm một lần nữa"}
        </Text>

        <View style={styles.otpContainer}>
          {Array(6).fill(0).map((_, index) => {
            const currentArr = getCurrentPinArray();
            return (
              <TextInput
                key={index}
                style={styles.otpInput}
                keyboardType="number-pad"
                maxLength={1}
                secureTextEntry={true}
                value={currentArr[index] || ''}
                onChangeText={(text) => handlePinChange(text, index)}
                onKeyPress={(e) => handlePinKeyPress(e, index)}
                ref={(ref) => { pinInputRefs.current[index] = ref; }}
                autoFocus={index === 0}
              />
            );
          })}
        </View>

        {submitting && (
          <View style={styles.loaderBox}>
            <ActivityIndicator size="small" color="#2563EB" />
            <Text style={styles.loaderText}>Oracle đang thực hiện Procedure...</Text>
          </View>
        )}
      </View>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#F9FAFB' },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingHorizontal: 16, height: 80, backgroundColor: '#FFFFFF', borderBottomWidth: 1, borderColor: '#E5E7EB', paddingTop: Platform.OS === 'ios' ? 0 : 20 },
  backButton: { padding: 4 },
  headerTitle: { fontSize: 17, fontWeight: '700', color: '#1F2937' },
  body: { flex: 1, padding: 24, alignItems: 'center', paddingTop: 40 },
  stepTitle: { fontSize: 18, fontWeight: '800', color: '#1F2937', marginBottom: 8 },
  stepSubtitle: { fontSize: 13, color: '#6B7280', textAlign: 'center', marginBottom: 32, paddingHorizontal: 12, lineHeight: 18 },
  otpContainer: { flexDirection: 'row', justifyContent: 'space-between', width: '100%', paddingHorizontal: 4 },
  otpInput: { width: 44, height: 50, borderWidth: 1.5, borderColor: '#E5E7EB', borderRadius: 12, textAlign: 'center', fontSize: 20, fontWeight: '700', backgroundColor: '#FFFFFF', color: '#1F2937' },
  loaderBox: { flexDirection: 'row', alignItems: 'center', marginTop: 32 },
  loaderText: { marginLeft: 8, fontSize: 13, color: '#2563EB', fontWeight: '600' }
});