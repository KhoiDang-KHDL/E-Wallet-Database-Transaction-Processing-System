// src/context/AuthContext.tsx
import { createContext, ReactNode, useContext, useState } from 'react';
import { Platform } from 'react-native';

// Định nghĩa kiểu dữ liệu cho Context
interface AuthContextType {
  token: string | null;
  isLoading: boolean;
  login: (phone: string, password: string) => Promise<boolean>;
  register: (payload: any) => Promise<boolean>;
  logout: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

// Địa chỉ IP Backend (Đổi lại theo IP máy của bạn khi chạy máy thật)
const API_BASE_URL = 'http://10.0.2.2:8000';

export function AuthProvider({ children }: { children: ReactNode }) {
  const [token, setToken] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  // 1. HÀM ĐĂNG NHẬP (Khớp endpoint /auth/login)
  const login = async (phone: string, password: string): Promise<boolean> => {
    setIsLoading(true);
    try {
      const response = await fetch(`${API_BASE_URL}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          phone,
          password,
          device_info: Platform.OS === 'ios' ? 'iOS App' : 'Android App',
        }),
      });

      const data = await response.json();

      if (response.ok && data.access_token) {
        setToken(data.access_token); // Lưu token toàn cục để các API sau này đính kèm vào Header
        return true;
      } else {
        alert(data.detail || 'Số điện thoại hoặc mật khẩu không chính xác!');
        return false;
      }
    } catch (error) {
      console.error('Login Error:', error);
      alert('Không thể kết nối đến máy chủ.');
      return false;
    } finally {
      setIsLoading(false);
    }
  };

  // 2. HÀM ĐĂNG KÝ HOÀN TẤT (Khớp endpoint /auth/register)
  const register = async (payload: any): Promise<boolean> => {
    setIsLoading(true);
    try {
      const response = await fetch(`${API_BASE_URL}/auth/register`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });

      const data = await response.json();

      if (response.ok) {
        return true;
      } else {
        alert(data.detail || 'Đăng ký thất bại. Vui lòng thử lại!');
        return false;
      }
    } catch (error) {
      console.error('Register Error:', error);
      alert('Lỗi kết nối hệ thống đăng ký.');
      return false;
    } finally {
      setIsLoading(false);
    }
  };

  // 3. HÀM ĐĂNG XUẤT (Khớp endpoint /auth/logout)
  const logout = async () => {
    if (!token) return;
    setIsLoading(true);
    try {
      await fetch(`${API_BASE_URL}/auth/logout`, {
        method: 'POST',
        headers: { 
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json' 
        },
      });
    } catch (error) {
      console.error('Logout Error:', error);
    } finally {
      setToken(null); // Xóa token khỏi frontend dù API có lỗi hay không
      setIsLoading(false);
    }
  };

  return (
    <AuthContext.Provider value={{ token, isLoading, login, register, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

// Custom Hook để gọi nhanh ở các màn hình
export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth phải được đặt trong AuthProvider');
  }
  return context;
}
