cat << 'EOF' > unshare-printer.sh
#!/bin/bash

# Kích hoạt chế độ dừng nếu có lỗi
set -e

echo "=== SCRIPT GỠ BỎ & TẮT CHIA SẺ MÁY IN CUPS ==="

# 1. Kiểm tra xem CUPS có hoạt động không
if ! command -v lpstat > /dev/null; then
    echo "❌ CUPS chưa được cài đặt trên hệ thống."
    exit 1
fi

# 2. Lấy danh sách máy in hiện có
PRINTER_LIST=$(lpstat -p 2>/dev/null | awk '{print $2}')

if [ -z "$PRINTER_LIST" ]; then
    echo "ℹ️  Không tìm thấy máy in nào đang được cấu hình trong hệ thống CUPS."
    exit 0
fi

echo "Danh sách các máy in hiện tại trong hệ thống:"
echo "----------------------------------------------------------"
index=1
declare -A PRINTER_MAP

while read -r printer; do
    echo " [$index] $printer"
    PRINTER_MAP[$index]="$printer"
    ((index++))
done <<< "$PRINTER_LIST"

echo " [$index] ⚠️  Xóa TẤT CẢ máy in khỏi CUPS"
echo " [0] Thoát"
echo "----------------------------------------------------------"

read -p "Nhập lựa chọn của bạn (0-$index): " choice

# Xử lý lựa chọn người dùng
if [ "$choice" -eq 0 ] 2>/dev/null; then
    echo "Hủy thao tác."
    exit 0
elif [ "$choice" -eq "$index" ] 2>/dev/null; then
    echo "⚠️  Đang tiến hành xóa TẤT CẢ máy in..."
    for p in "${PRINTER_MAP[@]}"; do
        echo "-> Đang xóa máy in: $p"
        sudo lpadmin -x "$p"
    done
elif [ -n "${PRINTER_MAP[$choice]}" ]; then
    SELECTED_PRINTER="${PRINTER_MAP[$choice]}"
    echo "-> Đang xóa máy in: $SELECTED_PRINTER"
    sudo lpadmin -x "$SELECTED_PRINTER"
else
    echo "❌ Lựa chọn không hợp lệ."
    exit 1
fi

# 3. Hỏi tùy chọn hủy chia sẻ mạng (Mở lại quyền riêng tư CUPS)
echo ""
read -p "Bạn có muốn TẮT tính năng chia sẻ máy in qua mạng LAN (Remote Access) của CUPS không? (y/N): " disable_remote

if [[ "$disable_remote" =~ ^[Yy]$ ]]; then
    echo "-> Đang tắt tính năng chia sẻ mạng cho CUPS..."
    sudo cupsctl --no-share-printers --no-remote-any --no-remote-admin
    
    # Đưa về lại Listen localhost:631
    if grep -q "Listen \*:631" /etc/cups/cupsd.conf; then
        sudo sed -i 's/Listen \*:631/Listen localhost:631/' /etc/cups/cupsd.conf
    fi
fi

# 4. Khởi động lại dịch vụ CUPS để áp dụng thay đổi
echo "-> Đang khởi động lại dịch vụ CUPS..."
sudo systemctl restart cups

echo ""
echo "=========================================================="
echo "✅ HOÀN TẤT GỠ BỎ MÁY IN!"
echo "=========================================================="
EOF

chmod +x unshare-printer.sh
