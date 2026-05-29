// src/app/(tabs)/voucher.tsx
import { Ionicons } from '@expo/vector-icons';
import { useEffect, useState } from 'react';
import { ActivityIndicator, RefreshControl, ScrollView, StyleSheet, Text, TextInput, TouchableOpacity, View } from 'react-native';

// Import cấu hình API và token xác thực
import { API_URL } from '../../utils/api';
import { getToken } from '../../utils/auth_storage';

export default function VoucherScreen() {
  const [vouchers, setVouchers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');

  // Tải danh sách voucher thực tế từ Oracle DB
  const fetchVouchers = async () => {
    const token = getToken();
    try {
      const res = await fetch(`${API_URL}/vouchers`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        }
      });
      if (res.ok) {
        const data = await res.json();
        setVouchers(Array.isArray(data) ? data : []);
      }
    } catch (error) {
      console.error("Lỗi tải danh sách voucher:", error);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    fetchVouchers();
  }, []);

  const onRefresh = () => {
    setRefreshing(true);
    fetchVouchers();
  };

  // Lọc dữ liệu theo từ khóa tìm kiếm (Mã code)
  const filteredVouchers = vouchers.filter(v => 
    v.code.toLowerCase().includes(searchQuery.toLowerCase())
  );

  // Helper định dạng hiển thị giá trị giảm giá dựa trên loại hình lưu trong DB
  const formatDiscountLabel = (item: any) => {
    if (item.discount_type === 'PERCENTAGE' || item.discount_type === '%') {
      return `Giảm ${item.discount_value}%`;
    }
    return `Giảm ${(item.discount_value).toLocaleString('vi-VN')}đ`;
  };

  // Helper sinh mô tả voucher tự động từ dữ liệu Oracle
  const buildVoucherDesc = (item: any) => {
    let desc = `Áp dụng cho giao dịch từ ${(item.min_order_value || 0).toLocaleString('vi-VN')}đ.`;
    if (item.max_discount && item.max_discount > 0) {
      desc += ` Giảm tối đa ${item.max_discount.toLocaleString('vi-VN')}đ.`;
    }
    return desc;
  };

  if (loading) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#2563EB" />
        <Text style={styles.loadingText}>Đang tải kho ưu đãi...</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      {/* 1. HEADER & SEARCH BAR */}
      <View style={styles.header}>
        <Text style={styles.title}>Ưu đãi của tôi</Text>
        <View style={styles.searchBar}>
          <Ionicons name="search" size={20} color="#9CA3AF" />
          <TextInput 
            placeholder="Nhập mã ưu đãi (VOUCHER)..." 
            placeholderTextColor="#9CA3AF"
            style={styles.searchInput} 
            value={searchQuery}
            onChangeText={setSearchQuery}
          />
          {searchQuery.length > 0 && (
            <TouchableOpacity onPress={() => setSearchQuery('')}>
              <Ionicons name="close-circle" size={18} color="#9CA3AF" />
            </TouchableOpacity>
          )}
        </View>
      </View>

      {/* 2. VOUCHER LIST */}
      <ScrollView 
        style={styles.list} 
        showsVerticalScrollIndicator={false} 
        contentContainerStyle={styles.listContent}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} colors={['#2563EB']} />
        }
      >
        {filteredVouchers.length > 0 ? (
          filteredVouchers.map((item) => (
            <View key={item.voucher_id} style={styles.voucherCard}>
              
              <View style={[styles.cardLeft, { backgroundColor: '#2563EB' }]}>
                <Ionicons name="gift-outline" size={26} color="#fff" />
                <Text style={styles.brandText} numberOfLines={1}>{item.code}</Text>
              </View>

              <View style={styles.cardRight}>
                <View style={{ flex: 1, justifyContent: 'center' }}>
                  {/* Tiêu đề */}
                  <Text style={styles.descText} numberOfLines={1}>
                    {formatDiscountLabel(item)}
                  </Text>
                  {/* Mô tả điều kiện áp dụng */}
                  <Text style={styles.conditionText} numberOfLines={2}>
                    {buildVoucherDesc(item)}
                  </Text>
                  {/* Hạn sử dụng */}
                  <Text style={styles.expiryText}>
                    Hạn dùng: {item.valid_until ? item.valid_until.substring(0, 10) : 'Vô thời hạn'}
                  </Text>
                </View>
                
                <View style={styles.actionRow}>
                  <View style={[styles.useButton, { marginLeft: 'auto' }]}>
                    <Text style={styles.useButtonText}>Khả dụng</Text>
                  </View>
                </View>
              </View>

              <View style={styles.cutoutTop} />
              <View style={styles.cutoutBottom} />
              <View style={styles.dashLine} />
            </View>
          ))
        ) : (
          <View style={styles.emptyContainer}>
            <Ionicons name="ticket-outline" size={54} color="#9CA3AF" />
            <Text style={styles.emptyText}>Không tìm thấy voucher nào hợp lệ</Text>
          </View>
        )}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#F9FAFB', paddingTop: 60 },
  loadingContainer: { flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: '#F9FAFB' },
  loadingText: { marginTop: 12, fontSize: 14, color: '#6B7280', fontWeight: '500' },
  header: { paddingHorizontal: 20, marginBottom: 15 },
  title: { fontSize: 24, fontWeight: '800', color: '#1F2937', marginBottom: 16 },
  searchBar: { flexDirection: 'row', backgroundColor: '#fff', borderRadius: 12, padding: 12, alignItems: 'center', borderWidth: 1, borderColor: '#E5E7EB' },
  searchInput: { marginLeft: 10, flex: 1, fontSize: 15, color: '#1F2937', padding: 0 },
  list: { flex: 1 },
  listContent: { paddingHorizontal: 20, paddingBottom: 100 },
  
  // Voucher Ticket Card Design
  voucherCard: { flexDirection: 'row', backgroundColor: '#fff', borderRadius: 16, height: 120, marginBottom: 16, overflow: 'hidden', borderWidth: 1, borderColor: '#E5E7EB', position: 'relative' },
  cardLeft: { width: 95, justifyContent: 'center', alignItems: 'center', padding: 8 },
  brandText: { color: '#fff', fontSize: 13, fontWeight: '800', marginTop: 6, textAlign: 'center' },
  cardRight: { flex: 1, padding: 12, justifyContent: 'space-between' },
  descText: { fontSize: 15, fontWeight: '800', color: '#1F2937' },
  conditionText: { fontSize: 12, color: '#4B5563', marginTop: 2, lineHeight: 16 },
  expiryText: { fontSize: 11, color: '#9CA3AF', marginTop: 4 },
  
  actionRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginTop: 4 },
  amountLeftText: { fontSize: 11, color: '#EF4444', fontWeight: '600' },
  useButton: { backgroundColor: '#EFF6FF', paddingVertical: 3, paddingHorizontal: 10, borderRadius: 6 },
  useButtonText: { fontSize: 11, fontWeight: '700', color: '#2563EB' },
  
  // Style răng cưa vé
  cutoutTop: { position: 'absolute', left: 87, top: -9, width: 16, height: 16, borderRadius: 8, backgroundColor: '#F9FAFB', borderWidth: 1, borderColor: '#E5E7EB' },
  cutoutBottom: { position: 'absolute', left: 87, bottom: -9, width: 16, height: 16, borderRadius: 8, backgroundColor: '#F9FAFB', borderWidth: 1, borderColor: '#E5E7EB' },
  dashLine: { position: 'absolute', left: 94, top: 12, bottom: 12, width: 1, borderStyle: 'dashed', borderWidth: 1, borderColor: '#E5E7EB' as any },
  
  emptyContainer: { alignItems: 'center', justifyContent: 'center', marginTop: 100 },
  emptyText: { marginTop: 12, color: '#9CA3AF', fontSize: 15, fontWeight: '500' }
});