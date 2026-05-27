// src/app/(transaction)/list_voucher.tsx
import { Ionicons } from '@expo/vector-icons';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { useEffect, useState } from 'react';
import { ActivityIndicator, Platform, RefreshControl, ScrollView, StyleSheet, Text, TouchableOpacity, View } from 'react-native';

// Import cấu hình API và token xác thực
import { API_URL } from '../../utils/api';
import { getToken } from '../../utils/auth_storage';

export default function ListVoucherScreen() {
  const router = useRouter();
  
  // 🌟 ĐÃ CẬP NHẬT: Nhận thêm biến amount truyền từ trang trước sang
  const { referrer, amount } = useLocalSearchParams<{ 
    referrer: 'transfer' | 'deposit';
    amount?: string; 
  }>();
  
  const currentTransactionType = referrer || 'transfer'; 
  // Chuyển đổi số tiền nhận được sang dạng số nguyên để tính toán, mặc định bằng 0 nếu chưa nhập
  const currentAmount = amount ? parseInt(amount) : 0;

  // Quản lý dữ liệu gọi từ Oracle DB
  const [vouchers, setVouchers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

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
      console.error("Lỗi tải kho voucher:", error);
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

  // Trả data ngược về lại trang trước đó (Đính kèm ngược lại cả amount cũ để trang trước ko bị mất data)
  const handleApplyVoucher = (voucherCode: string) => {
    const targetPath = currentTransactionType === 'deposit' 
      ? "/(transaction)/deposit" 
      : "/(transaction)/transfer";

    router.navigate({
      pathname: targetPath as any,
      params: { 
        voucher_code: voucherCode,
        amount: amount // Giữ lại số tiền cho màn hình trước
      } 
    });
  };

  const formatDiscountLabel = (item: any) => {
    if (item.discount_type === 'PERCENTAGE' || item.discount_type === '%') {
      return `Giảm ${item.discount_value}%`;
    }
    return `Giảm ${(item.discount_value).toLocaleString('vi-VN')}đ`;
  };

  const buildVoucherDesc = (item: any) => {
    let desc = `Giao dịch từ ${(item.min_order_value || 0).toLocaleString('vi-VN')}đ.`;
    if (item.max_discount && item.max_discount > 0) {
      desc += ` Tối đa ${item.max_discount.toLocaleString('vi-VN')}đ.`;
    }
    return desc;
  };

  if (loading) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#2563EB" />
        <Text style={styles.loadingText}>Đang quét ưu đãi khả dụng...</Text>
      </View>
    );
  }

  // 🌟 BƯỚC CẢI TIẾN CHÍNH: Lọc trực tiếp mảng voucher hợp lệ trước khi Render
  const applicableVouchers = vouchers.filter((item) => {
    // 1. Kiểm tra loại giao dịch (Nạp tiền vs Chuyển tiền)
    const isTopUpCode = item.code.toUpperCase().includes('NAP') || item.code.toUpperCase().includes('TOPUP');
    const isTypeMatch = currentTransactionType === 'deposit' ? isTopUpCode : !isTopUpCode;

    // 2. Kiểm tra điều kiện giá trị giao dịch tối thiểu (ví dụ: giao dịch phải >= 50,000đ)
    const minOrderValue = item.min_order_value || 0;
    const isAmountValid = currentAmount >= minOrderValue;

    // Chỉ giữ lại voucher thỏa mãn đồng thời cả 2 điều kiện
    return isTypeMatch && isAmountValid;
  });

  return (
    <View style={styles.container}>
      {/* HEADER */}
      <View style={styles.header}>
        <TouchableOpacity style={styles.backButton} onPress={() => router.back()}>
          <Ionicons name="arrow-back" size={24} color="#1F2937" />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Chọn mã ưu đãi</Text>
        <View style={{ width: 40 }} />
      </View>

      <ScrollView 
        contentContainerStyle={styles.scrollContent} 
        showsVerticalScrollIndicator={false}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} colors={['#2563EB']} />
        }
      >
        <View style={styles.infoBanner}>
          <Ionicons name="information-circle-outline" size={16} color="#1E40AF" />
          <Text style={styles.infoBannerText}>
            Đang hiển thị ưu đãi cho giao dịch: {currentAmount.toLocaleString('vi-VN')}đ
          </Text>
        </View>

        <Text style={styles.sectionNote}>Ưu đãi phù hợp với giao dịch của bạn</Text>

        {/* 🌟 ĐÃ THAY ĐỔI: Sử dụng danh sách đã qua bộ lọc applicableVouchers */}
        {applicableVouchers.length === 0 ? (
          <View style={styles.emptyContainer}>
            <Ionicons name="ticket-outline" size={48} color="#9CA3AF" />
            <Text style={styles.emptyText}>
              Không có mã giảm giá nào phù hợp với số tiền {currentAmount.toLocaleString('vi-VN')}đ của giao dịch hiện tại.
            </Text>
          </View>
        ) : (
          applicableVouchers.map((item) => {
            return (
              <TouchableOpacity
                key={item.voucher_id}
                style={styles.voucherCard} // 🌟 ĐÃ XÓA: Bỏ hoàn toàn disabled và class style mờ
                onPress={() => handleApplyVoucher(item.code)}
              >
                {/* Cột trái */}
                <View style={[styles.cardLeft, { backgroundColor: '#2563EB' }]}>
                  <Ionicons 
                    name={currentTransactionType === 'deposit' ? 'wallet' : 'arrow-forward-circle'} 
                    size={24} 
                    color="#fff" 
                  />
                  <Text style={styles.brandText} numberOfLines={1}>{item.code}</Text>
                </View>

                {/* Cột phải */}
                <View style={styles.cardRight}>
                  <View>
                    <Text style={styles.descText} numberOfLines={1}>{formatDiscountLabel(item)}</Text>
                    <Text style={styles.conditionText} numberOfLines={2}>{buildVoucherDesc(item)}</Text>
                    <Text style={styles.expiryText}>Hạn dùng: {item.valid_until ? item.valid_until.substring(0, 10) : 'Vô thời hạn'}</Text>
                  </View>
                  
                  <View style={styles.applyLabel}>
                    <Text style={styles.applyText}>Nhấn để áp dụng</Text>
                  </View>
                </View>

                {/* Hiệu ứng cắt răng cưa vé */}
                <View style={styles.cutoutTop} />
                <View style={styles.cutoutBottom} />
                <View style={styles.dashLine} />
              </TouchableOpacity>
            );
          })
        )}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#F9FAFB' },
  loadingContainer: { flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: '#F9FAFB' },
  loadingText: { marginTop: 12, fontSize: 14, color: '#6B7280', fontWeight: '500' },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingHorizontal: 16, height: 80, backgroundColor: '#fff', borderBottomWidth: 1, borderColor: '#E5E7EB', paddingTop: Platform.OS === 'ios' ? 0 : 20 },
  backButton: { padding: 8 },
  headerTitle: { fontSize: 18, fontWeight: '700', color: '#1F2937' },
  scrollContent: { padding: 20, paddingBottom: 40 },
  infoBanner: { flexDirection: 'row', alignItems: 'center', backgroundColor: '#EFF6FF', padding: 10, borderRadius: 10, marginBottom: 12, borderWidth: 1, borderColor: '#BFDBFE' },
  infoBannerText: { marginLeft: 6, fontSize: 13, color: '#1E40AF', fontWeight: '500' },
  sectionNote: { fontSize: 13, color: '#6B7280', fontWeight: '600', marginBottom: 16 },
  voucherCard: { flexDirection: 'row', backgroundColor: '#FFFFFF', borderRadius: 16, height: 120, marginBottom: 16, overflow: 'hidden', borderWidth: 1, borderColor: '#E5E7EB', position: 'relative', shadowColor: '#000', shadowOffset: { width: 0, height: 2 }, shadowOpacity: 0.01, shadowRadius: 4, elevation: 1 },
  cardLeft: { width: 90, justifyContent: 'center', alignItems: 'center', padding: 6 },
  brandText: { color: '#fff', fontSize: 11, fontWeight: '800', marginTop: 6, textAlign: 'center', textTransform: 'uppercase' },
  cardRight: { flex: 1, padding: 12, justifyContent: 'space-between' },
  descText: { fontSize: 15, fontWeight: '800', color: '#1F2937' },
  conditionText: { fontSize: 12, color: '#4B5563', marginTop: 2, lineHeight: 16 },
  expiryText: { fontSize: 11, color: '#9CA3AF', marginTop: 2 },
  applyLabel: { alignSelf: 'flex-start' },
  applyText: { fontSize: 12, fontWeight: '700', color: '#2563EB' },
  cutoutTop: { position: 'absolute', left: 82, top: -9, width: 16, height: 16, borderRadius: 8, backgroundColor: '#F9FAFB', borderWidth: 1, borderColor: '#E5E7EB' },
  cutoutBottom: { position: 'absolute', left: 82, bottom: -9, width: 16, height: 16, borderRadius: 8, backgroundColor: '#F9FAFB', borderWidth: 1, borderColor: '#E5E7EB' },
  dashLine: { position: 'absolute', left: 89.5, top: 12, bottom: 12, width: 1, borderStyle: 'dashed', borderWidth: 1, borderColor: '#E5E7EB' as any },
  emptyContainer: { alignItems: 'center', justifyContent: 'center', marginTop: 80, paddingHorizontal: 16 },
  emptyText: { marginTop: 12, color: '#6B7280', fontSize: 14, fontWeight: '500', textAlign: 'center', lineHeight: 20 }
});