// src/app/(tabs)/history.tsx
import { Ionicons } from '@expo/vector-icons';
import { useEffect, useState } from 'react';
import { ActivityIndicator, Platform, RefreshControl, ScrollView, StyleSheet, Text, TouchableOpacity, View } from 'react-native';

// Import cấu hình API và token xác thực
import { API_URL } from '../../utils/api';
import { getToken } from '../../utils/auth_storage';

type FilterType = 'All' | 'Income' | 'Expense';

export default function HistoryScreen() {
  const [activeFilter, setActiveFilter] = useState<FilterType>('All');
  const [transactions, setTransactions] = useState<any[]>([]);
  const [myWalletId, setMyWalletId] = useState<number | null>(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  // Tải dữ liệu lịch sử giao dịch và thông tin ví từ Oracle DB
  const fetchHistoryData = async () => {
    const token = getToken();
    const headers = {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    };

    try {
      // Gọi song song API thông tin ví để lấy wallet_id và API danh sách giao dịch
      const [walletRes, transRes] = await Promise.all([
        fetch(`${API_URL}/wallet`, { method: 'GET', headers }),
        fetch(`${API_URL}/transactions?limit=100&offset=0`, { method: 'GET', headers })
      ]);

      if (walletRes.ok && transRes.ok) {
        const walletData = await walletRes.json();
        const transData = await transRes.json();

        setMyWalletId(walletData.wallet_id);
        setTransactions(Array.isArray(transData) ? transData : []);
      }
    } catch (error) {
      console.error("Lỗi tải lịch sử giao dịch:", error);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    fetchHistoryData();
  }, []);

  const onRefresh = () => {
    setRefreshing(true);
    fetchHistoryData();
  };

  const formatCurrency = (value: number | string) => {
    const num = typeof value === 'string' ? parseFloat(value) : value;
    if (isNaN(num)) return '0';
    return num.toLocaleString('vi-VN');
  };

  // LOGIC CHUẨN HÓA TIÊU ĐỀ GIAO DỊCH VÀ PHÂN LOẠI (BỎ PENDING)
  const processedActivities = transactions.map(item => {
    let displayTitle = ''; 
    let displayIcon = 'cash-outline';
    let isPositive = false;

    const typeCodeClean = item.type_code ? item.type_code.trim().toUpperCase() : '';

    // Xác định Icon và dòng tiền
    if (typeCodeClean === 'DEPOSIT' || typeCodeClean === 'TOP_UP') {
      displayIcon = 'arrow-up-circle';
      isPositive = true;
    } else if (typeCodeClean === 'WITHDRAW') {
      displayIcon = 'arrow-down-circle';
      isPositive = false;
    } else if (typeCodeClean === 'TRANSFER') {
      isPositive = item.sender_wallet_id !== myWalletId;
      displayIcon = isPositive ? 'arrow-back-circle' : 'arrow-forward-circle';
    }

    // Lọc sạch chuỗi description
    if (
      item.description && 
      !item.description.toLowerCase().includes('giao dịch đang xử lý') &&
      !item.description.toLowerCase().includes('test')
    ) {
      displayTitle = item.description.replace(/#\S+/g, '').replace(/\s+/g, ' ').trim();
    }

    // Tự động ghi đè theo nghiệp vụ chuẩn khi description null
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

    return { ...item, displayTitle, displayIcon, isPositive };
  });
  
  // Bộ lọc theo Tab dựa trên trạng thái dòng tiền thực tế (isPositive)
  const filteredActivities = processedActivities.filter(item => {
    if (activeFilter === 'Income') return item.isPositive === true;
    if (activeFilter === 'Expense') return item.isPositive === false;
    return true;
  });

  if (loading) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#2563EB" />
        <Text style={styles.loadingText}>Đang đồng bộ giao dịch...</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      {/* 1. HEADER TITLE */}
      <View style={styles.headerContainer}>
        <Text style={styles.headerTitle}>Lịch sử giao dịch</Text>
      </View>

      {/* 2. FILTER TABS */}
      <View style={styles.filterContainer}>
        {(['All', 'Income', 'Expense'] as FilterType[]).map((filter) => {
          const isActive = activeFilter === filter;
          
          let filterLabel = 'Tất cả';
          if (filter === 'Income') filterLabel = 'Tiền vào';
          if (filter === 'Expense') filterLabel = 'Tiền ra';

          return (
            <TouchableOpacity
              key={filter}
              style={[styles.filterButton, isActive && styles.activeFilterButton]}
              onPress={() => setActiveFilter(filter)}
              activeOpacity={0.7}
            >
              <Text style={[styles.filterButtonText, isActive && styles.activeFilterButtonText]}>
                {filterLabel}
              </Text>
            </TouchableOpacity>
          );
        })}
      </View>

      {/* 3. TRANSACTION LIST */}
      <ScrollView 
        style={styles.listContainer} 
        showsVerticalScrollIndicator={false}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} colors={['#2563EB']} />
        }
      >
        {filteredActivities.length > 0 ? (
          filteredActivities.map((item) => (
            <View key={item.transaction_id} style={styles.activityItem}>
              <View style={styles.itemLeft}>
                <View style={styles.itemIconContainer}>
                  <Ionicons name={item.displayIcon as any} size={22} color="#4B5563" />
                </View>
                <View style={{ flexShrink: 1, paddingRight: 8 }}>
                  <Text style={styles.itemTitle} numberOfLines={1}>{item.displayTitle}</Text>
                  <Text style={styles.itemTime}>{item.created_at}</Text>
                </View>
              </View>
              
              <Text style={[
                styles.itemAmount, 
                { color: item.isPositive ? '#10B981' : '#1F2937' }
              ]}>
                {item.isPositive ? '+' : '-'}{formatCurrency(item.amount)}đ
              </Text>
            </View>
          ))
        ) : (
          <View style={styles.emptyContainer}>
            <Ionicons name="receipt-outline" size={48} color="#9CA3AF" />
            <Text style={styles.emptyText}>Không tìm thấy giao dịch nào</Text>
          </View>
        )}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#F9FAFB', paddingTop: Platform.OS === 'ios' ? 60 : 40 },
  loadingContainer: { flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: '#F9FAFB' },
  loadingText: { marginTop: 12, fontSize: 14, color: '#6B7280', fontWeight: '500' },
  headerContainer: { marginBottom: 20, paddingHorizontal: 20 },
  headerTitle: { fontSize: 24, fontWeight: '800', color: '#1F2937' },
  filterContainer: { flexDirection: 'row', backgroundColor: '#E5E7EB', borderRadius: 14, padding: 4, marginHorizontal: 20, marginBottom: 20 },
  filterButton: { flex: 1, paddingVertical: 10, alignItems: 'center', justifyContent: 'center', borderRadius: 10 },
  activeFilterButton: { backgroundColor: '#FFFFFF', shadowColor: '#000', shadowOffset: { width: 0, height: 2 }, shadowOpacity: 0.08, shadowRadius: 4, elevation: 2 },
  filterButtonText: { fontSize: 14, fontWeight: '600', color: '#6B7280' },
  activeFilterButtonText: { color: '#1F2937' },
  listContainer: { flex: 1, paddingHorizontal: 20 },
  activityItem: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', backgroundColor: '#FFFFFF', padding: 16, borderRadius: 16, marginBottom: 12, shadowColor: '#000', shadowOffset: { width: 0, height: 1 }, shadowOpacity: 0.02, shadowRadius: 4, elevation: 1 },
  itemLeft: { flexDirection: 'row', alignItems: 'center', flex: 1 },
  itemIconContainer: { width: 40, height: 40, borderRadius: 12, backgroundColor: '#F3F4F6', justifyContent: 'center', alignItems: 'center', marginRight: 12 },
  itemTitle: { fontSize: 14, fontWeight: '600', color: '#1F2937' },
  itemTime: { fontSize: 11, color: '#9CA3AF', marginTop: 2 },
  itemAmount: { fontSize: 15, fontWeight: '700' },
  emptyContainer: { alignItems: 'center', justifyContent: 'center', marginTop: 100 },
  emptyText: { marginTop: 12, color: '#9CA3AF', fontSize: 15, fontWeight: '500' },
});