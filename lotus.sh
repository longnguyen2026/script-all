#!/usr/bin/env bash
set -e

# Lotus Installer v8 Universal - Clean Fcitx5
# Ubuntu / Kubuntu / Zorin / TUXEDO OS / Debian
# Fixes fcitx5-lotus 3.5.6-1 broken Debian postinst on Ubuntu/Kubuntu/Zorin/TUXEDO OS.

BLUE='\033[1;34m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; NC='\033[0m'

printf '%b\n' "${BLUE}======================================="
printf '%b\n' "     Lotus Installer v8 Universal - Clean Fcitx5"
printf '%b\n' "     Ubuntu / Kubuntu / Zorin / TUXEDO OS / Debian"
printf '%b\n' "     X11 + Wayland"
printf '%b\n' "=======================================${NC}"

[ -r /etc/os-release ] || { echo "Cannot detect OS"; exit 1; }
. /etc/os-release

OS_ID=${ID:-unknown}
OS_LIKE=${ID_LIKE:-}
CODENAME=${VERSION_CODENAME:-}
BASE_CODENAME=${UBUNTU_CODENAME:-$CODENAME}

case "$OS_ID" in
  ubuntu|kubuntu|linuxmint|zorin)
    FAMILY=ubuntu
    ;;

  tuxedo)
    # TUXEDO OS Legacy = Ubuntu 24.04 LTS / Noble
    if [ "${UBUNTU_CODENAME:-}" = "noble" ] || [ "${VERSION_CODENAME:-}" = "noble" ]; then
      FAMILY=ubuntu
      BASE_CODENAME=noble
    else
      # Future Debian-based TUXEDO OS
      FAMILY=debian
    fi
    ;;

  debian)
    FAMILY=debian
    ;;

  *)
    if printf '%s' "$OS_LIKE" | grep -qi debian; then
      FAMILY=debian
    elif printf '%s %s' "$NAME" "$PRETTY_NAME" | grep -qi tuxedo; then
      if [ "${UBUNTU_CODENAME:-}" = "noble" ] || [ "${VERSION_CODENAME:-}" = "noble" ]; then
        FAMILY=ubuntu
        BASE_CODENAME=noble
      else
        FAMILY=debian
      fi
    else
      printf '%b\n' "${RED}Unsupported OS: ${PRETTY_NAME}${NC}"
      exit 1
    fi
    ;;
esac

SESSION=${XDG_SESSION_TYPE:-unknown}
DESKTOP=${XDG_CURRENT_DESKTOP:-unknown}
printf '%b\n' "Detected OS: ${PRETTY_NAME}"
printf '%b\n' "Codename: ${BASE_CODENAME:-unknown}"
printf '%b\n' "Desktop: ${DESKTOP}"
printf '%b\n' "Session: ${SESSION}"

# Do not allow a previously broken Lotus package to be configured by apt.
printf '%b\n' "${YELLOW}Cleaning any previous broken Lotus package...${NC}"
if dpkg-query -W -f='${Status}' fcitx5-lotus 2>/dev/null | grep -q 'install ok'; then
  sudo dpkg --purge --force-all fcitx5-lotus >/dev/null 2>&1 || true
fi
# If dpkg still has the package in a broken state, remove its maintainer scripts.
if dpkg-query -W -f='${db:Status-Status}' fcitx5-lotus 2>/dev/null | grep -qE '^(installed|unpacked|half-installed|triggers-awaited|triggers-pending)$'; then
  sudo rm -f /var/lib/dpkg/info/fcitx5-lotus.postinst /var/lib/dpkg/info/fcitx5-lotus.prerm /var/lib/dpkg/info/fcitx5-lotus.preinst /var/lib/dpkg/info/fcitx5-lotus.postrm
  sudo dpkg --remove --force-remove-reinstreq fcitx5-lotus >/dev/null 2>&1 || true
fi

# ------------------------------------------------------------
# CLEAN OLD FCITX5 + LOTUS
# ------------------------------------------------------------
echo
printf '%b\n' "${YELLOW}Cleaning old Fcitx5 and Lotus packages...${NC}"

# Remove Lotus first so its broken maintainer script cannot be triggered
# while APT is removing/reinstalling Fcitx5.
sudo dpkg --purge --force-all fcitx5-lotus 2>/dev/null || true

