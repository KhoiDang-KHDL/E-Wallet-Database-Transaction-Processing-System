// src/app/(tabs)/index.tsx
import { Ionicons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import { useEffect, useState } from 'react';
import { ActivityIndicator, Alert, ScrollView, StyleSheet, Text, TouchableOpacity, View } from 'react-native';

// Import cấu hình API 
import { API_URL } from '../../utils/api';
// Import helper lấy token đã lưu sau khi đăng nhập thành công
import { getToken } from '../../utils/auth_storage';

const formatCurrency = (value: number | string) => {
  const num = typeof value === 'string' ? parseFloat(value) : value;
  if (isNaN(num)) return '0';
  return num.toLocaleString('vi-VN');
};

const getFirstName = (fullName: string) => {
  if (!fullName) return 'Người dùng';

  const names = fullName.trim().split(' ');

  // Nếu chỉ có 1 chữ thì trả luôn
  if (names.length === 1) {
    return names[0];
  }

  // Lấy 2 chữ cuối
  return names.slice(-2).join(' ');
};

export default function HomeScreen() {
  const router = useRouter();
  
  const [profile, setProfile] = useState<any>(null);
  const [wallet, setWallet] = useState<any>(null);
  const [transactions, setTransactions] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [showBalance, setShowBalance] = useState(true);

  useEffect(() => {
    fetchHomeScreenData();
  }, []);

  const fetchHomeScreenData = async () => {
    setLoading(true);
    
    // 1. Lấy token ra để chuẩn bị gửi lên Backend
    const token = getToken();
    
    console.log('================ [API HOME REQUEST] ================');
    console.log(`Đang gọi các API thật với Token: ${token ? 'Đã có token' : 'Trống!'}`);
    console.log('====================================================');

    if (!token) {
      Alert.alert('Phiên đăng nhập hết hạn', 'Vui lòng đăng nhập lại.', [
        { text: 'OK', onPress: () => router.replace('/login') }
      ]);
      setLoading(false);
      return;
    }

    // 2. Cấu hình Headers chứa chuỗi xác thực Bearer Token đúng chuẩn FastAPI
    const headers = { 
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    }; 

    try {
      // Gọi đồng thời cả 3 API thật bằng Promise.all nhằm tăng tốc độ tải UI
      const [profileRes, walletRes, transRes] = await Promise.all([
        fetch(`${API_URL}/me`, { method: 'GET', headers }),
        fetch(`${API_URL}/wallet`, { method: 'GET', headers }),
        fetch(`${API_URL}/transactions?limit=4&offset=0`, { method: 'GET', headers })
      ]);

      const profileData = await profileRes.json();
      const walletData = await walletRes.json();
      const transData = await transRes.json();

      console.log('================ [API HOME RESPONSE] ================');
      console.log('Profile Response Status:', profileRes.status);
      console.log('Wallet Response Status:', walletRes.status);
      console.log(`Transactions Count: ${Array.isArray(transData) ? transData.length : 0}`);
      console.log('=====================================================');

      // Kiểm tra nếu tất cả API đồng loạt trả về thành công (200 OK)
      if (profileRes.ok && walletRes.ok && transRes.ok) {
        setProfile(profileData);
        setWallet(walletData);
        // Đảm bảo dữ liệu transaction trả về dạng mảng, nếu lỗi cấu trúc thì gán mảng rỗng
        setTransactions(Array.isArray(transData) ? transData : []);
      } else {
        console.error('Lỗi từ một trong các API:', { profileData, walletData, transData });
        Alert.alert('Lỗi dữ liệu', 'Không thể đồng bộ thông tin tài khoản từ hệ thống.');
      }
    } catch (error) {
      console.error('Lỗi kết nối API hệ thống Trang Chủ:', error);
      Alert.alert('Lỗi kết nối', 'Mất kết nối đến máy chủ Backend.');
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#2563EB" />
        <Text style={styles.loadingText}>Đang tải dữ liệu ví...</Text>
      </View>
    );
  }

  return (
    <ScrollView style={styles.container} bounces={false} showsVerticalScrollIndicator={false}>
      {/* 1. HEADER (Đã chỉnh sửa để thêm cụm nút bên phải) */}
      <View style={styles.header}>
        <View>
          <Text style={styles.greeting}>Xin chào 👋</Text>
          <Text style={styles.userName}>{getFirstName(profile?.full_name)}</Text>
        </View>

        {/* CỤM ICON MỚI: Thông báo và Cài đặt */}
        <View style={styles.headerButtons}>
          <TouchableOpacity 
            style={styles.headerIconBtn} 
            // onPress={() => Alert.alert('Thông báo', 'Tính năng thông báo đang được phát triển!')}
          >
            <Ionicons name="notifications-outline" size={24} color="#1F2937" />
          </TouchableOpacity>

          <TouchableOpacity 
            style={styles.headerIconBtn} 
            onPress={() => router.push('/settings')} // Điều hướng thẳng tới file settings theo cấu trúc layout của bạn
          >
            <Ionicons name="settings-outline" size={24} color="#1F2937" />
          </TouchableOpacity>
        </View>
      </View>

      {/* 2. MAIN CARD */}
      <View style={styles.mainCard}>
        <View style={styles.cardHeader}>
          <Text style={styles.balanceLabel}>Số dư ví khả dụng ({wallet?.currency || 'VND'})</Text>
          <TouchableOpacity onPress={() => setShowBalance(!showBalance)}>
            <Ionicons 
              name={showBalance ? "eye-outline" : "eye-off-outline"} 
              size={22} 
              color="#FFFFFF" 
            />
          </TouchableOpacity>
        </View>
        
        <Text style={styles.balanceValue}>
          {showBalance ? `${formatCurrency(wallet?.balance)}đ` : '******'}
        </Text>
      </View>

      {/* 3. QUICK ACTIONS */}
      <View style={styles.actionContainer}>
        <TouchableOpacity style={styles.actionItem} onPress={() => router.push('/(transaction)/my_qr')}>
          <View style={styles.iconCircle}>
            <Ionicons name="qr-code" size={24} color="#2563EB" />
          </View>
          <Text style={styles.actionText}>Mã QR</Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.actionItem} onPress={() => router.push('/(transaction)/transfer')}>
          <View style={styles.iconCircle}>
            <Ionicons name="swap-horizontal" size={24} color="#2563EB" />
          </View>
          <Text style={styles.actionText}>Chuyển tiền</Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.actionItem} onPress={() => router.push('/(transaction)/withdraw')}>
          <View style={styles.iconCircle}>
            <Ionicons name="arrow-down" size={24} color="#2563EB" />
          </View>
          <Text style={styles.actionText}>Rút tiền</Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.actionItem} onPress={() => router.push('/(transaction)/deposit')}>
          <View style={styles.iconCircle}>
            <Ionicons name="arrow-up" size={24} color="#2563EB" />
          </View>
          <Text style={styles.actionText}>Nạp tiền</Text>
        </TouchableOpacity>
      </View>

      {/* 4. RECENT ACTIVITY */}
      <View style={styles.activityHeader}>
        <Text style={styles.sectionTitle}>Giao dịch gần đây</Text>
        <TouchableOpacity onPress={() => router.push('/(tabs)/history')}>
          <Text style={styles.seeAllText}>Xem tất cả</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.activityList}>
        {transactions.length === 0 ? (
          <Text style={styles.emptyText}>Bạn chưa có giao dịch nào gần đây.</Text>
        ) : (
          transactions.map((item) => {
            let displayTitle = ''; 
            let displayIcon = 'cash-outline';
            let isPositive = false;

            // 🌟 CẢI TIẾN CHÍNH: Cắt khoảng trắng thừa từ kiểu CHAR của Oracle DB và ép chữ in hoa
            const typeCodeClean = item.type_code ? item.type_code.trim().toUpperCase() : '';

            // 1. Xác định Icon và dòng tiền (Âm/Dương) dựa vào typeCode đã làm sạch
            if (typeCodeClean === 'DEPOSIT' || typeCodeClean === 'TOP_UP') {
              displayIcon = 'arrow-up-circle';
              isPositive = true; // Hiện dấu cộng (+) và màu xanh lá chuẩn xác
            } else if (typeCodeClean === 'WITHDRAW') {
              displayIcon = 'arrow-down-circle';
              isPositive = false;
            } else if (typeCodeClean === 'TRANSFER') {
              isPositive = item.sender_wallet_id !== wallet?.wallet_id;
              displayIcon = isPositive ? 'arrow-back-circle' : 'arrow-forward-circle';
            }

            // 2. XỬ LÝ ĐIỀU KIỆN ĐỔI TÊN: Lọc sạch description rác
            if (
              item.description && 
              !item.description.toLowerCase().includes('giao dịch đang xử lý') &&
              !item.description.toLowerCase().includes('test')
            ) {
              displayTitle = item.description.replace(/#\S+/g, '').replace(/\s+/g, ' ').trim();
            }

            // 3. Nếu description trống hoặc dính chữ rác -> Gán tên nghiệp vụ chuẩn đồng bộ
            if (!displayTitle) {
              if (typeCodeClean === 'DEPOSIT' || typeCodeClean === 'TOP_UP') {
                displayTitle = 'Nạp tiền vào ví';
              } else if (typeCodeClean === 'WITHDRAW') {
                displayTitle = 'Rút tiền về ngân hàng';
              } else if (typeCodeClean === 'TRANSFER') {
                displayTitle = isPositive ? 'Nhận tiền từ ví khác' : 'Chuyển tiền đi';
              } else {
                displayTitle = 'Giao dịch ví';
              }
            }

            return (
              <View key={item.transaction_id} style={styles.activityItem}>
                <View style={styles.itemLeft}>
                  <View style={styles.itemIconContainer}>
                    <Ionicons name={displayIcon as any} size={22} color="#4B5563" />
                  </View>
                  <View style={{ flexShrink: 1, paddingRight: 8 }}>
                    <Text style={styles.itemTitle} numberOfLines={1}>
                      {displayTitle}
                    </Text>
                    <Text style={styles.itemTime}>{item.created_at}</Text>
                  </View>
                </View>
                
                <Text style={[
                  styles.itemAmount, 
                  { color: isPositive ? '#10B981' : '#1F2937' } // Xanh lá nếu tiền vào, đen nếu tiền ra
                ]}>
                  {isPositive ? '+' : '-'}{formatCurrency(item.amount)}đ
                </Text>
              </View>
            );
          })
        )}
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#F9FAFB', paddingTop: 60, paddingHorizontal: 20 },
  loadingContainer: { flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: '#F9FAFB' },
  loadingText: { marginTop: 12, fontSize: 14, color: '#6B7280', fontWeight: '500' },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 },
  greeting: { fontSize: 14, color: '#6B7280', paddingLeft: 10 },
  userName: { fontSize: 24, fontWeight: '800', color: '#1F2937', marginTop: 2, paddingLeft: 10 },
  
  // STYLE CỤM BUTTON MỚI:
  headerButtons: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  headerIconBtn: {
    padding: 8,
    marginLeft: 8, // Tạo khoảng cách nhẹ giữa 2 nút bấm
    backgroundColor: '#FFFFFF', // Thêm nền trắng bo tròn nhẹ cho nút bấm trông sang xịn mịn hơn
    borderRadius: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.02,
    shadowRadius: 2,
    elevation: 1,
  },

  mainCard: {
    backgroundColor: '#2563EB',
    borderRadius: 24,
    padding: 24,
    marginBottom: 28,
    shadowColor: '#2563EB',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.2,
    shadowRadius: 8,
    elevation: 4,
  },
  cardHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 },
  balanceLabel: { color: 'rgba(255,255,255,0.75)', fontSize: 13, fontWeight: '500' },
  balanceValue: { color: '#fff', fontSize: 30, fontWeight: '800', marginVertical: 4 },
  actionContainer: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: 32 },
  actionItem: { alignItems: 'center', flex: 1 },
  iconCircle: {
    width: 56,
    height: 56,
    borderRadius: 18,
    backgroundColor: '#FFFFFF',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 8,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.04,
    shadowRadius: 4,
    elevation: 2,
  },
  actionText: { color: '#4B5563', fontSize: 13, fontWeight: '600' },
  activityHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 },
  sectionTitle: { fontSize: 18, fontWeight: '700', color: '#1F2937' },
  seeAllText: { color: '#2563EB', fontSize: 14, fontWeight: '600' },
  activityList: { marginBottom: 40 },
  activityItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    padding: 16,
    borderRadius: 16,
    marginBottom: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.02,
    shadowRadius: 3,
    elevation: 1,
  },
  itemLeft: { flexDirection: 'row', alignItems: 'center', flex: 1 },
  itemIconContainer: { width: 40, height: 40, borderRadius: 12, backgroundColor: '#F3F4F6', justifyContent: 'center', alignItems: 'center', marginRight: 12 },
  itemTitle: { fontSize: 14, fontWeight: '600', color: '#1F2937' },
  itemTime: { fontSize: 11, color: '#9CA3AF', marginTop: 2 },
  itemAmount: { fontSize: 15, fontWeight: '700' },
  emptyText: { textAlign: 'center', color: '#9CA3AF', marginTop: 20, fontSize: 14, fontStyle: 'italic' }
});