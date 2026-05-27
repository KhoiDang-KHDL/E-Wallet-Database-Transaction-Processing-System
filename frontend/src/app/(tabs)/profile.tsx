// src/app/(tabs)/profile.tsx
import { Ionicons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import { useEffect, useState } from 'react';
import { ActivityIndicator, Alert, Platform, ScrollView, StyleSheet, Text, TouchableOpacity, View } from 'react-native';

// Import cấu hình API và kho lưu trữ token
import { API_URL } from '../../utils/api';
import { getToken, setToken } from '../../utils/auth_storage';

const settingItems = [
  // Nếu không có trường screen -> Định nghĩa đây là mục hiển thị tĩnh
  { id: '1', title: 'Thông báo', subtitle: 'Quản lý cảnh báo biến động số dư', icon: 'notifications-outline' },
  { id: '2', title: 'Cài đặt & Bảo mật', subtitle: 'Đổi mật khẩu, mã PIN của ví', icon: 'settings-outline', screen: 'settings' },
  { id: '3', title: 'Liên kết ngân hàng', subtitle: 'Quản lý thẻ và tài khoản liên kết', icon: 'card-outline', screen: 'linked_methods' },
  { id: '5', title: 'Trợ giúp & Hỗ trợ', subtitle: 'Trung tâm hỗ trợ khách hàng', icon: 'help-circle-outline' },
];

export default function ProfileScreen() {
  const router = useRouter();
  
  // Các trạng thái quản lý dữ liệu người dùng thật từ Oracle DB
  const [user, setUser] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  // 1. Gọi API /me để lấy thông tin cá nhân thực tế
  useEffect(() => {
    async function fetchUserProfile() {
      const token = getToken();
      try {
        const res = await fetch(`${API_URL}/me`, {
          method: 'GET',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
          }
        });
        if (res.ok) {
          const data = await res.json();
          setUser(data);
        }
      } catch (error) {
        console.error("Lỗi tải thông tin cá nhân:", error);
      } finally {
        setLoading(false);
      }
    }
    fetchUserProfile();
  }, []);

  // 2. Hàm xử lý gọi API Logout để Oracle cập nhật trạng thái session
  const handleSignOut = () => {
    Alert.alert(
      "Đăng xuất",
      "Bạn có chắc chắn muốn đăng xuất khỏi tài khoản ví?",
      [
        { text: "Hủy", style: "cancel" },
        { 
          text: "Đăng xuất", 
          style: "destructive", 
          onPress: async () => {
            const token = getToken();
            try {
              await fetch(`${API_URL}/auth/logout`, {
                method: 'POST',
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': `Bearer ${token}`
                }
              });
            } catch (error) {
              console.error("Lỗi gọi API đăng xuất:", error);
            } finally {
              setToken(''); 
              router.replace('/login');
            }
          } 
        }
      ]
    );
  };

  if (loading) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#2563EB" />
        <Text style={styles.loadingText}>Đang tải thông tin cá nhân...</Text>
      </View>
    );
  }

  return (
    <ScrollView style={styles.container} bounces={false} showsVerticalScrollIndicator={false}>
      {/* 1. HEADER TITLE */}
      <View style={styles.headerTitleContainer}>
        <Text style={styles.headerTitle}>Tài khoản</Text>
      </View>

      {/* 2. USER INFO CARD */}
      <TouchableOpacity 
        style={styles.userCard}
        activeOpacity={0.8}
        onPress={() => router.push('/update_info')} 
      >
        <View style={styles.userInfo}>
          <Text style={styles.userName}>{user?.full_name || 'Người dùng E-Wallet'}</Text>
          <Text style={styles.userEmail}>{user?.phone || user?.email}</Text>
          
          {user?.kyc_status === 'VERIFIED' || user?.kyc_status === 1 ? (
            <View style={styles.verifiedBadge}>
              <Ionicons name="checkmark-circle" size={16} color="#10B981" />
              <Text style={styles.verifiedText}>Tài khoản đã xác thực (KYC)</Text>
            </View>
          ) : (
            <View style={styles.verifiedBadge}>
              <Ionicons name="alert-circle-outline" size={16} color="#EF4444" />
              <Text style={[styles.verifiedText, { color: '#EF4444' }]}>Chưa xác thực thông tin</Text>
            </View>
          )}
        </View>
        <Ionicons name="chevron-forward" size={20} color="#9CA3AF" style={styles.cardChevron} />
      </TouchableOpacity>

      {/* 3. SETTINGS LIST GROUP */}
      <View style={styles.settingsGroup}>
        {settingItems.map((item, index) => {
          // Kiểm tra xem mục này có cấu hình màn hình đích để bấm chuyển trang hay không
          const hasTargetScreen = !!item.screen;

          return (
            <TouchableOpacity 
              key={item.id} 
              disabled={!hasTargetScreen} // 🌟 Vẫn KHÓA không cho bấm nếu là mục "Thông báo"
              activeOpacity={hasTargetScreen ? 0.7 : 1} // Tắt hiệu ứng mờ phản hồi khi chạm đối với mục bị khóa
              style={[
                styles.settingItem, 
                index === settingItems.length - 1 ? { borderBottomWidth: 0 } : null
              ]}
              onPress={() => {
                if (hasTargetScreen) {
                  router.push(`/${item.screen}` as any);
                }
              }}
            >
              <View style={styles.itemLeft}>
                <View style={styles.iconContainer}>
                  <Ionicons name={item.icon as any} size={22} color="#4B5563" />
                </View>
                <View style={{ flexShrink: 1, paddingRight: 8 }}>
                  <Text style={styles.itemTitle}>{item.title}</Text>
                  <Text style={styles.itemSubtitle} numberOfLines={1}>{item.subtitle}</Text>
                </View>
              </View>
              
              {/* 🌟 GIỮ NGUYÊN: Luôn luôn hiển thị ký hiệu mũi tên (>) cho tất cả các mục */}
              <Ionicons name="chevron-forward" size={18} color="#9CA3AF" />
            </TouchableOpacity>
          );
        })}
      </View>

      {/* 4. SIGN OUT BUTTON */}
      <TouchableOpacity style={styles.signOutButton} onPress={handleSignOut}>
        <Text style={styles.signOutText}>Đăng xuất</Text>
      </TouchableOpacity>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#F9FAFB', paddingTop: Platform.OS === 'ios' ? 60 : 40, paddingHorizontal: 20 },
  loadingContainer: { flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: '#F9FAFB' },
  loadingText: { marginTop: 12, fontSize: 14, color: '#6B7280', fontWeight: '500' },
  headerTitleContainer: { marginBottom: 24, paddingHorizontal: 4 },
  headerTitle: { fontSize: 24, fontWeight: '800', color: '#1F2937' },
  userCard: { flexDirection: 'row', alignItems: 'center', backgroundColor: '#FFFFFF', borderRadius: 20, padding: 20, paddingRight: 16, marginBottom: 24, shadowColor: '#000', shadowOffset: { width: 0, height: 2 }, shadowOpacity: 0.03, shadowRadius: 10, elevation: 2, position: 'relative' },
  userInfo: { flex: 1 },
  userName: { fontSize: 18, fontWeight: '800', color: '#1F2937' },
  userEmail: { fontSize: 14, color: '#6B7280', marginVertical: 4 },
  verifiedBadge: { flexDirection: 'row', alignItems: 'center', marginTop: 4 },
  verifiedText: { fontSize: 12, color: '#10B981', fontWeight: '600', marginLeft: 4 },
  cardChevron: { alignSelf: 'center', marginLeft: 8 },
  settingsGroup: { backgroundColor: '#FFFFFF', borderRadius: 20, paddingHorizontal: 16, marginBottom: 32, shadowColor: '#000', shadowOffset: { width: 0, height: 1 }, shadowOpacity: 0.02, shadowRadius: 8, elevation: 1 },
  settingItem: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingVertical: 18, borderBottomWidth: 1, borderColor: '#F3F4F6' },
  itemLeft: { flexDirection: 'row', alignItems: 'center', flex: 1 },
  iconContainer: { width: 40, height: 40, borderRadius: 12, backgroundColor: '#F3F4F6', justifyContent: 'center', alignItems: 'center', marginRight: 16 },
  itemTitle: { fontSize: 15, fontWeight: '600', color: '#1F2937' },
  itemSubtitle: { fontSize: 12, color: '#9CA3AF', marginTop: 2 },
  signOutButton: { backgroundColor: '#FEF2F2', borderRadius: 16, paddingVertical: 16, alignItems: 'center', justifyContent: 'center', marginBottom: 60, borderWidth: 1, borderColor: '#FEE2E2' },
  signOutText: { color: '#EF4444', fontSize: 15, fontWeight: '700' },
});