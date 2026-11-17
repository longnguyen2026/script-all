#!/usr/bin/env bash
# LONG PRO 2.0 - Public launcher for the private Kubuntu menu

set -Eeuo pipefail

WORKER_URL="https://protect-menu.cloud07622.workers.dev/script"
PASSWORD_HINT="@1234567890"

NC=$'\033[0m'
BOLD=$'\033[1m'
BLUE=$'\033[38;5;39m'
CYAN=$'\033[38;5;51m'
WHITE=$'\033[97m'
GREEN=$'\033[38;5;82m'
YELLOW=$'\033[38;5;220m'
RED=$'\033[38;5;203m'
DIM=$'\033[2m'

if [[ ! -t 0 || ! -t 1 ]]; then
    echo "CÔNG CỤ HỖ TRỢ cần được chạy trực tiếp trong Terminal."
    echo "bash <(curl -fsSL https://raw.githubusercontent.com/longnguyen2026/script-all/main/menu.sh)"
    exit 1
fi

for cmd in curl python3; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Lỗi: Thiếu chương trình $cmd."
        exit 1
    fi
done

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/long-pro.XXXXXX")"
MENU_FILE="$TMP_DIR/menu.sh"
RESPONSE_FILE="$TMP_DIR/response.txt"

cleanup() {
    unset PASSWORD 2>/dev/null || true
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

show_header() {
    clear 2>/dev/null || true
    printf '%s' "$BLUE"
    cat <<'BANNER'
╔══════════════════════════════════════════════════════════════════════╗
║                                                                      ║
║  ██╗      ██████╗ ███╗   ██╗ ██████╗     ██████╗ ██████╗             ║
║  ██║     ██╔═══██╗████╗  ██║██╔════╝     ╚════██╗╚════██╗            ║
║  ██║     ██║   ██║██╔██╗ ██║██║  ███╗     █████╔╝ █████╔╝            ║
║  ██║     ██║   ██║██║╚██╗██║██║   ██║    ██╔═══╝  ╚═══██╗            ║
║  ███████╗╚██████╔╝██║ ╚████║╚██████╔╝    ███████╗██████╔╝            ║
║  ╚══════╝ ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝     ╚══════╝╚═════╝             ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝
BANNER
    printf '%s' "$NC"
    printf '%s%s%s\n' "$BOLD$WHITE" "          KUBUNTU MANAGEMENT SYSTEM  |  VERSION 2.0" "$NC"
    printf '%s\n' "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    printf '  %sHệ thống:%s CÔNG CỤ HỖ TRỢ       %sBảo vệ:%s %sCloud Secure Access%s\n' \
        "$DIM" "$NC" "$DIM" "$NC" "$GREEN" "$NC"
    printf '%s\n\n' "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

show_header
printf '  %s%sTRUNG TÂM TRUY CẬP CÔNG CỤ HỖ TRỢ%s\n\n' "$BOLD" "$WHITE" "$NC"
printf '  %sGợi ý mật khẩu:%s %s%s%s\n' "$DIM" "$NC" "$YELLOW" "$PASSWORD_HINT" "$NC"
printf '  %sMật khẩu được xác thực Cloud.%s\n\n' "$DIM" "$NC"

read -r -s -p "  ${BLUE}➜ Nhập mật khẩu truy cập: ${NC}" PASSWORD
printf '\n\n'

if [[ -z "$PASSWORD" ]]; then
    printf '  %s✖ Bạn chưa nhập mật khẩu.%s\n' "$RED" "$NC"
    exit 1
fi

printf '  %s⟳ Đang kết nối Cloud và xác thực...%s\n' "$CYAN" "$NC"

HTTP_CODE="$(
    printf '%s' "$PASSWORD" |
    python3 -c 'import json,sys; print(json.dumps({"password":sys.stdin.read()}))' |
    curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
        -X POST -H 'Content-Type: application/json' \
        --data-binary @- "$WORKER_URL"
)" || {
    printf '  %s✖ Không thể kết nối Cloud. Kiểm tra Internet.%s\n' "$RED" "$NC"
    exit 1
}
unset PASSWORD

case "$HTTP_CODE" in
    200)
        if [[ ! -s "$RESPONSE_FILE" ]]; then
            printf '  %s✖ Cloud trả về nội dung rỗng.%s\n' "$RED" "$NC"
            exit 1
        fi
        mv "$RESPONSE_FILE" "$MENU_FILE"
        ;;
    400)
        printf '  %s✖ Yêu cầu không hợp lệ.%s\n' "$RED" "$NC"
        exit 1
        ;;
    401)
        printf '  %s✖ Mật khẩu không đúng. Truy cập bị từ chối.%s\n' "$RED" "$NC"
        exit 1
        ;;
    *)
        printf '  %s✖ Lỗi HTTP %s từ Cloud/GitHub.%s\n' "$RED" "$HTTP_CODE" "$NC"
        if [[ -s "$RESPONSE_FILE" ]]; then
            printf '  %sChi tiết: %s%s\n' "$DIM" "$(head -c 300 "$RESPONSE_FILE")" "$NC"
        fi
        exit 1
        ;;
esac

printf '  %s✔ Xác thực thành công.%s\n' "$GREEN" "$NC"
printf '  %s✔ Đã nhận menu từ GitHub Private.%s\n\n' "$GREEN" "$NC"
sleep 1

# Dùng /dev/tty làm stdin để các lệnh read trong menu.sh vẫn tương tác bình thường.
bash "$MENU_FILE" </dev/tty
