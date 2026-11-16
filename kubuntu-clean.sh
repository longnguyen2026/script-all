#!/bin/bash

echo "=== [1/4] Dọn dẹp cache gói cài đặt APT (giữ lại bản mới nhất) ==="
sudo apt-get autoclean

echo "=== [2/4] Làm sạch bộ nhớ đệm Thumbnail của KDE Plasma ==="
rm -rf ~/.cache/thumbnails/* 2>/dev/null || true

echo "=== [3/4] Xóa các tệp log hệ thống cũ (giữ lại 7 ngày gần nhất) ==="
sudo journalctl --vacuum-time=7d

echo "=== [4/4] Xóa các tệp rác trong thư mục tạm (/tmp) ==="
sudo rm -rf /tmp/* 2>/dev/null || true

echo "=== Hoàn tất dọn dẹp hệ thống an toàn! ==="
