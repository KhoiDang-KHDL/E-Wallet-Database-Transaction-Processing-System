// src/app/(transaction)/result.tsx
import { Ionicons } from '@expo/vector-icons';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { StyleSheet, Text, TouchableOpacity, View } from 'react-native';

export default function ResultScreen() {
  const router = useRouter();
  
  // Nhận thông tin kết quả từ trang confirm truyền sang
  const { status, amount, name, refCode, msg } = useLocalSearchParams<{
    status: 'success' | 'failed';
    amount: string;
    name: string;
    refCode: string;
    msg: string;
  }>();

  const isSuccess = status === 'success';

  return (
    <View style={styles.container}>
      <View style={styles.content}>
        
        {/* ICON TRẠNG THÁI */}
        <View style={[styles.iconCircle, { backgroundColor: isSuccess ? '#E8F5E9' : '#FFEBEE' }]}>
          <Ionicons 
            name={isSuccess ? "checkmark-circle" : "close-circle"} 
            size={80} 
            color={isSuccess ? "#4CAF50" : "#F44336"} 
          />
        </View>

        <Text style={styles.statusText}>
          {isSuccess ? 'Giao dịch thành công' : 'Giao dịch thất bại'}
        </Text>

        <Text style={styles.amountText}>
          {parseInt(amount || '0').toLocaleString('vi-VN')} VNĐ
        </Text>

        {/* THÔNG TIN BIÊN NHẬN CHI TIẾT */}
        <View style={styles.receiptBox}>
          <View style={styles.row}>
            <Text style={styles.label}>Người nhận</Text>
            <Text style={styles.value}>{name || 'N/A'}</Text>
          </View>
          
          <View style={styles.divider} />

          <View style={styles.row}>
            <Text style={styles.label}>Mã giao dịch (Ref)</Text>
            <Text style={[styles.value, { color: '#2563EB' }]}>{refCode || 'N/A'}</Text>
          </View>

          <View style={styles.divider} />

          <View style={styles.row}>
            <Text style={styles.label}>Nội dung</Text>
            <Text style={styles.value} numberOfLines={2}>{msg || 'Chuyển tiền ví'}</Text>
          </View>
        </View>

      </View>

      {/* NÚT QUAY VỀ TRANG CHỦ */}
      <TouchableOpacity 
        style={styles.homeButton} 
        onPress={() => router.replace('/(tabs)')}
      >
        <Text style={styles.homeButtonText}>Quay về trang chủ</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#FFFFFF', padding: 24 },
  content: { flex: 1, alignItems: 'center', justifyContent: 'center', paddingTop: 40 },
  iconCircle: { width: 120, height: 120, borderRadius: 60, justifyContent: 'center', alignItems: 'center', marginBottom: 24 },
  statusText: { fontSize: 22, fontWeight: '700', color: '#1F2937', marginBottom: 8 },
  amountText: { fontSize: 30, fontWeight: '800', color: '#1F2937', marginBottom: 40 },
  receiptBox: { backgroundColor: '#F9FAFB', borderRadius: 16, padding: 20, width: '100%', borderWidth: 1, borderColor: '#E5E7EB' },
  row: { flexDirection: 'row', justifyContent: 'space-between', marginVertical: 10 },
  label: { fontSize: 14, color: '#6B7280', fontWeight: '500' },
  value: { fontSize: 14, color: '#1F2937', fontWeight: '700', flex: 1, textAlign: 'right', marginLeft: 20 },
  divider: { height: 1, backgroundColor: '#E5E7EB', marginVertical: 4 },
  homeButton: { backgroundColor: '#2563EB', height: 56, borderRadius: 16, justifyContent: 'center', alignItems: 'center', marginBottom: 20 },
  homeButtonText: { color: '#FFFFFF', fontSize: 16, fontWeight: '700' }
});