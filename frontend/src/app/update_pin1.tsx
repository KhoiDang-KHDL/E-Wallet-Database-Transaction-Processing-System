// src/app/update_pin1.tsx
import { useRouter } from 'expo-router';
import { useRef, useState } from 'react';
import { ActivityIndicator, KeyboardAvoidingView, Platform, StyleSheet, Text, TextInput, View } from 'react-native';

export default function UpdatePinStep1Screen() {
  const router = useRouter();
  const [oldPin, setOldPin] = useState(['', '', '', '', '', '']);
  const [submitting, setSubmitting] = useState(false);
  const pinInputRefs = useRef<Array<TextInput | null>>([]);

  const handlePinChange = (text: string, index: number) => {
    const cleanText = text.replace(/[^0-9]/g, '');
    let currentPin = [...oldPin];
    currentPin[index] = cleanText;
    setOldPin(currentPin);

    if (cleanText && index < 5) {
      pinInputRefs.current[index + 1]?.focus();
    }

    const fullPinStr = currentPin.join('');
    if (fullPinStr.length === 6 && index === 5) {
      setSubmitting(true);
      setTimeout(() => {
        setSubmitting(false);
        // Chuyển sang màn hình update_pin2 kèm theo mã pin cũ trên URL
        router.push({
          pathname: '/update_pin2',
          params: { old_pin_code: fullPinStr }
        });
      }, 600);
    }
  };

  const handlePinKeyPress = (e: any, index: number) => {
    if (e.nativeEvent.key === 'Backspace' && index > 0 && !oldPin[index]) {
      pinInputRefs.current[index - 1]?.focus();
      let currentPin = [...oldPin];
      currentPin[index - 1] = '';
      setOldPin(currentPin);
    }
  };

  return (
    <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : 'height'} style={styles.container}>

      <View style={styles.body}>
        <Text style={styles.stepTitle}>Nhập mã PIN cũ</Text>
        <Text style={styles.stepSubtitle}>Vui lòng nhập mã bảo vệ hiện tại của bạn để hệ thống xác minh chính chủ.</Text>

        <View style={styles.otpContainer}>
          {Array(6).fill(0).map((_, index) => (
            <TextInput
              key={index}
              style={styles.otpInput}
              keyboardType="number-pad"
              maxLength={1}
              secureTextEntry={true}
              value={oldPin[index] || ''}
              onChangeText={(text) => handlePinChange(text, index)}
              onKeyPress={(e) => handlePinKeyPress(e, index)}
              ref={(ref) => { pinInputRefs.current[index] = ref; }}
              autoFocus={index === 0}
            />
          ))}
        </View>

        {submitting && (
          <View style={styles.loaderBox}>
            <ActivityIndicator size="small" color="#2563EB" />
            <Text style={styles.loaderText}>Đang kiểm tra thông tin...</Text>
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