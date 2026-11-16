#!/bin/bash

# --- CẤU HÌNH MÀU SẮC ANSI ---
NC='\033[0m'          # No Color
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
MAGENTA='\033[1;35m'
BLUE='\033[1;34m'
BOLD='\033[1;1m'

# Lưu log vào /tmp để tránh lỗi Permission denied dù chạy ở thư mục nào hay dưới quyền root/user
LOG_DIR="/tmp/kubuntu-install-logs"
mkdir -p "$LOG_DIR"
chmod 777 "$LOG_DIR" 2>/dev/null || true

while true; do
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}${MAGENTA}       QUẢN LÝ CÀI ĐẶT HỆ THỐNG KUBUNTU (LONG - PRO)         ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${BOLD}Môi trường:${NC} $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo -e "${BOLD}Hệ thống Log:${NC} ${CYAN}$LOG_DIR${NC}\n"
    
    echo -e "${YELLOW}Vui lòng chọn công cụ hoặc phần mềm cần cài đặt:${NC}"
    echo -e "${CYAN}──────────────────────────────────────────────────────────────${NC}"
    echo -e "  ${GREEN}[1]${NC} ⌨️  Cài đặt bộ gõ tiếng Việt VDKey (build)"
    echo -e "  ${GREEN}[2]${NC} 💬  Cài đặt hoặc gỡ bỏ Zalo Linux (Ver 26.11.10)"
    echo -e "  ${GREEN}[3]${NC} 🖨️  Cài đặt và cấu hình máy in (USB/LAN)"
    echo -e "  ${GREEN}[4]${NC} 🪟  Cài đặt Winboat"
    echo -e "  ${GREEN}[5]${NC} 📄  Cài đặt LibreOffice mới"
    echo -e "  ${GREEN}[6]${NC} 🖥️  Cài đặt FViewer (build UltraViewer)"
    echo -e "  ${GREEN}[7]${NC} ☁️  Cài đặt Google Drive"
    echo -e "  ${GREEN}[8]${NC} 📑  Cài đặt WPS Office mới"
    echo -e "  ${GREEN}[9]${NC} 🛠️  Sửa lỗi mất định dạng Office khi tải lên Google Drive"
    echo -e "  ${RED}[10]${NC}  🚪  Thoát chương trình"
    echo -e "${CYAN}──────────────────────────────────────────────────────────────${NC}"
    
    read -p "👉 Nhập lựa chọn của bạn [1-10]: " choice

    # Tạo tên file log dựa theo thời gian thực để tránh ghi đè
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

    case $choice in
        1)
            LOG_FILE="$LOG_DIR/vdkey_$TIMESTAMP.log"
            echo -e "\n${CYAN}--------------------------------------------------${NC}"
            echo -e "${MAGENTA}➔ Đang cài đặt bộ gõ tiếng Việt VDKey...${NC}"
            echo -e "${BOLD}Log chi tiết:${NC} $LOG_FILE"
            echo -e "${CYAN}--------------------------------------------------${NC}"
            
            bash <(curl -fsSL https://raw.githubusercontent.com/longnguyen2026/gotiengviet/main/vdkey.sh) 2>&1 | tee "$LOG_FILE"
            ;;
        2)
            LOG_FILE="$LOG_DIR/zalo_$TIMESTAMP.log"
            echo -e "\n${CYAN}--------------------------------------------------${NC}"
            echo -e "${MAGENTA}➔ Đang cài đặt/gỡ bỏ Zalo Linux...${NC}"
            echo -e "${BOLD}Log chi tiết:${NC} $LOG_FILE"
            echo -e "${CYAN}--------------------------------------------------${NC}"
            
            bash <(curl -fsSL https://raw.githubusercontent.com/longnguyen2026/script-all/main/zola.sh) 2>&1 | tee "$LOG_FILE"
            ;;
        3)
            LOG_FILE="$LOG_DIR/printer_$TIMESTAMP.log"
            echo -e "\n${CYAN}--------------------------------------------------${NC}"
            echo -e "${MAGENTA}➔ Đang cấu hình và cài đặt máy in...${NC}"
            echo -e "${BOLD}Log chi tiết:${NC} $LOG_FILE"
            echo -e "${CYAN}--------------------------------------------------${NC}"
            
            sudo -v
            curl -fsSL https://raw.githubusercontent.com/longnguyen2026/printer/main/in.sh | sudo bash 2>&1 | tee "$LOG_FILE"
            ;;
        4)
            LOG_FILE="$LOG_DIR/winboat_$TIMESTAMP.log"
            echo -e "\n${CYAN}--------------------------------------------------${NC}"
            echo -e "${MAGENTA}➔ Đang cài đặt Winboat...${NC}"
            echo -e "${BOLD}Log chi tiết:${NC} $LOG_FILE"
            echo -e "${CYAN}--------------------------------------------------${NC}"
            
            bash <(curl -fsSL https://raw.githubusercontent.com/longnguyen2026/winboat/main/install-wb-v4.sh) 2>&1 | tee "$LOG_FILE"
            ;;
        5)
            LOG_FILE="$LOG_DIR/libreoffice_$TIMESTAMP.log"
            echo -e "\n${CYAN}--------------------------------------------------${NC}"
            echo -e "${MAGENTA}➔ Đang cài đặt LibreOffice mới...${NC}"
            echo -e "${BOLD}Log chi tiết:${NC} $LOG_FILE"
            echo -e "${CYAN}--------------------------------------------------${NC}"
            
            sudo -v
            TMP_SCRIPT="/tmp/libreoffice_install.sh"
            curl -fsSL https://raw.githubusercontent.com/longnguyen2026/office/main/libreoffice.sh -o "$TMP_SCRIPT"
            sudo bash "$TMP_SCRIPT" 2>&1 | tee "$LOG_FILE"
            rm -f "$TMP_SCRIPT"
            ;;
        6)
            LOG_FILE="$LOG_DIR/fviewer_$TIMESTAMP.log"
            echo -e "\n${CYAN}--------------------------------------------------${NC}"
            echo -e "${MAGENTA}➔ Đang cài đặt FViewer...${NC}"
            echo -e "${BOLD}Log chi tiết:${NC} $LOG_FILE"
            echo -e "${CYAN}--------------------------------------------------${NC}"
            
            bash <(curl -fsSL https://raw.githubusercontent.com/longnguyen2026/fviewer/main/fviewer.sh) 2>&1 | tee "$LOG_FILE"
            ;;
        7)
            LOG_FILE="$LOG_DIR/drive_$TIMESTAMP.log"
            echo -e "\n${CYAN}--------------------------------------------------${NC}"
            echo -e "${MAGENTA}➔ Đang cài đặt Google Drive...${NC}"
            echo -e "${BOLD}Log chi tiết:${NC} $LOG_FILE"
            echo -e "${CYAN}--------------------------------------------------${NC}"
            
            bash <(curl -fsSL https://raw.githubusercontent.com/longnguyen2026/drive-gg/main/install.sh) 2>&1 | tee "$LOG_FILE"
            ;;
        8)
            LOG_FILE="$LOG_DIR/wps_$TIMESTAMP.log"
            echo -e "\n${CYAN}--------------------------------------------------${NC}"
            echo -e "${MAGENTA}➔ Đang cài đặt WPS Office mới...${NC}"
            echo -e "${BOLD}Log chi tiết:${NC} $LOG_FILE"
            echo -e "${CYAN}--------------------------------------------------${NC}"
            
            sudo -v
            curl -fsSL https://raw.githubusercontent.com/longnguyen2026/office/main/wps.sh | sudo bash 2>&1 | tee "$LOG_FILE"
            ;;
        9)
            LOG_FILE="$LOG_DIR/fix_upload_drive_$TIMESTAMP.log"
            echo -e "\n${CYAN}--------------------------------------------------${NC}"
            echo -e "${MAGENTA}➔ Đang sửa lỗi định dạng tệp tải lên Google Drive...${NC}"
            echo -e "${BOLD}Log chi tiết:${NC} $LOG_FILE"
            echo -e "${CYAN}--------------------------------------------------${NC}"
            
            sudo -v
            curl -fsSL https://raw.githubusercontent.com/longnguyen2026/office/main/fix-upload-drive.sh | sudo bash 2>&1 | tee "$LOG_FILE"
            ;;
        10)
            echo -e "\n${GREEN}✨ Thoát chương trình. Hẹn gặp lại anh Long! ✨${NC}\n"
            exit 0
            ;;
        *)
            echo -e "\n${RED}[!] Lựa chọn không hợp lệ! Vui chọn từ 1 đến 10.${NC}"
            ;;
    esac
    
    echo -e "\n${CYAN}💡 Các file log thực thi được lưu tại thư mục: ${BOLD}$LOG_DIR/${NC}"
    read -p "Nhấn [Enter] để quay lại menu chính..."
done
