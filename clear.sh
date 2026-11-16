#!/bin/bash
# --- CẤU HÌNH MÀU SẮC ANSI ---
NC='\033[0m'          # No Color
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
MAGENTA='\033[1;35m'
BOLD='\033[1;1m'

# Kiểm tra quyền root trước khi chạy các lệnh hệ thống
if [ "$EUID" -ne 0 ]; then
  echo -e "${YELLOW}[!] Vui lòng chạy script bằng quyền sudo để dọn dẹp triệt để cache hệ thống:${NC}"
  echo -e "    ${CYAN}sudo ./safe-clean.sh${NC}"
  exit 1
fi

clear
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}${MAGENTA}       KUBUNTU SYSTEM OPTIMIZER & SAFE CLEANER v2.6         ${NC}${CYAN}║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo -e "${BOLD}Môi trường:${NC} $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo -e "${BOLD}Thời gian bắt đầu:${NC} $(date '+%Y-%m-%d %H:%M:%S')\n"

# Tính dung lượng trống ban đầu
INITIAL_FREE=$(df / | awk 'NR==2 {print $4}')

# --- BƯỚC 1: APT CACHE ---
echo -e "${CYAN}[1/4] 🧹 Đang dọn dẹp cache gói cài đặt APT...${NC}"
apt-get autoclean -q &>/dev/null
echo -e "${GREEN}  ➔ Đã làm sạch các gói DEB cũ (giữ lại bản mới nhất). [OK]${NC}\n"

# --- BƯỚC 2: THUMBNAILS ---
echo -e "${CYAN}[2/4] 🖼️  Đang dọn dẹp bộ nhớ đệm Thumbnail của Plasma...${NC}"
# Dọn cache thumbnail của user hiện tại gọi script hoặc các user trên hệ thống
for user_home in /home/*; do
  if [ -d "$user_home/.cache/thumbnails" ]; then
    rm -rf "$user_home/.cache/thumbnails/"* 2>/dev/null || true
  fi
done
rm -rf /root/.cache/thumbnails/* 2>/dev/null || true
echo -e "${GREEN}  ➔ Đã xóa sạch rác hình thu nhỏ ẩn. [OK]${NC}\n"

# --- BƯỚC 3: JOURNAL LOGS ---
echo -e "${CYAN}[3/4] 📜 Đang tối ưu hóa tệp nhật ký hệ thống (Journal logs)...${NC}"
journalctl --vacuum-time=7d &>/dev/null
echo -e "${GREEN}  ➔ Đã giữ lại log hệ thống trong vòng 7 ngày gần nhất. [OK]${NC}\n"

# --- BƯỚC 4: TEMP FILES ---
echo -e "${CYAN}[4/4] 🗑️  Đang dọn dẹp các tệp tạm (/tmp)...${NC}"
find /tmp -mindepth 1 -delete 2>/dev/null || true
echo -e "${GREEN}  ➔ Đã làm sạch thư mục tạm thời. [OK]${NC}\n"

# Tính dung lượng dọn dẹp được
FINAL_FREE=$(df / | awk 'NR==2 {print $4}')
FREED_KB=$((FINAL_FREE - INITIAL_FREE))
if [ "$FREED_KB" -gt 0 ]; then
  FREED_MB=$((FREED_KB / 1024))
  SUMMARY_MSG="Đã giải phóng thành công ~${FREED_MB} MB dung lượng hệ thống!"
else
  SUMMARY_MSG="Hệ thống đã ở trạng thái tối ưu nhất!"
fi

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}${GREEN}                   DỌN DẸP HOÀN TẤT!                        ${NC}${CYAN}║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo -e "${BOLD}Kết quả:${NC} ${GREEN}${SUMMARY_MSG}${NC}\n"
