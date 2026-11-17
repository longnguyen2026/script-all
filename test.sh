#!/usr/bin/env bash

# Tạo thư mục tạm chạy giao diện, tự xóa sạch khi đóng cửa sổ
TMP_DIR=$(mktemp -d /tmp/long-pro-gui.XXXXXX)
LOG_DIR="/tmp/kubuntu-install-logs"
mkdir -p "$LOG_DIR"
chmod 777 "$LOG_DIR" 2>/dev/null || true

cleanup() {
    rm -rf "$TMP_DIR"
    kill "$SERVER_PID" 2>/dev/null || true
}
trap cleanup EXIT

cat << 'EOF' > "$TMP_DIR/server.py"
import http.server
import socketserver
import subprocess
import json
import os
import shutil
from datetime import datetime

LOG_DIR = "/tmp/kubuntu-install-logs"

HTML_UI = """<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<title>Quản Lý Cài Đặt Hệ Thống - Long Pro</title>
<style>
  :root {
    --primary: #b91c1c;
    --primary-hover: #991b1b;
    --bg: #f3f4f6;
    --card: #ffffff;
    --text: #1f2937;
    --muted: #6b7280;
    --border: #e5e7eb;
  }
  * { box-sizing: border-box; }
  body {
    font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
    background: var(--bg);
    color: var(--text);
    margin: 0;
    padding: 20px;
    user-select: none;
  }
  .header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 18px;
  }
  .brand {
    display: flex;
    align-items: center;
    gap: 14px;
  }
  .logo {
    width: 46px;
    height: 46px;
    background: linear-gradient(135deg, #dc2626, #991b1b);
    color: #fff;
    border-radius: 12px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-weight: 800;
    font-size: 22px;
    box-shadow: 0 4px 10px rgba(185, 28, 28, 0.25);
  }
  .title { margin: 0; font-size: 22px; font-weight: 700; color: var(--primary); }
  .subtitle { margin: 2px 0 0; font-size: 13px; color: var(--muted); }
  .os-badge {
    background: #fff;
    border: 1px solid var(--border);
    padding: 6px 12px;
    border-radius: 20px;
    font-size: 12px;
    font-weight: 600;
    color: #374151;
  }

  /* Tabs */
  .tabs {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 10px;
    margin-bottom: 16px;
  }
  .tab {
    background: var(--card);
    border: 1px solid var(--border);
    padding: 11px;
    border-radius: 10px;
    font-weight: 600;
    font-size: 14px;
    cursor: pointer;
    transition: all 0.15s;
    color: var(--text);
  }
  .tab:hover { border-color: #d1d5db; background: #f9fafb; }
  .tab.active {
    background: var(--primary);
    color: #fff;
    border-color: var(--primary);
    box-shadow: 0 2px 6px rgba(185, 28, 28, 0.25);
  }
  .tab-content { display: none; }
  .tab-content.active { display: block; }

  /* Grid 3x3 cho 9 công cụ */
  .grid-3 {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 12px;
    margin-bottom: 16px;
  }
  .tool-card {
    background: var(--card);
    border: 1px solid var(--border);
    border-radius: 12px;
    padding: 16px 12px;
    text-align: center;
    cursor: pointer;
    transition: all 0.15s ease;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    min-height: 102px;
  }
  .tool-card:hover {
    border-color: #10b981;
    transform: translateY(-2px);
    box-shadow: 0 6px 14px rgba(0, 0, 0, 0.06);
  }
  .tool-card:active { transform: scale(0.98); }
  .tool-icon { font-size: 26px; margin-bottom: 8px; }
  .tool-name { font-weight: 600; font-size: 13.5px; color: #111827; line-height: 1.3; }
  .tool-desc { font-size: 11.5px; color: var(--muted); margin-top: 4px; }

  /* Panel thông tin & log */
  .panel {
    background: var(--card);
    border: 1px solid var(--border);
    border-radius: 12px;
    padding: 16px;
    margin-bottom: 14px;
  }
  .info-row {
    display: flex;
    justify-content: space-between;
    padding: 9px 0;
    border-bottom: 1px solid #f3f4f6;
    font-size: 13.5px;
  }
  .info-row:last-child { border-bottom: none; }
  .log-list {
    max-height: 130px;
    overflow-y: auto;
    border: 1px solid var(--border);
    border-radius: 8px;
    margin-bottom: 10px;
  }
  .log-item {
    padding: 8px 12px;
    border-bottom: 1px solid #f3f4f6;
    font-size: 12.5px;
    font-family: monospace;
    cursor: pointer;
    display: flex;
    justify-content: space-between;
  }
  .log-item:hover { background: #f9fafb; color: var(--primary); }
  pre#log-viewer {
    background: #111827;
    color: #e5e7eb;
    padding: 12px;
    border-radius: 8px;
    font-size: 12px;
    height: 180px;
    overflow: auto;
    margin: 0;
    user-select: text;
    white-space: pre-wrap;
  }

  /* Thanh trạng thái dưới cùng */
  .footer {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-top: 10px;
    font-size: 12px;
    color: var(--muted);
  }
  #status-bar {
    background: #1f2937;
    color: #34d399;
    padding: 10px 14px;
    border-radius: 8px;
    font-family: monospace;
    font-size: 12.5px;
  }
</style>
</head>
<body>

  <div class="header">
    <div class="brand">
      <div class="logo">LP</div>
      <div>
        <h1 class="title">Quản Lý Cài Đặt Hệ Thống</h1>
        <p class="subtitle">Bộ Công Cụ Triển Khai & Hỗ Trợ Linux (Long - Pro)</p>
      </div>
    </div>
    <div class="os-badge" id="os-badge">Đang nhận diện OS...</div>
  </div>

  <!-- Thanh điều hướng Tab -->
  <div class="tabs">
    <button class="tab active" onclick="switchTab(event, 'tab-tools')">Cài Đặt & Công Cụ</button>
    <button class="tab" onclick="switchTab(event, 'tab-info'); loadSysInfo();">Thông Tin Máy</button>
    <button class="tab" onclick="switchTab(event, 'tab-logs'); loadLogs();">Lịch Sử Log</button>
  </div>

  <!-- TAB 1: 9 CHỨC NĂNG TỪ MENU.SH -->
  <div id="tab-tools" class="tab-content active">
    <div class="grid-3">
      <div class="tool-card" onclick="runTask('vdkey')">
        <span class="tool-icon">⌨️</span>
        <span class="tool-name">Bộ Gõ Tiếng Việt VDKey</span>
        <span class="tool-desc">Build & cài Fcitx5 VDKey</span>
      </div>
      <div class="tool-card" onclick="runTask('zalo')">
        <span class="tool-icon">💬</span>
        <span class="tool-name">Zalo Linux (26.11.10)</span>
        <span class="tool-desc">Cài đặt hoặc gỡ bỏ Zalo</span>
      </div>
      <div class="tool-card" onclick="runTask('printer')">
        <span class="tool-icon">🖨️</span>
        <span class="tool-name">Cài & Cấu Hình Máy In</span>
        <span class="tool-desc">Hỗ trợ máy in USB / LAN</span>
      </div>
      <div class="tool-card" onclick="runTask('winboat')">
        <span class="tool-icon">🪟</span>
        <span class="tool-name">Cài Đặt Winboat</span>
        <span class="tool-desc">Triển khai gói Winboat v4</span>
      </div>
      <div class="tool-card" onclick="runTask('libreoffice')">
        <span class="tool-icon">📄</span>
        <span class="tool-name">Cài LibreOffice Mới</span>
        <span class="tool-desc">Bộ văn phòng mã nguồn mở</span>
      </div>
      <div class="tool-card" onclick="runTask('fviewer')">
        <span class="tool-icon">🖥️</span>
        <span class="tool-name">Cài Đặt FViewer</span>
        <span class="tool-desc">Điều khiển từ xa (no-cache)</span>
      </div>
      <div class="tool-card" onclick="runTask('gdrive')">
        <span class="tool-icon">☁️</span>
        <span class="tool-name">Cài Đặt Google Drive</span>
        <span class="tool-desc">Đồng bộ & mount ổ đĩa</span>
      </div>
      <div class="tool-card" onclick="runTask('wps')">
        <span class="tool-icon">📑</span>
        <span class="tool-name">Cài WPS Office Mới</span>
        <span class="tool-desc">Bộ văn phòng chuẩn định dạng</span>
      </div>
      <div class="tool-card" onclick="runTask('fix_drive')">
        <span class="tool-icon">🛠️</span>
        <span class="tool-name">Sửa Lỗi Upload Drive</span>
        <span class="tool-desc">Giữ định dạng file Office</span>
      </div>
    </div>
  </div>

  <!-- TAB 2: THÔNG TIN MÁY -->
  <div id="tab-info" class="tab-content">
    <div class="panel" id="sysinfo-box">Đang tải thông tin hệ thống...</div>
  </div>

  <!-- TAB 3: LỊCH SỬ LOG -->
  <div id="tab-logs" class="tab-content">
    <div class="panel">
      <div style="display:flex;justify-content:space-between;margin-bottom:8px;">
        <strong>Danh sách log trong /tmp/kubuntu-install-logs</strong>
        <button onclick="loadLogs()" style="cursor:pointer;border:1px solid #d1d5db;background:#fff;border-radius:6px;padding:2px 8px;">Làm mới</button>
      </div>
      <div class="log-list" id="log-list">Chưa có file log nào.</div>
      <pre id="log-viewer">Chọn một file log bên trên để xem chi tiết...</pre>
    </div>
  </div>

  <div id="status-bar">Sẵn sàng. Click vào một công cụ để bắt đầu thực thi...</div>

  <div class="footer">
    <span id="user-label">Tài khoản: ...</span>
    <span>Log Dir: /tmp/kubuntu-install-logs</span>
  </div>

<script>
  function switchTab(evt, tabId) {
    document.querySelectorAll('.tab-content').forEach(el => el.classList.remove('active'));
    document.querySelectorAll('.tab').forEach(el => el.classList.remove('active'));
    document.getElementById(tabId).classList.add('active');
    evt.currentTarget.classList.add('active');
  }

  function runTask(taskId) {
    const bar = document.getElementById('status-bar');
    bar.innerText = "⏳ Đang mở cửa sổ thực thi cho tác vụ: " + taskId + "...";
    fetch('/api/run', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ task: taskId })
    })
    .then(r => r.json())
    .then(res => { bar.innerText = res.message; })
    .catch(err => { bar.innerText = "❌ Lỗi kết nối: " + err; });
  }

  function loadSysInfo() {
    fetch('/api/sysinfo').then(r => r.json()).then(data => {
      document.getElementById('os-badge').innerText = data.os;
      document.getElementById('user-label').innerText = "Tài khoản: " + data.user;
      document.getElementById('sysinfo-box').innerHTML = `
        <div class="info-row"><strong>Hệ điều hành:</strong><span>${data.os}</span></div>
        <div class="info-row"><strong>Tên máy (Hostname):</strong><span>${data.hostname}</span></div>
        <div class="info-row"><strong>Địa chỉ IP nội bộ:</strong><span>${data.ip}</span></div>
        <div class="info-row"><strong>Tài khoản hiện tại:</strong><span>${data.user}</span></div>
        <div class="info-row"><strong>CPU / RAM:</strong><span>${data.hw}</span></div>
      `;
    });
  }

  function loadLogs() {
    fetch('/api/logs').then(r => r.json()).then(files => {
      const list = document.getElementById('log-list');
      if (!files.length) {
        list.innerHTML = '<div style="padding:10px;color:#6b7280;">Chưa có file log nào được tạo.</div>';
        return;
      }
      list.innerHTML = files.map(f => `<div class="log-item" onclick="readLog('${f}')"><span>📄 ${f}</span><span>Xem log ➔</span></div>`).join('');
    });
  }

  function readLog(filename) {
    fetch('/api/log_content?file=' + encodeURIComponent(filename))
      .then(r => r.text())
      .then(txt => {
        const viewer = document.getElementById('log-viewer');
        viewer.innerText = txt || "(File log trống)";
        viewer.scrollTop = viewer.scrollHeight;
      });
  }

  // Tự động tải thông tin OS khi mở app
  loadSysInfo();
</script>
</body>
</html>
"""

