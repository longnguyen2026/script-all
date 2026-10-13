#!/usr/bin/env bash
# ==============================================================================
# Linux Mint System Freeze & Resource Monitor Installer
# Tự động ghi log tài nguyên mỗi 10s để bắt lỗi treo máy/tràn RAM
# ==============================================================================

set -e

# Kiểm tra quyền root
if [ "$EUID" -ne 0 ]; then
    echo "[-] Vui lòng chạy script với quyền sudo/root!"
    exit 1
fi

MONITOR_SCRIPT="/usr/local/bin/sys_monitor.sh"
SERVICE_FILE="/etc/systemd/system/sys-monitor.service"
CHECK_CMD="/usr/local/bin/check-hang"
UNINSTALL_CMD="/usr/local/bin/uninstall-monitor"
LOG_DIR="/var/log/sys_monitor"

echo "[+] 1/4 Đang tạo script giám sát tại $MONITOR_SCRIPT..."
cat << 'EOF' > "$MONITOR_SCRIPT"
#!/usr/bin/env bash

LOG_DIR="/var/log/sys_monitor"
LOG_FILE="$LOG_DIR/sys_freeze.log"
MAX_LINES=50000

mkdir -p "$LOG_DIR"

while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    MEM_INFO=$(free -h | awk 'NR==2{printf "RAM: Used %s / Total %s (Free: %s, Avail: %s)", $3, $2, $4, $7} NR==3{printf " | Swap: Used %s / Total %s", $3, $2}')
    
    {
        echo "=================================================================="
        echo "[$TIMESTAMP] $MEM_INFO"
        echo "------------------------------------------------------------------"
        echo "USER       PID   %CPU  %MEM    VSZ    RSS COMMAND"
        ps -eo user,pid,%cpu,%mem,vsz,rss,comm --sort=-%mem | head -n 6
        echo ""
    } >> "$LOG_FILE"

    sync

    if [ -f "$LOG_FILE" ]; then
        LINE_COUNT=$(wc -l < "$LOG_FILE")
        if [ "$LINE_COUNT" -gt "$MAX_LINES" ]; then
            tail -n 25000 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
        fi
    fi

    sleep 10
done
EOF

chmod +x "$MONITOR_SCRIPT"

echo "[+] 2/4 Đang cấu hình systemd service..."
cat << 'EOF' > "$SERVICE_FILE"
[Unit]
Description=Realtime System Resource Monitor for Hang Diagnosis
After=multi-user.target

[Service]
Type=simple
ExecStart=/usr/local/bin/sys_monitor.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo "[+] 3/4 Tạo lệnh tắt tiện ích: 'check-hang' và 'uninstall-monitor'..."
# Lệnh check nhanh log khi máy vừa mở lại
cat << 'EOF' > "$CHECK_CMD"
#!/usr/bin/env bash
LOG_FILE="/var/log/sys_monitor/sys_freeze.log"
if [ ! -f "$LOG_FILE" ]; then
    echo "[-] Chưa tìm thấy file log tại $LOG_FILE"
    exit 1
fi
echo "=== 35 DÒNG LOG CUỐI CÙNG TRƯỚC KHI TREO MÁY ==="
tail -n 35 "$LOG_FILE"
EOF
chmod +x "$CHECK_CMD"

# Lệnh gỡ bỏ sạch sẽ khi không cần dùng nữa
cat << 'EOF' > "$UNINSTALL_CMD"
#!/usr/bin/env bash
if [ "$EUID" -ne 0 ]; then
    echo "[-] Vui lòng chạy với sudo!"
    exit 1
fi
systemctl stop sys-monitor.service 2>/dev/null || true
systemctl disable sys-monitor.service 2>/dev/null || true
rm -f /etc/systemd/system/sys-monitor.service
rm -f /usr/local/bin/sys_monitor.sh
rm -f /usr/local/bin/check-hang
rm -f /usr/local/bin/uninstall-monitor
rm -rf /var/log/sys_monitor
systemctl daemon-reload
echo "[+] Đã gỡ bỏ toàn bộ sys-monitor thành công!"
EOF
chmod +x "$UNINSTALL_CMD"

echo "[+] 4/4 Khởi động dịch vụ..."
systemctl daemon-reload
systemctl enable --now sys-monitor.service

echo "=================================================================="
echo "[V] CÀI ĐẶT THÀNH CÔNG!"
echo " - Dịch vụ sys-monitor đang chạy ngầm mỗi 10 giây."
echo " - Khi máy bị treo bật lại, chỉ cần gõ lệnh: check-hang"
echo " - Nếu muốn gỡ cài đặt sau này, gõ lệnh: sudo uninstall-monitor"
echo "=================================================================="
