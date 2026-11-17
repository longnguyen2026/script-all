#!/usr/bin/env bash
# Install VNI fonts from a public Google Drive file on Ubuntu, Kubuntu and Linux Mint.
set -Eeuo pipefail

DRIVE_FILE_ID="1N6mkOZonvxfjLowAxza961lkaIJwrGH_"
FONT_DIR="/usr/local/share/fonts/vni"
WORK_DIR="$(mktemp -d -t install-vni.XXXXXX)"
DOWNLOAD_FILE="$WORK_DIR/vni-download"
EXTRACT_DIR="$WORK_DIR/extracted"

cleanup() { rm -rf "$WORK_DIR"; }
trap cleanup EXIT

if [[ $EUID -ne 0 ]]; then
  echo "Vui lòng chạy bằng sudo: sudo bash $0" >&2
  exit 1
fi

for cmd in curl find install fc-cache file; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Thiếu lệnh: $cmd. Đang cài công cụ cần thiết..."
    apt-get update
    apt-get install -y curl fontconfig file
    break
  fi
done

if ! command -v unzip >/dev/null 2>&1; then
  apt-get update
  apt-get install -y unzip
fi

mkdir -p "$EXTRACT_DIR"
URL="https://drive.usercontent.google.com/download?id=${DRIVE_FILE_ID}&export=download&confirm=t"
echo "Đang tải bộ font VNI từ Google Drive..."
if ! curl -fL --retry 3 --retry-delay 2 --connect-timeout 20 "$URL" -o "$DOWNLOAD_FILE"; then
  echo "Không tải được file. Hãy kiểm tra quyền Google Drive: Anyone with the link – Viewer." >&2
  exit 1
fi

# Google Drive may return an HTML permission/error page instead of the actual file.
if file "$DOWNLOAD_FILE" | grep -qiE 'HTML|text'; then
  echo "Google Drive trả về trang HTML, không phải file font. Kiểm tra quyền chia sẻ hoặc link." >&2
  exit 1
fi

if unzip -tq "$DOWNLOAD_FILE" >/dev/null 2>&1; then
  echo "Đã nhận ZIP, đang giải nén..."
  unzip -q "$DOWNLOAD_FILE" -d "$EXTRACT_DIR"
else
  # Also accept a single TTF/OTF/TTC file instead of a ZIP archive.
  if file "$DOWNLOAD_FILE" | grep -qiE 'TrueType|OpenType|font data'; then
    mime="$(file -b --mime-type "$DOWNLOAD_FILE")"
    case "$mime" in
      font/ttf|application/x-font-ttf) ext="ttf" ;;
      font/otf|application/vnd.ms-opentype) ext="otf" ;;
      font/collection|application/x-font-ttc) ext="ttc" ;;
      *) echo "Không xác định được định dạng font: $mime" >&2; exit 1 ;;
    esac
    cp "$DOWNLOAD_FILE" "$EXTRACT_DIR/$(basename "${DRIVE_FILE_ID}").$ext"
  else
    echo "File tải về không phải ZIP hợp lệ hoặc file font TTF/OTF/TTC." >&2
    echo "Có thể link Drive đang trỏ đến định dạng khác hoặc yêu cầu quyền truy cập." >&2
    exit 1
  fi
fi

mapfile -d '' FONT_FILES < <(find "$EXTRACT_DIR" -type f \( -iname '*.ttf' -o -iname '*.otf' -o -iname '*.ttc' \) -print0)
if (( ${#FONT_FILES[@]} == 0 )); then
  echo "Không tìm thấy file .TTF, .OTF hoặc .TTC trong gói tải về." >&2
  exit 1
fi

mkdir -p "$FONT_DIR"
installed=0
for font in "${FONT_FILES[@]}"; do
  # Keep original filename; prefix duplicates to avoid overwriting unrelated fonts.
  base="$(basename "$font")"
  target="$FONT_DIR/$base"
  if [[ -e "$target" ]] && ! cmp -s "$font" "$target"; then
    target="$FONT_DIR/${RANDOM}_${base}"
  fi
  install -m 0644 "$font" "$target"
  ((installed+=1))
done

fc-cache -f "$FONT_DIR"
echo
echo "Hoàn tất: đã cài $installed file font vào $FONT_DIR"
echo "Một số font VNI được nhận diện:"
fc-list : family | sort -u | grep -iE '(^|[^A-Z])VNI([ -]|$)' | head -40 || true
echo
echo "Hãy đóng và mở lại LibreOffice để cập nhật danh sách font."
