// src/app/linked_methods.tsx
import { Ionicons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import { useEffect, useState } from 'react';
import { ActivityIndicator, Alert, KeyboardAvoidingView, Modal, Platform, RefreshControl, ScrollView, StyleSheet, Text, TextInput, TouchableOpacity, View } from 'react-native';
import { Colors } from '../constants/Colors';

import { API_URL } from '../utils/api';
import { getToken } from '../utils/auth_storage';

export default function LinkedMethodsScreen() {
  const router = useRouter();

  // Các state quản lý dữ liệu từ Oracle DB
  const [methods, setMethods] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  // State quản lý Modal thêm thẻ mới
  const [isAddModalVisible, setIsAddModalVisible] = useState(false);
  const [providerName, setProviderName] = useState('');
  const [accountNumber, setAccountNumber] = useState('');
  const [isDefault, setIsDefault] = useState(false);
  const [submitting, setSubmitting] = useState(false);

  const token = getToken();
  const headers = {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`
  };

  // 1. API: LẤY DANH SÁCH TÀI KHOẢN NGÂN HÀNG LIÊN KẾT
  const fetchPaymentMethods = async () => {
    try {
      const res = await fetch(`${API_URL}/payment-methods`, { method: 'GET', headers });
      if (res.ok) {
        const data = await res.json();
        // Lọc hiển thị các tài khoản đang active
        setMethods(Array.isArray(data) ? data.filter((m: any) => m.is_active) : []);
      }
    } catch (error) {
      console.error("Lỗi tải danh sách thẻ:", error);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    fetchPaymentMethods();
  }, []);

  const onRefresh = () => {
    setRefreshing(true);
    fetchPaymentMethods();
  };

  // 2. API: THÊM LIÊN KẾT NGÂN HÀNG MỚI
  const handleAddPaymentMethod = async () => {
    if (!providerName || !accountNumber) {
      Alert.alert("Thông báo", "Vui lòng nhập tên Ngân hàng và Số tài khoản!");
      return;
    }

    setSubmitting(true);
    try {
      const res = await fetch(`${API_URL}/payment-methods`, {
        method: 'POST',
        headers,
        body: JSON.stringify({
          method_type: 'BANK_ACCOUNT',
          provider_name: providerName,
          masked_number: accountNumber, 
          is_default: isDefault
        })
      });

      if (res.ok) {
        Alert.alert("Thành công", "Liên kết tài khoản ngân hàng thành công!");
        setIsAddModalVisible(false);
        setProviderName('');
        setAccountNumber('');
        setIsDefault(false);
        fetchPaymentMethods();
      } else {
        const err = await res.json();
        Alert.alert("Lỗi", err.detail || "Không thể liên kết ngân hàng này.");
      }
    } catch (error) {
      Alert.alert("Lỗi", "Không thể kết nối đến máy chủ.");
    } finally {
      setSubmitting(false);
    }
  };

  // 3. API: ĐẶT NGÂN HÀNG MẶC ĐỊNH 
  const handleSetDefault = async (methodId: number) => {
    try {
      const res = await fetch(`${API_URL}/payment-methods/${methodId}/default`, {
        method: 'PUT',
        headers
      });
      if (res.ok) {
        fetchPaymentMethods(); 
      } else {
        const err = await res.json();
        Alert.alert("Thất bại", err.detail || "Không thể đặt làm mặc định.");
      }
    } catch (error) {
      console.error(error);
    }
  };

  // API: HỦY LIÊN KẾT NGÂN HÀNG 
  const handleUnlinkMethod = (methodId: number, bankName: string) => {
    Alert.alert(
      "Hủy liên kết",
      `Bạn có chắc chắn muốn ngừng liên kết tài khoản với ngân hàng ${bankName}?`,
      [
        { text: "Hủy bỏ", style: "cancel" },
        {
          text: "Xác nhận xóa",
          style: "destructive",
          onPress: async () => {
            try {
              const res = await fetch(`${API_URL}/payment-methods/${methodId}`, {
                method: 'DELETE',
                headers
              });
              if (res.ok) {
                Alert.alert("Thành công", "Đã hủy liên kết ngân hàng thành công.");
                fetchPaymentMethods();
              } else {
                const err = await res.json();
                Alert.alert("Lỗi", err.detail || "Không thể hủy liên kết.");
              }
            } catch (error) {
              Alert.alert("Lỗi", "Mất kết nối mạng.");
            }
          }
        }
      ]
    );
  };

  // Helper đổi màu sắc icon theo tên bank
  const getBankColor = (name: string) => {
    const lower = name?.toLowerCase() || '';
    if (lower.includes('vietcombank') || lower.includes('vcb')) return '#2563EB';
    if (lower.includes('techcombank') || lower.includes('tcb')) return '#EF4444';
    if (lower.includes('vietinbank')) return '#0284C7';
    return '#4B5563';
  };

  // Helper format hiển thị số đuôi (Masking số tài khoản phòng hờ)
  const maskBankAccount = (num: string) => {
    if (!num) return '•••• ••••';
    const clean = num.replace(/\s/g, '');
    if (clean.length <= 4) return clean;
    return `•••• ${clean.slice(-4)}`;
  };

  if (loading) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#2563EB" />
        <Text style={styles.loadingText}>Đang quét danh sách ngân hàng...</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>

      {/* DANH SÁCH THẺ/TÀI KHOẢN */}
      <ScrollView 
        contentContainerStyle={styles.scrollContent} 
        showsVerticalScrollIndicator={false}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} colors={['#2563EB']} />
        }
      >
        <Text style={styles.sectionTitle}>Tài khoản đã kết nối ({methods.length})</Text>

        {methods.length === 0 ? (
          <View style={styles.emptyContainer}>
            <Ionicons name="card-outline" size={54} color="#9CA3AF" />
            <Text style={styles.emptyText}>Bạn chưa liên kết tài khoản ngân hàng nào.</Text>
          </View>
        ) : (
          methods.map((item) => (
            <View key={item.method_id} style={styles.bankCard}>
              <View style={styles.cardInfoRow}>
                <View style={[styles.bankIconBg, { backgroundColor: getBankColor(item.provider_name) + '15' }]}>
                  <Ionicons name="business" size={24} color={getBankColor(item.provider_name)} />
                </View>
                <View style={styles.cardTextContent}>
                  <View style={{ flexDirection: 'row', alignItems: 'center' }}>
                    <Text style={styles.bankName}>{item.provider_name}</Text>
                    {item.is_default && (
                      <View style={styles.defaultBadge}>
                        <Text style={styles.defaultBadgeText}>Mặc định</Text>
                      </View>
                    )}
                  </View>
                  <Text style={styles.bankNumber}>{maskBankAccount(item.masked_number)}</Text>
                </View>
              </View>

              {/* THANH THAO TÁC (ĐẶT MẶC ĐỊNH / XÓA) */}
              <View style={styles.actionRow}>
                {!item.is_default ? (
                  <TouchableOpacity style={styles.actionBtn} onPress={() => handleSetDefault(item.method_id)}>
                    <Ionicons name="star-outline" size={16} color="#4B5563" />
                    <Text style={styles.actionBtnText}>Đặt mặc định</Text>
                  </TouchableOpacity>
                ) : (
                  <View style={styles.actionBtn}>
                    <Ionicons name="star" size={16} color="#F59E0B" />
                    <Text style={[styles.actionBtnText, { color: '#F59E0B' }]}>Đang sử dụng chính</Text>
                  </View>
                )}

                <TouchableOpacity 
                  style={[styles.actionBtn, { marginLeft: 'auto' }]} 
                  onPress={() => handleUnlinkMethod(item.method_id, item.provider_name)}
                >
                  <Ionicons name="trash-outline" size={16} color="#EF4444" />
                  <Text style={[styles.actionBtnText, { color: '#EF4444' }]}>Hủy liên kết</Text>
                </TouchableOpacity>
              </View>
            </View>
          ))
        )}
      </ScrollView>

      {/* NÚT THÊM LIÊN KẾT MỚI DƯỚI ĐÁY */}
      <TouchableOpacity style={styles.addCardButton} onPress={() => setIsAddModalVisible(true)}>
        <Ionicons name="add-circle" size={22} color="#FFFFFF" style={{ marginRight: 6 }} />
        <Text style={styles.addCardButtonText}>Liên kết ngân hàng mới</Text>
      </TouchableOpacity>

      {/* MODAL POPUP THÊM THẺ NHANH */}
      <Modal visible={isAddModalVisible} animationType="slide" transparent={true} onRequestClose={() => setIsAddModalVisible(false)}>
        <View style={styles.modalOverlay}>
          <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : 'height'} style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Liên kết ngân hàng</Text>
              <TouchableOpacity onPress={() => setIsAddModalVisible(false)} style={styles.closeBtn}>
                <Ionicons name="close" size={24} color="#1F2937" />
              </TouchableOpacity>
            </View>

            <View style={styles.modalBody}>
              <Text style={styles.inputLabel}>Tên ngân hàng phát hành</Text>
              <TextInput 
                style={styles.textInput} 
                placeholder="Ví dụ: Vietcombank, Techcombank..." 
                placeholderTextColor="#9CA3AF"
                value={providerName}
                onChangeText={setProviderName}
              />

              <Text style={styles.inputLabel}>Số tài khoản / Số thẻ ngân hàng</Text>
              <TextInput 
                style={styles.textInput} 
                placeholder="Nhập số tài khoản ngân hàng" 
                placeholderTextColor="#9CA3AF"
                keyboardType="number-pad"
                value={accountNumber}
                onChangeText={setAccountNumber}
              />

              {/* CHỌN MẶC ĐỊNH */}
              <TouchableOpacity style={styles.checkboxRow} activeOpacity={0.8} onPress={() => setIsDefault(!isDefault)}>
                <Ionicons name={isDefault ? "checkbox" : "square-outline"} size={22} color={Colors.primary} />
                <Text style={styles.checkboxLabel}>Đặt tài khoản này làm nguồn tiền mặc định</Text>
              </TouchableOpacity>

              <TouchableOpacity style={styles.submitButton} onPress={handleAddPaymentMethod} disabled={submitting}>
                {submitting ? <ActivityIndicator color="#FFF" /> : <Text style={styles.submitButtonText}>Xác nhận liên kết</Text>}
              </TouchableOpacity>
            </View>
          </KeyboardAvoidingView>
        </View>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#F9FAFB' },
  loadingContainer: { flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: '#F9FAFB' },
  loadingText: { marginTop: 12, fontSize: 14, color: '#6B7280', fontWeight: '500' },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingHorizontal: 16, height: 80, backgroundColor: '#FFFFFF', borderBottomWidth: 1, borderColor: '#E5E7EB', paddingTop: Platform.OS === 'ios' ? 0 : 20 },
  backButton: { padding: 4 },
  headerTitle: { fontSize: 18, fontWeight: '700', color: '#1F2937' },
  scrollContent: { padding: 20, paddingBottom: 100 },
  sectionTitle: { fontSize: 13, fontWeight: '700', color: '#6B7280', textTransform: 'uppercase', marginBottom: 16 },
  
  // Bank Card Style
  bankCard: { backgroundColor: '#FFFFFF', borderRadius: 20, padding: 16, borderWidth: 1, borderColor: '#E5E7EB', marginBottom: 16 },
  cardInfoRow: { flexDirection: 'row', alignItems: 'center', borderBottomWidth: 1, borderColor: '#F3F4F6', paddingBottom: 14 },
  bankIconBg: { width: 44, height: 44, borderRadius: 12, justifyContent: 'center', alignItems: 'center', marginRight: 14 },
  cardTextContent: { flex: 1 },
  bankName: { fontSize: 15, fontWeight: '700', color: '#1F2937' },
  bankNumber: { fontSize: 13, color: '#6B7280', marginTop: 4, fontWeight: '600' },
  
  defaultBadge: { backgroundColor: '#EFF6FF', paddingHorizontal: 8, paddingVertical: 2, borderRadius: 6, marginLeft: 8 },
  defaultBadgeText: { fontSize: 10, color: '#2563EB', fontWeight: '700' },
  
  actionRow: { flexDirection: 'row', alignItems: 'center', paddingTop: 12 },
  actionBtn: { flexDirection: 'row', alignItems: 'center', paddingVertical: 4, paddingHorizontal: 6 },
  actionBtnText: { fontSize: 12, fontWeight: '600', color: '#4B5563', marginLeft: 4 },

  addCardButton: { position: 'absolute', bottom: 70, left: 20, right: 20, backgroundColor: '#2563EB', height: 54, borderRadius: 16, flexDirection: 'row', justifyContent: 'center', alignItems: 'center', shadowColor: '#2563EB', shadowOffset: { width: 0, height: 4 }, shadowOpacity: 0.15, shadowRadius: 8, elevation: 4 },
  addCardButtonText: { color: '#FFFFFF', fontSize: 15, fontWeight: '700' },

  // Empty State
  emptyContainer: { alignItems: 'center', justifyContent: 'center', marginTop: 100 },
  emptyText: { marginTop: 12, color: '#9CA3AF', fontSize: 14, fontWeight: '500', textAlign: 'center', paddingHorizontal: 20 },

  // Modal CSS
  modalOverlay: { flex: 1, backgroundColor: 'rgba(0, 0, 0, 0.4)', justifyContent: 'flex-end' },
  modalContent: { backgroundColor: '#FFFFFF', borderTopLeftRadius: 24, borderTopRightRadius: 24, padding: 24, minHeight: 400, width: '100%' },
  modalHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20, borderBottomWidth: 1, borderColor: '#F3F4F6' },
  modalTitle: { fontSize: 17, fontWeight: '700', color: '#1F2937' },
  closeBtn: { padding: 4 },
  modalBody: { flex: 1 },
  inputLabel: { fontSize: 13, fontWeight: '600', color: '#4B5563', marginBottom: 8, marginTop: 10 },
  textInput: { backgroundColor: '#F9FAFB', borderRadius: 14, paddingHorizontal: 16, height: 50, borderWidth: 1, borderColor: '#E5E7EB', fontSize: 14, color: '#1F2937', fontWeight: '500', marginBottom: 16 },
  checkboxRow: { flexDirection: 'row', alignItems: 'center', marginVertical: 12, paddingHorizontal: 12 },
  checkboxLabel: { fontSize: 13, color: '#4B5563', fontWeight: '500', marginLeft: 8 },
  submitButton: { backgroundColor: '#2563EB', borderRadius: 16, height: 52, bottom: 30, justifyContent: 'center', alignItems: 'center', marginTop: 24, width: '100%' },
  submitButtonText: { color: '#FFFFFF', fontSize: 15, fontWeight: '700'}
});