#!/bin/bash

# Script để tạo tài khoản admin
# Sử dụng: bash setup-admin.sh

echo "🎵 Music App - Setup Admin Account"
echo "=================================="
echo ""

# Kiểm tra Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js không được cài đặt"
    exit 1
fi

echo "✅ Node.js được tìm thấy"
echo ""

# Chạy script tạo admin
echo "📝 Đang tạo tài khoản admin..."
echo ""

node src/utils/createAdmin.js

if [ $? -eq 0 ]; then
    echo ""
    echo "✨ Hoàn thành! Bạn có thể đăng nhập với:"
    echo "   Email: admin@gmail.com"
    echo "   Password: 123456"
    echo ""
    echo "⚠️  Lưu ý: Hãy đổi mật khẩu sau khi đăng nhập lần đầu!"
else
    echo ""
    echo "❌ Có lỗi xảy ra. Kiểm tra kết nối database."
fi

