#!/usr/bin/env bash
set -euo pipefail

# Kiểm tra quyền root
if [[ $EUID -ne 0 ]]; then
   echo "❌ Vui lòng chạy script với quyền root (sudo bash ...)"
   exit 1
fi

echo "=== BẮT ĐẦU TỐI ƯU BỘ NHỚ & CHỐNG ĐỨNG MÁY ==="

# 1. Tính dung lượng RAM vật lý (làm tròn lên theo GB, tối thiểu 4GB, tối đa 16GB)
RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
RAM_GB=$(( (RAM_KB + 1048575) / 1048576 ))
[[ $RAM_GB -lt 4 ]] && SWAP_GB=4 || SWAP_GB=$RAM_GB
[[ $SWAP_GB -gt 16 ]] && SWAP_GB=16

# Kiểm tra dung lượng trống trên phân vùng / (tính bằng GB)
FREE_GB=$(df -BG / | awk 'NR==2 {print $4}' | tr -d 'G')
if [[ $FREE_GB -lt $((SWAP_GB + 3)) ]]; then
    echo "⚠️ Dung lượng trống ổ / chỉ còn ${FREE_GB}GB, không đủ tạo Swap ${SWAP_GB}GB (cần dư ít nhất 3GB)."
    exit 1
fi

echo "-> Phát hiện RAM vật lý: ~${RAM_GB}GB. Tiến hành thiết lập Swap cố định: ${SWAP_GB}GB..."

# 2. Tạo file Swap mới (/swapfile_new) trước để tránh dồn RAM ngược gây đơ máy khi đang chạy
NEW_SWAP="/swapfile_new"
rm -f "$NEW_SWAP"
fallocate -l "${SWAP_GB}G" "$NEW_SWAP" || dd if=/dev/zero of="$NEW_SWAP" bs=1M count=$((SWAP_GB * 1024)) status=none
chmod 600 "$NEW_SWAP"
mkswap "$NEW_SWAP" >/dev/null
swapon -p 10 "$NEW_SWAP"

# 3. Tắt toàn bộ Swap cũ và chuyển tên chuẩn về /swapfile
for s in $(swapon --noheadings --show=NAME); do
    if [[ "$s" != "$NEW_SWAP" ]]; then
        swapoff "$s" 2>/dev/null || true
    fi
done

# Xóa file swap cũ phổ biến nếu tồn tại
rm -f /swapfile /swap.img

# Đổi tên /swapfile_new thành /swapfile mà vẫn giữ trạng thái hoạt động
swapoff "$NEW_SWAP"
mv "$NEW_SWAP" /swapfile
chmod 600 /swapfile
swapon /swapfile

# 4. Cập nhật /etc/fstab (xóa các dòng swap file cũ bị trùng, ghi mới chuẩn)
cp /etc/fstab /etc/fstab.bak.$(date +%Y%m%d%H%M%S)
sed -i '/\/swapfile/d; /\/swap\.img/d; /\/swapfile_new/d' /etc/fstab
echo '/swapfile none swap sw 0 0' >> /etc/fstab

# 5. Tinh chỉnh vm.swappiness=15 để ưu tiên RAM vật lý
echo 'vm.swappiness=15' > /etc/sysctl.d/99-swappiness.conf
sysctl -p /etc/sysctl.d/99-swappiness.conf >/dev/null

# 6. Cài đặt và kích hoạt earlyoom chống treo cứng giao diện
if ! command -v earlyoom >/dev/null 2>&1; then
    echo "-> Đang cài đặt earlyoom..."
    apt-get update -qq || true
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq earlyoom
fi
systemctl enable --now earlyoom >/dev/null 2>&1

# 7. Dọn dẹp service limit-camera cũ (nếu có)
if systemctl list-unit-files | grep -q "limit-camera.service"; then
    systemctl disable --now limit-camera.service 2>/dev/null || true
    rm -f /etc/systemd/system/limit-camera.service
    systemctl daemon-reload
fi

echo ""
echo "✅ HOÀN TẤT CẤU HÌNH! Trạng thái bộ nhớ hiện tại:"
free -h
echo "-> Trạng thái earlyoom: $(systemctl is-active earlyoom)"