# Purge all currently installed Fcitx5 packages.
FCITX5_OLD="$(dpkg-query -W -f='${binary:Package}\t${db:Status-Status}\n' 2>/dev/null \
  | awk -F '\t' '$1 ~ /^fcitx5($|-)/ && $2 == "installed" {print $1}')"

if [ -n "$FCITX5_OLD" ]; then
  printf '%s\n' "$FCITX5_OLD" | xargs -r sudo apt-get purge -y
fi

# Remove user and system Fcitx5 configuration left by previous installs.
rm -rf "$HOME/.config/fcitx5" "$HOME/.cache/fcitx5" 2>/dev/null || true
sudo rm -rf /etc/fcitx5 2>/dev/null || true

# Clear any leftover package state.
sudo dpkg --configure -a || true
sudo apt-get autoremove -y || true
sudo apt-get autoclean -y || true

printf '%b\n' "${GREEN}Old Fcitx5/Lotus installation cleaned.${NC}"

sudo apt-get update

printf '%b\n' "${YELLOW}Stopping IBus...${NC}"
if command -v ibus >/dev/null 2>&1; then ibus exit >/dev/null 2>&1 || true; fi
pkill -f ibus-daemon >/dev/null 2>&1 || true

printf '%b\n' "${YELLOW}Installing Fcitx5 dependencies...${NC}"
PACKAGES=(curl gnupg ca-certificates fcitx5 fcitx5-modules fcitx5-config-qt im-config)
if [ "$FAMILY" = ubuntu ]; then
  PACKAGES+=(fcitx5-frontend-gtk3 fcitx5-frontend-gtk4 fcitx5-frontend-qt5 fcitx5-frontend-qt6)
  apt-cache show kde-config-fcitx5 >/dev/null 2>&1 && PACKAGES+=(kde-config-fcitx5)
  apt-cache show fcitx5-frontend-gtk2 >/dev/null 2>&1 && PACKAGES+=(fcitx5-frontend-gtk2)
else
  apt-cache show fcitx5-frontend-all >/dev/null 2>&1 && PACKAGES+=(fcitx5-frontend-all)
fi
sudo apt-get install -y "${PACKAGES[@]}"

if [ "$FAMILY" = debian ]; then
  case "$CODENAME" in bookworm|trixie) LOTUS_CODENAME=$CODENAME;; *) echo "Unsupported Debian codename: $CODENAME"; exit 1;; esac
else
  LOTUS_CODENAME=$BASE_CODENAME
fi

[ -n "$LOTUS_CODENAME" ] || { echo "Cannot determine Lotus codename"; exit 1; }
printf '%b\n' "${GREEN}Lotus repository codename: ${LOTUS_CODENAME}${NC}"

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://fcitx5-lotus.pages.dev/pubkey.gpg | sudo gpg --dearmor --yes -o /etc/apt/keyrings/fcitx5-lotus.gpg
printf 'deb [arch=amd64 signed-by=/etc/apt/keyrings/fcitx5-lotus.gpg] https://fcitx5-lotus.pages.dev/apt/%s %s main\n' "$LOTUS_CODENAME" "$LOTUS_CODENAME" | sudo tee /etc/apt/sources.list.d/fcitx5-lotus.list >/dev/null
sudo apt-get update

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
cd "$TMP"

printf '%b\n' "${YELLOW}Downloading Lotus package without configuring it...${NC}"
apt-get download fcitx5-lotus
DEB=$(find . -maxdepth 1 -type f -name 'fcitx5-lotus_*.deb' -print -quit)
[ -n "$DEB" ] || { echo "Lotus .deb not downloaded"; exit 1; }

mkdir unpack
# Extract package and repair the broken maintainer script before dpkg sees it.
dpkg-deb -R "$DEB" unpack
POSTINST=unpack/DEBIAN/postinst

if [ ! -f "$POSTINST" ]; then
  echo "Lotus package has no postinst; aborting safely."; exit 1
fi

printf '%b\n' "${YELLOW}Checking Lotus postinst syntax...${NC}"
if ! sh -n "$POSTINST" 2>/dev/null; then
  printf '%b\n' "${YELLOW}Broken postinst detected. Applying safe fix...${NC}"
fi

