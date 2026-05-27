import { Ionicons } from '@expo/vector-icons';
import { CameraView, useCameraPermissions } from 'expo-camera';
import { useRouter } from 'expo-router';
import { useState } from 'react';
import { Alert, StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import { Colors } from '../../../src/constants/Colors';

export default function ScanQRScreen() {
  const router = useRouter();
  const [permission, requestPermission] = useCameraPermissions();
  const [scanned, setScanned] = useState(false);
  const [facing, setFacing] = useState<'back' | 'front'>('back');
  const [torch, setTorch] = useState(false); // Bật/tắt đèn Flash

  // Kiểm tra quyền truy cập Camera khi vào trang
  if (!permission) {
    // Đang tải dữ liệu quyền
    return <View style={styles.container} />;
  }

  if (!permission.granted) {
    // Nếu chưa cấp quyền, hiển thị nút yêu cầu cấp quyền
    return (
      <View style={styles.container}>
        <Text style={styles.textCenter}>App cần bạn cấp quyền truy cập Camera để quét mã QR</Text>
        <TouchableOpacity style={styles.permissionButton} onPress={requestPermission}>
          <Text style={styles.permissionButtonText}>Cấp quyền Camera</Text>
        </TouchableOpacity>
      </View>
    );
  }

  // Hàm xử lý khi camera đọc được mã QR
  const handleBarcodeScanned = ({ type, data }: { type: string; data: string }) => {
    if (scanned) return; // Nếu đang xử lý rồi thì bỏ qua các lượt quét trùng
    setScanned(true);

    // Giả lập đọc dữ liệu QR (ví dụ QR chứa số điện thoại hoặc link thanh toán)
    Alert.alert(
      "Quét thành công!",
      `Dữ liệu mã QR: ${data}`,
      [
        { 
          text: "Chuyển tiền ngay", 
          onPress: () => {
            setScanned(false);
            // Sau này quét xong sẽ truyền dữ liệu SĐT qua trang chuyển tiền
            router.push('/(transaction)/transfer'); 
          }
        },
        { text: "Quét lại", onPress: () => setScanned(false), style: "cancel" }
      ]
    );
  };

  return (
    <View style={styles.container}>
      {/* 1. Trình xem Camera */}
      <CameraView
        style={StyleSheet.absoluteFill}
        facing={facing}
        enableTorch={torch}
        onBarcodeScanned={handleBarcodeScanned}
        barcodeScannerSettings={{
          barcodeTypes: ['qr'], // Chỉ nhận diện duy nhất mã QR
        }}
      >
        {/* 2. Lớp phủ Giao diện (Overlay) */}
        <View style={styles.overlayContainer}>
          
          {/* Thay thế nút quay lại bằng khoảng trống để giữ nguyên bố cục không bị lệch */}
          <View style={styles.topSpace} />

          {/* Khung vuông ở giữa để người dùng căn mã QR vào */}
          <View style={styles.maskContainer}>
            <Text style={styles.scanText}>Di chuyển camera đến vùng có mã QR</Text>
            <View style={styles.qrTargetBox}>
              {/* Vẽ 4 góc vuông cho đẹp mắt */}
              <View style={[styles.corner, styles.topLeft]} />
              <View style={[styles.corner, styles.topRight]} />
              <View style={[styles.corner, styles.bottomLeft]} />
              <View style={[styles.corner, styles.bottomRight]} />
            </View>
          </View>

          {/* Thanh công cụ phía dưới (Nút Flash) */}
          <View style={styles.bottomTools}>
            <TouchableOpacity 
              style={[styles.toolButton, torch && styles.toolButtonActive]} 
              onPress={() => setTorch(!torch)}
            >
              <Ionicons name={torch ? "flash" : "flash-off"} size={24} color="#fff" />
              <Text style={styles.toolText}>Flash</Text>
            </TouchableOpacity>
          </View>
        </View>
      </CameraView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background,
    justifyContent: 'center',
    alignItems: 'center',
  },
  textCenter: {
    color: '#ffffff',
    textAlign: 'center',
    fontSize: 16,
    marginBottom: 20,
    paddingHorizontal: 40,
  },
  permissionButton: {
    backgroundColor: Colors.primary,
    paddingVertical: 12,
    paddingHorizontal: 24,
    borderRadius: 8,
  },
  permissionButtonText: {
    color: '#ffffff',
    fontWeight: 'bold',
    fontSize: 16,
  },
  overlayContainer: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.4)', // Làm tối mờ xung quanh camera
    justifyContent: 'space-between',
  },
  topSpace: {
    height: 45,       // Bằng chiều cao của nút bấm cũban đầu
    marginTop: 50,    // Giữ khoảng cách an toàn từ đỉnh màn hình xuống (tránh tai thỏ)
  },
  maskContainer: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  scanText: {
    color: '#ffffff',
    fontSize: 15,
    marginBottom: 20,
    fontWeight: '500',
    textShadowColor: 'rgba(0, 0, 0, 0.75)',
    textShadowOffset: {width: -1, height: 1},
    textShadowRadius: 10
  },
  qrTargetBox: {
    width: 250,
    height: 250,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.3)',
    position: 'relative',
    backgroundColor: 'transparent',
  },
  // Style vẽ 4 góc viền xanh cho giống app quét thực tế
  corner: {
    position: 'absolute',
    width: 20,
    height: 20,
    borderColor: Colors.primary,
  },
  topLeft: { top: -2, left: -2, borderTopWidth: 4, borderLeftWidth: 4 },
  topRight: { top: -2, right: -2, borderTopWidth: 4, borderRightWidth: 4 },
  bottomLeft: { bottom: -2, left: -2, borderBottomWidth: 4, borderLeftWidth: 4 },
  bottomRight: { bottom: -2, right: -2, borderBottomWidth: 4, borderRightWidth: 4 },
  
  bottomTools: {
    flexDirection: 'row',
    justifyContent: 'center',
    marginBottom: 160,
  },
  toolButton: {
    alignItems: 'center',
    padding: 12,
    borderRadius: 12,
    backgroundColor: 'transparent',
    minWidth: 80,
  },
  toolButtonActive: {
    backgroundColor: Colors.primary,
  },
  toolText: {
    color: '#ffffff',
    fontSize: 12,
    marginTop: 4,
  },
});