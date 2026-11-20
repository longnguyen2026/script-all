#!/usr/bin/env bash
set -euo pipefail

GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
CYAN="\033[1;36m"
RESET="\033[0m"

TARGET_DIR="${1:-.}"
SIZE="${2:-128}"
THRESHOLD="${3:-242}"

if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${RED}Lỗi: Thư mục không tồn tại -> $TARGET_DIR${RESET}"
    exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
    echo -e "${RED}Lỗi: Không tìm thấy python3${RESET}"
    exit 1
fi

if ! python3 -c "from PIL import Image" >/dev/null 2>&1; then
    echo -e "${YELLOW}Thiếu python3-pil, đang cài đặt...${RESET}"
    sudo apt-get update -qq && sudo apt-get install -y -qq python3-pil
fi

echo -e "${CYAN}Đang xử lý icon Zalo 3D trong: ${TARGET_DIR} (kích thước: ${SIZE}x${SIZE})${RESET}"

python3 - "$TARGET_DIR" "$SIZE" "$THRESHOLD" << 'EOF'
import os
import sys
from collections import deque
from PIL import Image

target_dir = sys.argv[1]
size = int(sys.argv[2])
threshold = int(sys.argv[3])

files = ["s1.jpg", "s2.jpg", "s3.jpg", "s4.jpg", "s5.jpg", "s5p.jpg"]

def is_near_white(pixel, thresh):
    r, g, b, _ = pixel
    return r >= thresh and g >= thresh and b >= thresh

processed = 0
for fname in files:
    src_path = os.path.join(target_dir, fname)
    if not os.path.isfile(src_path):
        print(f"[SKIP] Không tìm thấy: {src_path}")
        continue

    img = Image.open(src_path).convert("RGBA")
    w, h = img.size
    pixels = img.load()
    visited = [[False] * w for _ in range(h)]
    q = deque()

    for x in range(w):
        for y in (0, h - 1):
            if is_near_white(pixels[x, y], threshold):
                visited[y][x] = True
                q.append((x, y))

    for y in range(h):
        for x in (0, w - 1):
            if not visited[y][x] and is_near_white(pixels[x, y], threshold):
                visited[y][x] = True
                q.append((x, y))

    while q:
        cx, cy = q.popleft()
        pixels[cx, cy] = (255, 255, 255, 0)
        for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
            if 0 <= nx < w and 0 <= ny < h and not visited[ny][nx]:
                if is_near_white(pixels[nx, ny], threshold):
                    visited[ny][nx] = True
                    q.append((nx, ny))

    out_name = os.path.splitext(fname)[0] + ".png"
    out_path = os.path.join(target_dir, out_name)
    img.resize((size, size), Image.Resampling.LANCZOS).save(out_path, "PNG")
    print(f"[OK] {out_path}")
    processed += 1

sys.exit(0 if processed > 0 else 1)
EOF

echo -e "${GREEN}Hoàn tất xuất PNG nền trong suốt cho bộ icon Zalo 3D.${RESET}"
