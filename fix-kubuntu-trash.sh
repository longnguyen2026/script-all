
#!/usr/bin/env bash
#
# FIX KUBUNTU TRASH - LONG PRO
# Version: 1.0.0
# Support: Kubuntu / Ubuntu KDE Plasma
# Purpose: Fix incorrect permissions in user's Trash
#

set -Eeuo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

TRASH="$HOME/.local/share/Trash"

echo
echo "======================================================"
echo "       KUBUNTU TRASH REPAIR - LONG PRO"
echo "======================================================"
echo

# Check user
if [[ "$EUID" -eq 0 ]]; then
    echo -e "${RED}Không chạy script bằng sudo.${NC}"
    echo "Hãy chạy bằng tài khoản người dùng thông thường."
    exit 1
fi

# Create Trash directories if missing
for DIR in "$TRASH" "$TRASH/files" "$TRASH/info"; do
    if [[ -L "$DIR" ]]; then
        echo -e "${RED}Lỗi: Phát hiện symbolic link: $DIR${NC}"
        exit 1
    fi
done

mkdir -p "$TRASH/files" "$TRASH/info"

# Verify ownership before changing permissions
for DIR in "$TRASH" "$TRASH/files" "$TRASH/info"; do
    OWNER=$(stat -c '%u' "$DIR")

    if [[ "$OWNER" != "$UID" ]]; then
        echo -e "${RED}Lỗi: $DIR không thuộc quyền sở hữu của $USER.${NC}"
        echo "Owner UID: $OWNER | Current UID: $UID"
        echo "Không tự động thay đổi chủ sở hữu."
        exit 1
    fi
done

echo -e "${CYAN}[1/3] Đang sửa quyền thư mục Trash...${NC}"

chmod 700 "$TRASH"
chmod 700 "$TRASH/files"
chmod 700 "$TRASH/info"

echo -e "${GREEN}[2/3] Đã chuẩn hóa quyền thành 700.${NC}"

echo
echo "Kiểm tra kết quả:"
stat -c '%A %U:%G %n' \
    "$TRASH" \
    "$TRASH/files" \
    "$TRASH/info"

echo
echo -e "${GREEN}[3/3] HOÀN TẤT!${NC}"
echo
echo "Thùng rác đã được kiểm tra và sửa quyền."
echo "Không xóa dữ liệu bên trong Trash."
echo "Không thay đổi cấu hình Dolphin hoặc KDE."
echo
echo "Hãy thử xóa một file bằng phím Delete."
echo
