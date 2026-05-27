import { ActivityIndicator, StyleSheet, Text, TouchableOpacity, TouchableOpacityProps } from 'react-native';

interface ButtonProps extends TouchableOpacityProps {
  title: string;
  loading?: boolean; // Hiển thị vòng xoay khi đang xử lý (ví dụ: đang đăng nhập)
}

export function Button({ title, style, loading, disabled, ...rest }: ButtonProps) {
  return (
    <TouchableOpacity 
      style={[styles.button, disabled && styles.disabled, style]} 
      disabled={disabled || loading}
      activeOpacity={0.7}
      {...rest}
    >
      {loading ? (
        <ActivityIndicator color="#fff" />
      ) : (
        <Text style={styles.text}>{title}</Text>
      )}
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  button: {
    backgroundColor: '#10B981', // Màu xanh đặc trưng ví điện tử
    paddingVertical: 14,
    paddingHorizontal: 24,
    borderRadius: 12, // Bo góc hiện đại
    alignItems: 'center',
    justifyContent: 'center',
    width: '100%',
    shadowColor: '#10B981',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.2,
    shadowRadius: 4,
    elevation: 3, // Tạo bóng đổ trên Android
  },
  disabled: {
    backgroundColor: '#A7F3D0', // Màu mờ khi bị disable
  },
  text: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '700',
  },
});