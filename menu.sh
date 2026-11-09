#!/bin/bash

# Tạo thư mục chứa file log nếu chưa có
LOG_DIR="./logs"
mkdir -p "$LOG_DIR"

while true; do
    clear
    echo "=================================================="
    echo "    QUẢN LÝ CÀI ĐẶT HỆ THỐNG KUBUNTU (LONG)        "
    echo "=================================================="
    echo "Vui lòng chọn công cụ hoặc phần mềm cần cài đặt:"
    echo ""
    echo "  1) Cài đặt bộ gõ tiếng Việt VDKey"
    echo "  2) Cài đặt hoặc gỡ bỏ Zalo Linux (chuẩn)"
    echo "  3) Cài đặt và cấu hình máy in (USB/LAN)"
    echo "  4) Cài đặt Winboat"
    echo "  5) Cài mới LibreOffice"
    echo "  6) Cài đặt FViewer (chỉ dành cho máy IT cài linux)"
    echo "  7) Cài đặt Google Drive"
    echo "  8) Thoát"
    echo ""
    
    read -p "Nhập lựa chọn của bạn [1-8]: " choice

    # Tạo tên file log dựa theo thời gian thực để tránh ghi đè
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

    case $choice in
        1)
            LOG_FILE="$LOG_DIR/vdkey_$TIMESTAMP.log"
            echo "----------------------------------"
            echo "Đang cài đặt bộ gõ tiếng Việt VDKey..."
            echo "Log chi tiết được lưu tại: $LOG_FILE"
            echo "----------------------------------"
            
            bash <(curl -fsSL https://raw.githubusercontent.com/longnguyen2026/gotiengviet/main/vdkey.sh) 2>&1 | tee "$LOG_FILE"
            ;;
        2)
            LOG_FILE="$LOG_DIR/zalo_$TIMESTAMP.log"
            echo "----------------------------------"
            echo "Đang cài đặt/gỡ bỏ Zalo (chuẩn)..."
            echo "Log chi tiết được lưu tại: $LOG_FILE"
            echo "----------------------------------"
            
            bash <(curl -fsSL https://raw.githubusercontent.com/longnguyen2026/script-all/main/zola.sh) 2>&1 | tee "$LOG_FILE"
            ;;
        3)
            LOG_FILE="$LOG_DIR/printer_$TIMESTAMP.log"
            echo "----------------------------------"
            echo "Đang cấu hình và cài đặt máy in..."
            echo "Log chi tiết được lưu tại: $LOG_FILE"
            echo "----------------------------------"
            
            # Xác thực sudo trước để tránh xung đột stdin với tee
            sudo -v
            curl -fsSL https://raw.githubusercontent.com/longnguyen2026/printer/main/in.sh | sudo bash 2>&1 | tee "$LOG_FILE"
            ;;
        4)
            LOG_FILE="$LOG_DIR/winboat_$TIMESTAMP.log"
            echo "----------------------------------"
            echo "Đang cài đặt Winboat..."
            echo "Log chi tiết được lưu tại: $LOG_FILE"
            echo "----------------------------------"
            
            bash <(curl -fsSL https://raw.githubusercontent.com/longnguyen2026/winboat/main/install-wb-v4.sh) 2>&1 | tee "$LOG_FILE"
            ;;
        5)
            LOG_FILE="$LOG_DIR/libreoffice_$TIMESTAMP.log"
            echo "----------------------------------"
            echo "Đang cài mới LibreOffice..."
            echo "Log chi tiết được lưu tại: $LOG_FILE"
            echo "----------------------------------"
            
            # Tải về file tạm và cấp sudo sạch sẽ, không bị vướng stdin
            sudo -v
            TMP_SCRIPT="/tmp/libreoffice_install.sh"
            curl -fsSL https://raw.githubusercontent.com/longnguyen2026/office/main/libreoffice.sh -o "$TMP_SCRIPT"
            sudo bash "$TMP_SCRIPT" 2>&1 | tee "$LOG_FILE"
            rm -f "$TMP_SCRIPT"
            ;;
        6)
            LOG_FILE="$LOG_DIR/fviewer_$TIMESTAMP.log"
            echo "----------------------------------"
            echo "Đang cài đặt FViewer..."
            echo "Log chi tiết được lưu tại: $LOG_FILE"
            echo "----------------------------------"
            
            bash <(curl -fsSL https://raw.githubusercontent.com/longnguyen2026/fviewer/main/fviewer.sh) 2>&1 | tee "$LOG_FILE"
            ;;
        7)
            LOG_FILE="$LOG_DIR/drive_$TIMESTAMP.log"
            echo "----------------------------------"
            echo "Đang cài đặt Google Drive..."
            echo "Log chi tiết được lưu tại: $LOG_FILE"
            echo "----------------------------------"
            
            bash <(curl -fsSL https://raw.githubusercontent.com/longnguyen2026/drive-gg/main/drive.sh) 2>&1 | tee "$LOG_FILE"
            ;;
        8)
            echo "Thoát chương trình. Hẹn gặp lại!"
            exit 0
            ;;
        *)
            echo "Lựa chọn không hợp lệ! Vui lòng chọn từ 1 đến 8."
            ;;
    esac
    
    echo ""
    echo "💡 Các file log thực thi được lưu tại thư mục: ./logs/"
    read -p "Nhấn [Enter] để quay lại menu chính..."
done