# The published 3.5.6-1 script has an empty THEN branch:
#   if systemctl ...; then
#
#   else
#
# POSIX sh requires a command in that branch. ':' is the no-op command.
# Insert ':' after the service-test line, but only if it is not already there.
if grep -q 'systemctl enable --now.*fcitx5-lotus-server@.*service.*then' "$POSTINST"; then
  sed -i '/systemctl enable --now.*fcitx5-lotus-server@.*service.*then/ { n; /^[[:space:]]*$/ s/.*/        :/; }' "$POSTINST"
  # If there was no blank line between then and else, insert ':' explicitly.
  awk '
    /systemctl enable --now.*fcitx5-lotus-server@.*service.*then/ { print; getline; if ($0 ~ /^[[:space:]]*$/) { print "        :"; getline; print; } else if ($0 ~ /^[[:space:]]*else[[:space:]]*$/) { print "        :"; print; } else { print } ; next }
    { print }
  ' "$POSTINST" > "$POSTINST.fixed"
  mv "$POSTINST.fixed" "$POSTINST"
fi

# Normalize the exact broken pattern if it survived the generic repair.
python3 - "$POSTINST" <<'PY'
from pathlib import Path
import re, sys
p=Path(sys.argv[1])
s=p.read_text()
pat=r'(if\s+systemctl\s+enable\s+--now\s+"fcitx5-lotus-server@\$\{REAL_USER\}\.service"[^\n]*;\s*then\n)(\s*\n\s*else\b)'
s2=re.sub(pat, r'\1        :\n\2', s, count=1)
if s2 == s:
    # Handle a blank-free form: then immediately followed by else.
    s2=re.sub(r'(if\s+systemctl\s+enable\s+--now\s+"fcitx5-lotus-server@\$\{REAL_USER\}\.service"[^\n]*;\s*then\n)(\s*else\b)', r'\1        :\n\2', s, count=1)
p.write_text(s2)
PY

chmod 0755 "$POSTINST"
if ! sh -n "$POSTINST"; then
  echo "ERROR: Lotus postinst is still syntactically invalid after repair." >&2
  nl -ba "$POSTINST" | sed -n '1,80p' >&2
  exit 1
fi

# Rebuild a new local .deb. Version remains 3.5.6-1, only the maintainer script is fixed.
dpkg-deb -b unpack "$TMP/fcitx5-lotus-fixed.deb" >/dev/null

printf '%b\n' "${YELLOW}Installing repaired Lotus package...${NC}"
# dpkg -i first installs the local repaired package without consulting the broken repository copy.
sudo dpkg -i "$TMP/fcitx5-lotus-fixed.deb" || {
  sudo apt-get -f install -y
  sudo dpkg -i "$TMP/fcitx5-lotus-fixed.deb"
}

# Complete the service setup that the original postinst was intended to perform.
sudo modprobe uinput || true
if command -v udevadm >/dev/null 2>&1; then
  sudo udevadm control --reload-rules || true
  sudo udevadm trigger || true
fi
sudo systemd-sysusers || true
REAL_USER=${SUDO_USER:-$USER}
if command -v systemctl >/dev/null 2>&1; then
  sudo systemctl enable --now "fcitx5-lotus-server@${REAL_USER}.service" || true
fi

# Fcitx5 environment/configuration.
im-config -n fcitx5 >/dev/null 2>&1 || true
mkdir -p "$HOME/.config/environment.d" "$HOME/.config/autostart"
cat > "$HOME/.config/environment.d/90-fcitx5-lotus.conf" <<'EOF2'
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
QT_IM_MODULES=wayland;fcitx;ibus
XMODIFIERS=@im=fcitx
SDL_IM_MODULE=fcitx
EOF2
cat > "$HOME/.config/autostart/fcitx5.desktop" <<'EOF3'
[Desktop Entry]
Type=Application
Name=Fcitx5
Exec=fcitx5 -d
X-GNOME-Autostart-enabled=true
X-KDE-autostart-after=panel
EOF3

pkill -9 fcitx5 >/dev/null 2>&1 || true
fcitx5 -d >/dev/null 2>&1 || true

if dpkg-query -W -f='${db:Status-Status}' fcitx5-lotus 2>/dev/null | grep -qx installed; then
  printf '%b\n' "${GREEN}======================================="
  printf '%b\n' " Lotus installed successfully"
  printf '%b\n' " Fcitx5 + Lotus: OK"
  printf '%b\n' "=======================================${NC}"
  echo "Log out and log in again before testing."
else
  printf '%b\n' "${RED}Lotus is not fully installed.${NC}"
  exit 1
fi
