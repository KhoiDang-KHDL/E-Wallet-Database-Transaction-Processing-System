// src/app/settings.tsx
import { Ionicons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import { useState } from 'react';
import { Alert, Platform, ScrollView, StyleSheet, Switch, Text, TouchableOpacity, View } from 'react-native';

export default function SettingsScreen() {
  const router = useRouter();
  const [biometric, setBiometric] = useState(false);
  const [notification, setNotification] = useState(true);

  return (
    <View style={styles.container}>

      <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
        
        {/* NHÓM 1: TÀI KHOẢN & BẢO MẬT */}
        <Text style={styles.sectionTitle}>Tài khoản & Bảo mật</Text>
        <View style={styles.cardGroup}>
          
          {/* Chuyển đến trang nhập PIN cũ */}
          <TouchableOpacity style={styles.itemRow} onPress={() => router.push('/update_pin1')}>
            <View style={styles.itemLeft}>
              <View style={[styles.iconBg, { backgroundColor: '#EFF6FF' }]}>
                <Ionicons name="key-outline" size={20} color="#2563EB" />
              </View>
              <View>
                <Text style={styles.itemTitle}>Thay đổi mã PIN ví</Text>
                <Text style={styles.itemSubtitle}>Mã bảo mật 6 số dùng khi giao dịch</Text>
              </View>
            </View>
            <Ionicons name="chevron-forward" size={18} color="#9CA3AF" />
          </TouchableOpacity>

          <View style={styles.divider} />

          {/* Chuyển đến trang đổi mật khẩu */}
          <TouchableOpacity style={styles.itemRow} onPress={() => router.push('/update_password')}>
            <View style={styles.itemLeft}>
              <View style={[styles.iconBg, { backgroundColor: '#FEE2E2' }]}>
                <Ionicons name="lock-closed-outline" size={20} color="#EF4444" />
              </View>
              <View>
                <Text style={styles.itemTitle}>Đổi mật khẩu đăng nhập</Text>
                <Text style={styles.itemSubtitle}>Bảo vệ tài khoản ứng dụng của bạn</Text>
              </View>
            </View>
            <Ionicons name="chevron-forward" size={18} color="#9CA3AF" />
          </TouchableOpacity>
        </View>

        {/* NHÓM 2: TIỆN ÍCH ĐIỀU CHỈNH (SWITCH DEMO) */}
        <Text style={styles.sectionTitle}>Cấu hình ứng dụng</Text>
        <View style={styles.cardGroup}>
          <View style={styles.itemRow}>
            <View style={styles.itemLeft}>
              <View style={[styles.iconBg, { backgroundColor: '#ECFDF5' }]}>
                <Ionicons name="finger-print-outline" size={20} color="#10B981" />
              </View>
              <View>
                <Text style={styles.itemTitle}>Xác thực sinh trắc học</Text>
                <Text style={styles.itemSubtitle}>Sử dụng Vân tay / FaceID để mở ví</Text>
              </View>
            </View>
            <Switch value={biometric} onValueChange={setBiometric} trackColor={{ true: '#10B981' }} />
          </View>

          <View style={styles.divider} />

          <View style={styles.itemRow}>
            <View style={styles.itemLeft}>
              <View style={[styles.iconBg, { backgroundColor: '#FFF7ED' }]}>
                <Ionicons name="notifications-outline" size={20} color="#F97316" />
              </View>
              <View>
                <Text style={styles.itemTitle}>Thông báo ứng dụng</Text>
                <Text style={styles.itemSubtitle}>Nhận biến động số dư real-time</Text>
              </View>
            </View>
            <Switch value={notification} onValueChange={setNotification} trackColor={{ true: '#F97316' }} />
          </View>
        </View>

        {/* NHÓM 3: THÔNG TIN BỔ SUNG */}
        <Text style={styles.sectionTitle}>Thông tin bổ sung</Text>
        <View style={styles.cardGroup}>
          <TouchableOpacity style={styles.itemRow} onPress={() => Alert.alert("Thông báo", "Tài khoản của bạn đã được định danh mức độ cao nhất (KYC Level 2).")}>
            <View style={styles.itemLeft}>
              <View style={[styles.iconBg, { backgroundColor: '#F5F3FF' }]}>
                <Ionicons name="id-card-outline" size={20} color="#7C3AED" />
              </View>
              <View>
                <Text style={styles.itemTitle}>Định danh tài khoản (KYC)</Text>
                <Text style={styles.itemSubtitle}>Trạng thái: Đã xác thực thành công</Text>
              </View>
            </View>
            <Ionicons name="checkmark-circle" size={18} color="#10B981" />
          </TouchableOpacity>

          <View style={styles.divider} />

          <TouchableOpacity style={styles.itemRow} onPress={() => Alert.alert("Ngôn ngữ", "Hệ thống đang ưu tiên hiển thị Tiếng Việt mặc định.")}>
            <View style={styles.itemLeft}>
              <View style={[styles.iconBg, { backgroundColor: '#F0FDFA' }]}>
                <Ionicons name="globe-outline" size={20} color="#0D9488" />
              </View>
              <View>
                <Text style={styles.itemTitle}>Ngôn ngữ / Language</Text>
                <Text style={styles.itemSubtitle}>Tiếng Việt (Vietnamese)</Text>
              </View>
            </View>
            <Ionicons name="chevron-forward" size={18} color="#9CA3AF" />
          </TouchableOpacity>
        </View>

        {/* NÚT ĐĂNG XUẤT */}
        <TouchableOpacity style={styles.logoutButton} onPress={() => Alert.alert("Đăng xuất", "Bạn có chắc chắn muốn đăng xuất khỏi ví?")}>
          <Ionicons name="log-out-outline" size={20} color="#EF4444" style={{ marginRight: 8 }} />
          <Text style={styles.logoutText}>Đăng xuất tài khoản</Text>
        </TouchableOpacity>

      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#F9FAFB' },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingHorizontal: 16, height: 80, backgroundColor: '#FFFFFF', borderBottomWidth: 1, borderColor: '#E5E7EB', paddingTop: Platform.OS === 'ios' ? 0 : 20 },
  backButton: { padding: 4 },
  headerTitle: { fontSize: 17, fontWeight: '700', color: '#1F2937' },
  scrollContent: { padding: 20 },
  sectionTitle: { fontSize: 13, fontWeight: '700', color: '#6B7280', textTransform: 'uppercase', marginBottom: 12, marginTop: 14, paddingHorizontal: 4 },
  cardGroup: { backgroundColor: '#FFFFFF', borderRadius: 20, paddingHorizontal: 16, borderWidth: 1, borderColor: '#E5E7EB', marginBottom: 18 },
  itemRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingVertical: 14 },
  itemLeft: { flexDirection: 'row', alignItems: 'center', flex: 1 },
  iconBg: { width: 38, height: 38, borderRadius: 12, justifyContent: 'center', alignItems: 'center', marginRight: 14 },
  itemTitle: { fontSize: 14, fontWeight: '600', color: '#1F2937' },
  itemSubtitle: { fontSize: 12, color: '#9CA3AF', marginTop: 2 },
  divider: { height: 1, backgroundColor: '#F3F4F6' },
  logoutButton: { flexDirection: 'row', justifyContent: 'center', alignItems: 'center', backgroundColor: '#FFF5F5', borderRadius: 16, height: 50, borderWidth: 1, borderColor: '#FEE2E2', marginTop: 12, marginBottom: 30 },
  logoutText: { color: '#EF4444', fontSize: 14, fontWeight: '700' }
});