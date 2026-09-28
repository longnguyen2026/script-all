cat << 'EOF' > share-usb-printer.sh
#!/bin/bash

# Kích hoạt chế độ dừng nếu có lỗi
set -e

echo "=== ĐANG CẤU HÌNH CHIA SẺ MÁY IN USB ==="

# 1. Cài đặt các gói cần thiết
echo "[1/5] Cài đặt CUPS và các công cụ..."
sudo apt update -y
sudo apt install -y cups cups-client system-config-printer avahi-daemon

# 2. Khởi động dịch vụ CUPS & Avahi
echo "[2/5] Bật dịch vụ CUPS và Avahi..."
sudo systemctl enable --now cups
sudo systemctl enable --now avahi-daemon

# 3. Cấu hình CUPS chia sẻ trong mạng LAN
echo "[3/5] Cấu hình CUPS cho phép truy cập từ máy khác..."
sudo cupsctl --share-printers --remote-any --remote-admin

# Thêm quyền lắng nghe trên cổng 631 nếu chưa có
if ! grep -q "Listen \*:631" /etc/cups/cupsd.conf; then
    sudo sed -i 's/Listen localhost:631/Listen \*:631/' /etc/cups/cupsd.conf
fi

sudo cupsctl --remote-any

# 4. Tìm và chia sẻ các máy in USB đang kết nối
echo "[4/5] Quét máy in kết nối qua cổng USB..."
USB_PRINTERS=$(lpinfo -v | grep "usb://" | awk '{print $2}')

if [ -z "$USB_PRINTERS" ]; then
    echo "⚠️  CẢNH BÁO: Không tìm thấy máy in USB nào đang bật/kết nối."
    echo "Vui lòng cắm cáp USB máy in, bật nguồn và chạy lại script."
else
    echo "Phát hiện máy in USB tại các cổng:"
    echo "$USB_PRINTERS"
    echo ""
    
    # Duyệt qua từng máy in USB tìm thấy
    echo "$USB_PRINTERS" | while read -r uri; do
        default_name=$(echo "$uri" | awk -F'/' '{print $NF}' | sed 's/[^a-zA-Z0-9_]/-/g')
        
        echo "----------------------------------------------------------"
        echo "📍 Tìm thấy máy in tại cổng: $uri"
        
        # 1. Tên máy in (Printer Name)
        read -p "1. Nhập TÊN chia sẻ (Mặc định: $default_name): " custom_name
        if [ -z "$custom_name" ]; then
            printer_name="$default_name"
        else
            printer_name=$(echo "$custom_name" | sed 's/[^a-zA-Z0-9_]/-/g')
        fi

        # 2. Vị trí đặt máy in (Location)
        read -p "2. Nhập VỊ TRÍ đặt máy in (Ví dụ: Phong Ke Toan, Tang 1) [Có thể bỏ trống]: " location_info

        # 3. Mô tả chi tiết (Description)
        read -p "3. Nhập MÔ TẢ chi tiết (Ví dụ: Canon LBP 2900 - In 2 mat) [Có thể bỏ trống]: " description_info

        echo "-> Đang tiến hành tạo và chia sẻ máy in: $printer_name..."
        
        # Thêm máy in vào CUPS với Driver phù hợp
        sudo lpadmin -p "$printer_name" -v "$uri" -E -m everywhere 2>/dev/null || \
        sudo lpadmin -p "$printer_name" -v "$uri" -E -m raw
        
        # Thêm thông tin Vị trí (Location) nếu người dùng có nhập
        if [ -n "$location_info" ]; then
            sudo lpadmin -p "$printer_name" -L "$location_info"
        fi

        # Thêm thông tin Mô tả (Description) nếu người dùng có nhập
        if [ -n "$description_info" ]; then
            sudo lpadmin -p "$printer_name" -D "$description_info"
        fi

        # Bật chế độ chia sẻ máy in qua mạng
        sudo lpadmin -p "$printer_name" -o printer-is-shared=true
    done
fi

# 5. Mở Cổng Firewall (UFW)
echo "[5/5] Cấu hình Firewall..."
if command -v ufw > /dev/null; then
    sudo ufw allow 631/tcp comment 'CUPS Printer Sharing'
    sudo ufw allow 5353/udp comment 'mDNS Avahi'
fi

# Reset CUPS để áp dụng thay đổi
sudo systemctl restart cups

HOST_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "=========================================================="
echo "✅ HOÀN TẤT CẤU HÌNH CHIA SẺ MÁY IN!"
echo "----------------------------------------------------------"
echo "Để kết nối máy in từ máy Linux khác trong cùng mạng LAN,"
echo "chạy lệnh sau trên máy đó:"
echo ""
echo -e "\033[1;32msudo apt install -y cups && sudo cupsctl --remote-any && sudo systemctl restart cups\033[0m"
echo ""
echo "Địa chỉ truy cập giao diện CUPS Web quản lý:"
echo "http://$HOST_IP:631/printers/"
echo "=========================================================="
EOF

chmod +x share-usb-printer.sh
