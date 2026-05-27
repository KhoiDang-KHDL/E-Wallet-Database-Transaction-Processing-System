// app/(tabs)/_layout.tsx
import { Ionicons } from '@expo/vector-icons';
import { Tabs } from 'expo-router';
import { StyleSheet, View } from 'react-native';
import { Colors } from '../../constants/Colors';

export default function TabLayout() {
  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarShowLabel: true,
        // Cấu hình màu sắc chữ tổng quan
        tabBarActiveTintColor: Colors.primary, // Chữ khi được chọn sẽ có màu xanh chủ đạo
        tabBarInactiveTintColor: '#9CA3AF',    // Chữ khi chưa chọn màu xám
        tabBarLabelStyle: {
          fontSize: 12,
          fontWeight: '600',
          marginBottom: 10, // Đẩy chữ lên một chút cho cân đối
        },
        tabBarStyle: {
          height: 100, // Giảm chiều cao xuống một chút cho chuẩn UI thực tế
          backgroundColor: '#FFFFFF',
          borderTopWidth: 1,
          borderTopColor: '#E5E7EB',
          position: 'absolute', // Giúp hình tròn nhô hẳn lên trên màn hình chính được
        },
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          title: 'E-Wallet',
          tabBarIcon: ({ color, focused }) => (
            <View style={[styles.iconContainer, focused && styles.activeIcon]}>
              <Ionicons
                name={focused ? 'home' : 'home-outline'}
                size={24}
                color={focused ? Colors.primary : color}
              />
            </View>
          ),
        }}
      />

      <Tabs.Screen
        name="voucher"
        options={{
          title: 'Ưu đãi',
          tabBarIcon: ({ color, focused }) => (
            <View style={[styles.iconContainer, focused && styles.activeIcon]}>
              <Ionicons
                name={focused ? 'gift' : 'gift-outline'}
                size={24}
                color={focused ? Colors.primary : color}
              />
            </View>
          ),
        }}
      />

      <Tabs.Screen
        name="scan"
        options={{
          title: 'Quét mã QR',
          tabBarIcon: ({ color, focused }) => (
            <View style={[styles.iconContainer, focused && styles.activeIcon]}>
              <Ionicons
                name={focused ? 'qr-code' : 'qr-code-outline'}
                size={24}
                color={focused ? Colors.primary : color}
              />
            </View>
          ),
        }}
      />

      <Tabs.Screen
        name="history"
        options={{
          title: 'Lịch sử GD',
          tabBarIcon: ({ color, focused }) => (
            <View style={[styles.iconContainer, focused && styles.activeIcon]}>
              <Ionicons
                name={focused ? 'receipt' : 'receipt-outline'}
                size={24}
                color={focused ? Colors.primary : color}
              />
            </View>
          ),
        }}
      />

      <Tabs.Screen
        name="profile"
        options={{
          title: 'Hò sơ',
          tabBarIcon: ({ color, focused }) => (
            <View style={[styles.iconContainer, focused && styles.activeIcon]}>
              <Ionicons
                name={focused ? 'person' : 'person-outline'}
                size={24}
                color={focused ? Colors.primary : color}
              />
            </View>
          ),
        }}
      />
    </Tabs>
  );
}

const styles = StyleSheet.create({
  iconContainer: {
    width: 70, // 🌟 Giảm size xuống vừa vặn để ôm khít icon mà không đè chữ
    height: 70,
    borderRadius: 28, // Một nửa width/height để tạo thành hình tròn xịn
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: 4,
    paddingBottom: 5,
  },

  activeIcon: {
    backgroundColor: '#F3F4F6', // 🌟 Đổi sang màu xám siêu nhạt để tương phản với thanh trắng
    // 🌟 ĐỔ BÓNG CHO IOS
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.1,
    shadowRadius: 6,
    // 🌟 ĐỔ BÓNG CHO ANDROID
    elevation: 4,
  },
});