
#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$HOME/.local/bin"
AUTO_DIR="$HOME/.config/autostart"
SCRIPT="$APP_DIR/pos-display-resolution.sh"
DESKTOP="$AUTO_DIR/pos-display-resolution.desktop"
LOG="$HOME/.local/state/pos-display-resolution.log"

# Gỡ cấu hình: ./install-pos-resolution.sh --remove
if [[ "${1:-}" == "--remove" ]]; then
    rm -f "$SCRIPT" "$DESKTOP"
    echo "Đã gỡ cấu hình tự động đổi độ phân giải."
    echo "Khởi động lại hoặc đăng xuất để hoàn tất."
    exit 0
fi

if ! command -v xrandr >/dev/null 2>&1; then
    echo "Lỗi: không tìm thấy xrandr."
    exit 1
fi

mkdir -p "$APP_DIR" "$AUTO_DIR" "$(dirname "$LOG")"

cat > "$SCRIPT" <<'RESOLUTION_SCRIPT'
#!/usr/bin/env bash
set -u

LOG="$HOME/.local/state/pos-display-resolution.log"
mkdir -p "$(dirname "$LOG")"
exec >> "$LOG" 2>&1

echo "=== $(date) ==="

if ! command -v xrandr >/dev/null 2>&1; then
    echo "Không tìm thấy xrandr"
    exit 1
fi

# Đợi Cinnamon và màn hình khởi tạo
sleep 5

# Tìm màn hình đang kết nối
OUTPUT="$(xrandr --query |
    awk '/ connected/ {print $1; exit}')"

if [[ -z "$OUTPUT" ]]; then
    echo "Không tìm thấy màn hình đang kết nối"
    exit 1
fi

echo "Màn hình: $OUTPUT"

# Chỉ áp dụng nếu màn hình hỗ trợ 1024x768
if xrandr --query |
   awk -v out="$OUTPUT" '
       $1 == out { active=1; next }
       /^[^ ]/ { active=0 }
       active && $1 == "1024x768" { found=1 }
       END { exit !found }
   '; then
    if xrandr --output "$OUTPUT" --mode 1024x768; then
        echo "Đã đặt 1024x768 thành công"
    else
        echo "Không thể đổi độ phân giải"
        exit 1
    fi
else
    echo "Màn hình không công bố chế độ 1024x768; không ép độ phân giải"
    exit 1
fi
RESOLUTION_SCRIPT

chmod +x "$SCRIPT"

cat > "$DESKTOP" <<EOF
[Desktop Entry]
Type=Application
Name=POS Display Resolution
Comment=Set POS screen resolution at Cinnamon login
Exec=$SCRIPT
Terminal=false
X-GNOME-Autostart-enabled=true
EOF

echo "Đã cài cấu hình tự động."
echo "Script: $SCRIPT"
echo "Autostart: $DESKTOP"
echo "Log: $LOG"
echo "Đăng xuất rồi đăng nhập lại để kiểm tra."