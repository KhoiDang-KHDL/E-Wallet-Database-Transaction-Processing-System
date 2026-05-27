// src/utils/auth_storage.ts
// Biến lưu token tạm thời trong bộ nhớ RAM khi app đang chạy
let userToken: string = '';

export const setToken = (token: string) => {
  userToken = token;
};

export const getToken = () => {
  return userToken;
};