def find_terminal():
    # Ưu tiên Konsole trên Kubuntu, sau đó tới các terminal trên Linux Mint
    for term in ["konsole", "gnome-terminal", "xfce4-terminal", "mate-terminal", "x-terminal-emulator"]:
        if shutil.which(term):
            return term
    return None

def launch_in_terminal(title, bash_command):
    term = find_terminal()
    wrapped_cmd = f'{bash_command}; echo ""; echo "========================================"; echo "✅ Hoàn tất! Nhấn phím Enter để đóng cửa sổ này..."; read'
    if not term:
        subprocess.Popen(["bash", "-c", bash_command])
        return False
    if term == "konsole":
        subprocess.Popen(["konsole", "--hold", "-p", f"tabtitle={title}", "-e", "bash", "-c", wrapped_cmd])
    elif term == "gnome-terminal":
        subprocess.Popen(["gnome-terminal", "--title", title, "--", "bash", "-c", wrapped_cmd])
    else:
        subprocess.Popen([term, "-e", f"bash -c '{wrapped_cmd}'"])
    return True

class AppHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/":
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.end_headers()
            self.wfile.write(HTML_UI.encode("utf-8"))

        elif self.path == "/api/sysinfo":
            os_name = subprocess.getoutput("lsb_release -ds 2>/dev/null || grep PRETTY_NAME /etc/os-release | cut -d'\"' -f2")
            hostname = subprocess.getoutput("hostname")
            ip = subprocess.getoutput("hostname -I | awk '{print $1}'")
            user = subprocess.getoutput("whoami")
            ram = subprocess.getoutput("free -h | awk '/^Mem:/ {print $2}'")
            cpu = subprocess.getoutput("nproc")
            data = {"os": os_name, "hostname": hostname, "ip": ip or "Chưa kết nối mạng", "user": user, "hw": f"{cpu} Cores / {ram} RAM"}
            self.send_json(data)

        elif self.path == "/api/logs":
            files = sorted([f for f in os.listdir(LOG_DIR) if f.endswith(".log")], reverse=True) if os.path.exists(LOG_DIR) else []
            self.send_json(files)

        elif self.path.startswith("/api/log_content"):
            fname = os.path.basename(self.path.split("file=")[-1])
            fpath = os.path.join(LOG_DIR, fname)
            content = ""
            if os.path.isfile(fpath):
                with open(fpath, "r", encoding="utf-8", errors="replace") as f:
                    content = f.read()
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.end_headers()
            self.wfile.write(content.encode("utf-8"))

    def do_POST(self):
        if self.path == "/api/run":
            length = int(self.headers.get("Content-Length", 0))
            payload = json.loads(self.rfile.read(length))
            task = payload.get("task")
            ts = datetime.now().strftime("%Y%m%d_%H%M%S")

            commands = {
                "vdkey": (
                    "Cài đặt VDKey",
                    f'bash <(curl -fsSL https://raw.githubusercontent.com/longnguyen2026/gotiengviet/main/vd.sh) 2>&1 | tee "{LOG_DIR}/vdkey_{ts}.log"'
                ),
                "zalo": (
                    "Cài đặt / Gỡ bỏ Zalo Linux",
                    f'bash <(curl -fsSL https://raw.githubusercontent.com/longnguyen2026/script-all/main/zola.sh) 2>&1 | tee "{LOG_DIR}/zalo_{ts}.log"'
                ),
                "printer": (
                    "Cài đặt Máy In",
                    f'sudo -v && curl -fsSL https://raw.githubusercontent.com/longnguyen2026/printer/main/in.sh | sudo bash 2>&1 | tee "{LOG_DIR}/printer_{ts}.log"'
                ),
                "winboat": (
                    "Cài đặt Winboat",
                    f'bash <(curl -fsSL https://raw.githubusercontent.com/longnguyen2026/winboat/main/install-wb-v4.sh) 2>&1 | tee "{LOG_DIR}/winboat_{ts}.log"'
                ),
                "libreoffice": (
                    "Cài đặt LibreOffice",
                    f'sudo -v && TMP_S=$(mktemp /tmp/lo_XXXXXX.sh) && curl -fsSL https://raw.githubusercontent.com/longnguyen2026/office/main/libreoffice.sh -o "$TMP_S" && sudo bash "$TMP_S" 2>&1 | tee "{LOG_DIR}/libreoffice_{ts}.log"; rm -f "$TMP_S"'
                ),
                "fviewer": (
                    "Cài đặt FViewer",
                    f'FVIEWER_URL="https://raw.githubusercontent.com/longnguyen2026/fviewer/main/fviewer.sh"; TMP_S=$(mktemp /tmp/fv_XXXXXX.sh); curl -fLsS -H "Cache-Control: no-cache" "${{FVIEWER_URL}}?nocache=$(date +%s%N)" -o "$TMP_S" && bash "$TMP_S" 2>&1 | tee "{LOG_DIR}/fviewer_{ts}.log"; rm -f "$TMP_S"'
                ),
                "gdrive": (
                    "Cài đặt Google Drive",
                    f'bash <(curl -fsSL https://raw.githubusercontent.com/longnguyen2026/drive-gg/main/install.sh) 2>&1 | tee "{LOG_DIR}/drive_{ts}.log"'
                ),
                "wps": (
                    "Cài đặt WPS Office",
                    f'sudo -v && curl -fsSL https://raw.githubusercontent.com/longnguyen2026/office/main/wps.sh | sudo bash 2>&1 | tee "{LOG_DIR}/wps_{ts}.log"'
                ),
                "fix_drive": (
                    "Sửa lỗi Upload Drive",
                    f'sudo -v && curl -fsSL https://raw.githubusercontent.com/longnguyen2026/office/main/fix-upload-drive.sh | sudo bash 2>&1 | tee "{LOG_DIR}/fix_upload_drive_{ts}.log"'
                ),
            }

            if task in commands:
                title, cmd = commands[task]
                launch_in_terminal(title, cmd)
                self.send_json({"message": f"✅ Đã khởi chạy: {title} (Log lưu tại {LOG_DIR})"})
            else:
                self.send_json({"message": "❌ Tác vụ không hợp lệ!"})

    def send_json(self, obj):
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.end_headers()
        self.wfile.write(json.dumps(obj).encode("utf-8"))

    def log_message(self, *args):
        pass

if __name__ == "__main__":
    with socketserver.TCPServer(("127.0.0.1", 0), AppHandler) as httpd:
        port = httpd.server_address[1]
        port_file = os.path.join(os.path.dirname(__file__), "port")
        with open(port_file, "w") as f:
            f.write(str(port))
        httpd.serve_forever()
EOF

# Khởi chạy server nội bộ ở chế độ nền
python3 "$TMP_DIR/server.py" &
SERVER_PID=$!

while [ ! -f "$TMP_DIR/port" ]; do sleep 0.1; done
PORT=$(cat "$TMP_DIR/port")
APP_URL="http://127.0.0.1:$PORT"

# Mở giao diện cửa sổ App bằng trình duyệt có sẵn trên máy
for browser in google-chrome microsoft-edge chromium chromium-browser; do
    if command -v "$browser" >/dev/null 2>&1; then
        "$browser" --app="$APP_URL" --window-size=880,640 --user-data-dir="$TMP_DIR/profile" >/dev/null 2>&1
        exit 0
    fi
done

# Dự phòng nếu máy chỉ có Firefox
xdg-open "$APP_URL" >/dev/null 2>&1
wait "$SERVER_PID"
