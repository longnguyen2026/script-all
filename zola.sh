#!/bin/bash

set -e

WORKER_URL="https://private-script-sentosa-9.cloud07622.workers.dev"

echo "============================================================="
echo "    CÀI ĐẶT FZALO PC VER 26.11.10 - Mật khẩu mới sentosa-9   "
echo "============================================================="
echo


# ============================================================
# KIỂM TRA ZALO / FZALO ĐÃ CÀI TRƯỚC KHI CÀI BẢN MỚI
# ============================================================

ZALO_PKGS=$(dpkg-query -W -f='${binary:Package}\n' 2>/dev/null \
    | grep -Ei '^(zalo|fzalo|zalux)(-linux-builder|-linux-darling|-linux|-mac)?(:|$)' \
    || true)

ZALO_INSTALLED=0
ZALO_VERSION=""

if [ -n "$ZALO_PKGS" ]; then
    ZALO_INSTALLED=1

    # Lấy phiên bản của package Zalo/Fzalo đầu tiên tìm được.
    FIRST_ZALO_PKG=$(printf '%s\n' "$ZALO_PKGS" | head -n 1)
    ZALO_VERSION=$(dpkg-query -W -f='${Version}' "$FIRST_ZALO_PKG" 2>/dev/null || true)
fi

# Trường hợp package không còn trong dpkg nhưng thư mục cài đặt vẫn tồn tại.
if [ "$ZALO_INSTALLED" -eq 0 ] && {
    [ -d "/opt/Zalo" ] || [ -d "/opt/zalo" ] || [ -d "/opt/zalo-linux" ] || \
    [ -d "/opt/fzalo" ] || [ -d "/opt/zalux" ] || [ -d "$HOME/.local/opt/zalux" ] || [ -d "$HOME/.local/opt/fzalo" ];
}; then
    ZALO_INSTALLED=1
    ZALO_VERSION="không xác định"
fi

if [ "$ZALO_INSTALLED" -eq 1 ]; then
    echo "================================"
    echo "   ZALO / FZALO ĐÃ ĐƯỢC CÀI ĐẶT "
    echo "================================"
    echo
    echo "Máy bạn đang có phiên bản: $ZALO_VERSION"
    echo
    echo "Bạn có muốn gỡ cài đặt Zalo/Fzalo cũ không?"
    echo
    echo "Nếu muốn gỡ bản cũ, bạn cần chọn Thoát ứng dụng trên khay đồng hồ trước và chọn 1"
    echo
    echo "  1. Gỡ bản cũ và tiếp tục hỏi cài bản mới"
    echo "  2. Hủy lệnh"
    echo

    while true; do
        read -rp "Lựa chọn [1-2]: " REMOVE_CHOICE

        case "$REMOVE_CHOICE" in
            1)
                echo
                echo "Đang gỡ Zalo / Fzalo cũ..."
                echo

                # Dừng các tiến trình đang chạy
                pkill -f '/opt/Zalo' 2>/dev/null || true
                pkill -f '/opt/zalo' 2>/dev/null || true
                pkill -f 'zalo-linux' 2>/dev/null || true
                pkill -f 'fzalo' 2>/dev/null || true
                pkill -f 'zalux' 2>/dev/null || true
                pkill -f '\.local/opt/zalux' 2>/dev/null || true
                pkill -f '\.local/opt/fzalo' 2>/dev/null || true

                # Gỡ đúng các package đã tìm thấy
                if [ -n "$ZALO_PKGS" ]; then
                    sudo apt purge -y $ZALO_PKGS
                fi

                # Xóa thư mục cài đặt hệ thống
                sudo rm -rf /opt/Zalo
                sudo rm -rf /opt/zalo
                sudo rm -rf /opt/zalo-linux
                sudo rm -rf /opt/fzalo
                sudo rm -rf /opt/zalux

                # Xóa thư mục cài đặt user-local (Fzalo/Zalux)
                rm -rf "$HOME/.local/opt/zalux"
                rm -rf "$HOME/.local/opt/fzalo"

                # Xóa launcher cá nhân
                rm -f "$HOME/.local/share/applications/zalo.desktop"
                rm -f "$HOME/.local/share/applications/zalo-linux.desktop"
                rm -f "$HOME/.local/share/applications/Zalo.desktop"
                rm -f "$HOME/.local/share/applications/ZaloMac.desktop"
                rm -f "$HOME/.local/share/applications/fzalo.desktop"
                rm -f "$HOME/.local/share/applications/zalux.desktop"

                # Xóa launcher hệ thống
                sudo rm -f /usr/share/applications/zalo.desktop
                sudo rm -f /usr/share/applications/zalo-linux.desktop
                sudo rm -f /usr/share/applications/Zalo.desktop
                sudo rm -f /usr/share/applications/ZaloMac.desktop
                sudo rm -f /usr/share/applications/fzalo.desktop
                sudo rm -f /usr/share/applications/zalux.desktop

                echo
                echo "================================"
                echo "    ĐÃ GỠ ỨNG DỤNG THÀNH CÔNG   "
                echo "================================"
                echo
                break
                ;;
            2)
                echo
                echo "Đã hủy lệnh. Không thay đổi ứng dụng hiện tại."
                unset PASSWORD
                exit 0
                ;;
            *)
                echo "Lựa chọn không hợp lệ. Vui lòng chọn 1 hoặc 2."
                ;;
        esac
    done

    echo
    echo "Máy bạn đã gỡ ứng dụng cũ thành công."
    echo "Bạn có muốn cài phiên bản mới không?"
    echo
    echo "Nếu cài phiên bản mới, cần nhập thêm mật khẩu cài đặt, chọn 1 nếu cài tiếp bản mới"
    echo
    echo "  1. Tiếp tục cài bản mới Fzalo"
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
                echo "Đã thoát. Ứng dụng cũ đã được gỡ và không cài bản mới."
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

read -rsp "Nhập mật khẩu cài đặt. Nhớ tắt bộ gõ tiếng việt : " PASSWORD
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
