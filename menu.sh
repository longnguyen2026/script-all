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
    echo "  2) Cài đặt hoặc gỡ bỏ Zalo Linux (sentosa-9)"
    echo "  3) Cài đặt và cấu hình máy in (USB/LAN)"
    echo "  4) Cài đặt Winboat"
    echo "  5) Cài mới LibreOffice"
    echo "  6) Cài đặt tất cả (Chạy tuần tự 1 -> 5)"
    echo "  7) Thoát"
    echo ""
    
    read -p "Nhập lựa chọn của bạn [1-7]: " choice

    # Tạo tên file log dựa theo thời gian thực để tránh ghi đè
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

    case $choice in
        1)
            LOG_FILE="$LOG_DIR/vdkey_$TIMESTAMP.log"
            echo "----------------------------------"
            echo "Đang cài đặt bộ gõ tiếng Việt VDKey..."
            echo "Log chi tiết được lưu tại: $LOG_FILE"
            echo "----------------------------------"
            
            # Thực thi và ghi toàn bộ output (stdout & stderr) ra màn hình và file log
            bash <(curl -fsSL https://raw.githubusercontent.com/longnguyen2026/gotiengviet/main/vdkey-install.sh) 2>&1 | tee "$LOG_FILE"
            ;;
        2)
            LOG_FILE="$LOG_DIR/zalo_$TIMESTAMP.log"
            echo "----------------------------------"
            echo "Đang cài đặt/gỡ bỏ Zalo (sentosa-9)..."
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
            
            curl -sSL https://raw.githubusercontent.com/longnguyen2026/office/main/libreoffice.sh | bash 2>&1 | tee "$LOG_FILE"
            ;;
        6)
            LOG_FILE="$LOG_DIR/install_all_$TIMESTAMP.log"
            echo "----------------------------------"
            echo "Tiến hành cài đặt toàn bộ gói hệ thống..."
            echo "Log chi tiết được lưu tại: $LOG_FILE"
            echo "----------------------------------"
            
            {
                echo "=== BẮT ĐẦU CÀI ĐẶT TOÀN BỘ ($(date)) ==="
                
                echo "--- [1/5] VDKey ---"
                bash <(curl -fsSL https://raw.githubusercontent.com/longnguyen2026/gotiengviet/main/vdkey-install.sh)
                
                echo "--- [2/5] Zalo ---"
                bash <(curl -fsSL https://raw.githubusercontent.com/longnguyen2026/script-all/main/zola.sh)
                
                echo "--- [3/5] Printer ---"
                curl -fsSL https://raw.githubusercontent.com/longnguyen2026/printer/main/in.sh | sudo bash
                
                echo "--- [4/5] Winboat ---"
                bash <(curl -fsSL https://raw.githubusercontent.com/longnguyen2026/winboat/main/install-wb-v4.sh)
                
                echo "--- [5/5] LibreOffice ---"
                curl -sSL https://raw.githubusercontent.com/longnguyen2026/office/main/libreoffice.sh | bash
                
                echo "=== HOÀN TẤT TOÀN BỘ QUÁ TRÌNH ($(date)) ==="
            } 2>&1 | tee "$LOG_FILE"
            
            echo "Đã hoàn tất toàn bộ tiến trình cài đặt!"
            ;;
        7)
            echo "Thoát chương trình. Hẹn gặp lại!"
            exit 0
            ;;
        *)
            echo "Lựa chọn không hợp lệ! Vui lòng chọn từ 1 đến 7."
            ;;
    esac
    
    echo ""
    echo "💡 Các file log thực thi được lưu tại thư mục: ./logs/"
    read -p "Nhấn [Enter] để quay lại menu chính..."
done
