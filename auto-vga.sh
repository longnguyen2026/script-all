
#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$HOME/.local/bin"
AUTO_DIR="$HOME/.config/autostart"
SCRIPT="$APP_DIR/pos-display-resolution.sh"
DESKTOP="$AUTO_DIR/pos-display-resolution.desktop"

if [[ "${1:-}" == "--remove" ]]; then
    rm -f "$SCRIPT" "$DESKTOP"
    echo "Đã gỡ cấu hình tự động."
    exit 0
fi

if ! command -v xrandr >/dev/null 2>&1; then
    echo "Lỗi: chưa có xrandr."
    exit 1
fi

mkdir -p "$APP_DIR" "$AUTO_DIR"

cat > "$SCRIPT" <<'RESOLUTION_SCRIPT'
#!/usr/bin/env bash
set -u

STATE="$HOME/.local/state"
LOG="$STATE/pos-display-resolution.log"
mkdir -p "$STATE"
exec >> "$LOG" 2>&1

echo "=== $(date) ==="
sleep 5

if ! command -v xrandr >/dev/null 2>&1; then
    echo "Không tìm thấy xrandr"
    exit 1
fi

# Lấy màn hình đang kết nối đầu tiên
OUTPUT="$(xrandr --query |
    awk '/ connected/ {print $1; exit}')"

if [[ -z "$OUTPUT" ]]; then
    echo "Không tìm thấy màn hình kết nối"
    exit 1
fi

echo "Màn hình: $OUTPUT"

# Đọc các mode được liệt kê dưới màn hình đó.
# Ưu tiên diện tích pixel lớn nhất, sau đó đến tần số cao nhất.
MODE="$(
    xrandr --query | awk -v out="$OUTPUT" '
        $1 == out && $2 == "connected" { active=1; next }
        /^[^ ]/ { active=0 }
        active && $1 ~ /^[0-9]+x[0-9]+$/ {
            mode=$1
            split(mode, a, "x")
            pixels=a[1]*a[2]
            refresh=0

            for (i=2; i<=NF; i++) {
                value=$i
                gsub(/[*+]/, "", value)
                if (value ~ /^[0-9]+(\.[0-9]+)?$/ && value+0 > refresh)
                    refresh=value+0
            }

            if (pixels > best_pixels ||
                (pixels == best_pixels && refresh > best_refresh)) {
                best_pixels=pixels
                best_refresh=refresh
                best_mode=mode
            }
        }
        END { if (best_mode != "") print best_mode }
    '
)"

if [[ -z "$MODE" ]]; then
    echo "Không tìm được độ phân giải phù hợp"
    exit 1
fi

echo "Độ phân giải được chọn: $MODE"

if xrandr --output "$OUTPUT" --mode "$MODE"; then
    echo "Đã áp dụng thành công: $OUTPUT $MODE"
else
    echo "Không thể áp dụng $MODE"
    exit 1
fi
RESOLUTION_SCRIPT

chmod +x "$SCRIPT"

cat > "$DESKTOP" <<EOF
[Desktop Entry]
Type=Application
Name=POS Display Resolution
Comment=Automatically select highest available display resolution
Exec=$SCRIPT
Terminal=false
X-GNOME-Autostart-enabled=true
EOF

echo "Đã cài cấu hình tự động cho user hiện tại."
echo "Đăng xuất rồi đăng nhập lại để thử."
echo "Log: ~/.local/state/pos-display-resolution.log"
