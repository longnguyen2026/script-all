#!/usr/bin/env bash
set -Eeuo pipefail

# KVM + Windows 10 installer for Linux Mint / Ubuntu-based desktops.
# Safe uninstall: this script NEVER runs apt autoremove.

VM_NAME="Windows10"
VM_RAM_MB=8192
VM_VCPUS=4
VM_DISK_GB=80
VM_DISK="/var/lib/libvirt/images/${VM_NAME}.qcow2"
STATE_DIR="${HOME}/.kvm-win10-installer"
STATE_FILE="${STATE_DIR}/installed-by-script.txt"

log()  { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
ok()   { printf '\033[1;32m[OK]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2; exit 1; }

need_root() {
    if [[ $EUID -ne 0 ]]; then
        sudo -v || die "Không lấy được quyền sudo."
    fi
}

is_mint() {
    [[ -f /etc/linuxmint/info ]] || grep -qi 'Linux Mint' /etc/os-release 2>/dev/null
}

check_host() {
    log "Kiểm tra hệ thống"
    [[ "$(uname -m)" == "x86_64" ]] || die "Script này cần Linux 64-bit x86_64."

    if is_mint; then
        ok "Đã phát hiện Linux Mint."
    else
        warn "Không phải Linux Mint. Script vẫn hỗ trợ hệ Ubuntu-based nếu APT có đủ package."
    fi

    if grep -Eq '(vmx|svm)' /proc/cpuinfo; then
        ok "CPU có hỗ trợ Intel VT-x / AMD-V."
    else
        die "CPU không báo VT-x/AMD-V. Hãy kiểm tra BIOS/UEFI."
    fi
}

install_packages() {
    need_root
    log "Cài KVM/QEMU + libvirt + virt-manager"

    sudo apt-get update

    # Không dùng apt autoremove.
    # qemu-system-x86 là backend QEMU x86; qemu-kvm là virtual package trên
    # một số Ubuntu/Mint mới nên không ép cài nếu APT không cung cấp nó.
    local pkgs=(
        qemu-system-x86
        qemu-utils
        libvirt-daemon-system
        libvirt-clients
        virt-manager
        virtinst
        cpu-checker
        ovmf
        bridge-utils
        dnsmasq-base
    )

    # TPM emulator không bắt buộc cho Windows 10, nhưng cài nếu có package.
    if apt-cache show swtpm >/dev/null 2>&1; then
        pkgs+=(swtpm)
    fi

    sudo apt-get install -y "${pkgs[@]}"

    mkdir -p "$STATE_DIR"
    printf '%s\n' "${pkgs[@]}" > "$STATE_FILE"

    ok "Đã cài các thành phần KVM/libvirt."
}

configure_libvirt() {
    need_root
    log "Cấu hình libvirt"

    # Hỗ trợ cả hệ thống dùng libvirtd.service và socket activation.
    if systemctl list-unit-files --type=service 2>/dev/null | grep -q '^libvirtd\.service'; then
        sudo systemctl enable --now libvirtd.service || true
    fi

    for unit in virtqemud.socket virtlogd.socket libvirtd.socket; do
        if systemctl list-unit-files 2>/dev/null | grep -q "^${unit}"; then
            sudo systemctl enable --now "$unit" || true
        fi
    done

    sudo usermod -aG libvirt "$USER" || true
    sudo usermod -aG kvm "$USER" || true

    ok "Đã thêm $USER vào nhóm libvirt và kvm."
    warn "Nếu đây là lần đầu thêm nhóm, hãy đăng xuất/đăng nhập lại sau khi script kết thúc."
}

configure_default_network() {
    need_root
    log "Kiểm tra mạng NAT mặc định của libvirt"

    if ! sudo virsh -c qemu:///system net-info default >/dev/null 2>&1; then
        warn "Không tìm thấy network 'default'. Đang thử tạo từ cấu hình mặc định."
        if [[ -f /usr/share/libvirt/networks/default.xml ]]; then
            sudo virsh -c qemu:///system net-define /usr/share/libvirt/networks/default.xml || true
        fi
    fi

    sudo virsh -c qemu:///system net-autostart default >/dev/null 2>&1 || true
    sudo virsh -c qemu:///system net-start default >/dev/null 2>&1 || true

    if sudo virsh -c qemu:///system net-info default 2>/dev/null | grep -q 'Active:.*yes'; then
        ok "Mạng libvirt 'default' đang hoạt động."
    else
        warn "Chưa xác nhận được mạng default. Có thể kiểm tra bằng: virsh net-list --all"
    fi
}

verify_kvm() {
    log "Kiểm tra KVM"

    if command -v kvm-ok >/dev/null 2>&1; then
        if sudo kvm-ok; then
            ok "KVM hoạt động."
        else
            warn "kvm-ok báo KVM chưa sẵn sàng. Kiểm tra VT-x/AMD-V trong BIOS/UEFI."
        fi
    fi

    if [[ -e /dev/kvm ]]; then
        ok "/dev/kvm tồn tại."
    else
        warn "/dev/kvm chưa tồn tại. Có thể cần khởi động lại hoặc bật virtualization trong BIOS/UEFI."
    fi

    if virsh -c qemu:///system uri >/dev/null 2>&1; then
        ok "libvirt qemu:///system kết nối được."
    else
        warn "User hiện tại chưa kết nối được qemu:///system. Nếu vừa thêm nhóm, hãy đăng xuất/đăng nhập."
    fi
}

choose_iso() {
    local iso=""
    echo
    read -r -p "Nhập đường dẫn ISO Windows 10 (hoặc kéo file ISO vào terminal): " iso
    iso="${iso%\"}"
    iso="${iso#\"}"
    iso="${iso%\'}"
    iso="${iso#\'}"

    [[ -f "$iso" ]] || die "Không tìm thấy ISO: $iso"
    [[ "${iso,,}" == *.iso ]] || warn "File không có đuôi .iso, nhưng script vẫn tiếp tục."

    ISO_PATH="$iso"
}

delete_existing_vm() {
    if sudo virsh -c qemu:///system dominfo "$VM_NAME" >/dev/null 2>&1; then
        warn "VM $VM_NAME đã tồn tại."
        read -r -p "Xóa VM cũ và ổ đĩa của nó? [y/N]: " ans
        if [[ "${ans,,}" == "y" ]]; then
            sudo virsh -c qemu:///system destroy "$VM_NAME" >/dev/null 2>&1 || true
            sudo virsh -c qemu:///system undefine "$VM_NAME" --nvram >/dev/null 2>&1 || \
                sudo virsh -c qemu:///system undefine "$VM_NAME" >/dev/null 2>&1 || true
            sudo rm -f "$VM_DISK"
            ok "Đã xóa VM cũ."
        else
            die "Không thể tạo VM mới cùng tên."
        fi
    fi
}

create_windows_vm() {
    need_root
    choose_iso
    delete_existing_vm

    log "Tạo máy ảo Windows 10"

    sudo mkdir -p /var/lib/libvirt/images
    sudo rm -f "$VM_DISK"

    # SATA + e1000e được chọn để Windows 10 có thể cài đặt mà không cần
    # thêm VirtIO driver ISO trong bước cài đặt ban đầu.
    #
    # UEFI dùng OVMF. Windows 10 không bắt buộc TPM nên không ép TPM,
    # giúp script tương thích rộng hơn.
    sudo virt-install \
        --connect qemu:///system \
        --name "$VM_NAME" \
        --memory "$VM_RAM_MB" \
        --vcpus "$VM_VCPUS" \
        --cpu host \
        --machine q35 \
        --boot uefi \
        --disk "path=${VM_DISK},size=${VM_DISK_GB},format=qcow2,bus=sata" \
        --cdrom "$ISO_PATH" \
        --network network=default,model=e1000e \
        --graphics spice \
        --video virtio \
        --channel spicevmc \
        --sound ich9 \
        --noautoconsole

    ok "Đã tạo VM $VM_NAME."
    echo
    echo "Mở giao diện VM:"
    echo "  virt-manager"
    echo
    echo "Trạng thái:"
    echo "  sudo virsh -c qemu:///system list --all"
    echo
    echo "Tắt VM:"
    echo "  sudo virsh -c qemu:///system shutdown $VM_NAME"
    echo
    echo "Khởi động lại VM:"
    echo "  sudo virsh -c qemu:///system start $VM_NAME"

    if command -v virt-manager >/dev/null 2>&1; then
        read -r -p "Mở virt-manager ngay bây giờ? [Y/n]: " ans
        if [[ -z "$ans" || "${ans,,}" == "y" ]]; then
            nohup virt-manager >/dev/null 2>&1 &
        fi
    fi
}

show_status() {
    log "Trạng thái KVM/libvirt"

    echo "KVM:"
    [[ -e /dev/kvm ]] && echo "  /dev/kvm: OK" || echo "  /dev/kvm: KHÔNG CÓ"

    echo
    echo "Libvirt networks:"
    sudo virsh -c qemu:///system net-list --all 2>/dev/null || true

    echo
    echo "Virtual machines:"
    sudo virsh -c qemu:///system list --all 2>/dev/null || true
}

remove_vm() {
    need_root
    log "Xóa Windows 10 VM"

    if sudo virsh -c qemu:///system dominfo "$VM_NAME" >/dev/null 2>&1; then
        sudo virsh -c qemu:///system destroy "$VM_NAME" >/dev/null 2>&1 || true
        sudo virsh -c qemu:///system undefine "$VM_NAME" --nvram >/dev/null 2>&1 || \
            sudo virsh -c qemu:///system undefine "$VM_NAME" >/dev/null 2>&1 || true
        sudo rm -f "$VM_DISK"
        ok "Đã xóa VM và ổ đĩa $VM_DISK."
    else
        warn "Không tìm thấy VM $VM_NAME."
    fi
}

uninstall_stack() {
    need_root
    log "Gỡ KVM/QEMU/libvirt"

    echo
    echo "CẢNH BÁO: thao tác này sẽ gỡ phần mềm virtualization."
    echo "Script KHÔNG chạy apt autoremove."
    echo "Các VM/ổ đĩa có thể vẫn còn nếu bạn không xóa chúng."
    echo
    read -r -p "Bạn chắc chắn muốn gỡ? Nhập REMOVE để tiếp tục: " confirm
    [[ "$confirm" == "REMOVE" ]] || { echo "Đã hủy."; return; }

    # Chỉ remove các package chính, không autoremove.
    sudo apt-get remove -y \
        qemu-system-x86 \
        qemu-utils \
        libvirt-daemon-system \
        libvirt-clients \
        virt-manager \
        virtinst \
        cpu-checker \
        ovmf \
        bridge-utils \
        swtpm 2>/dev/null || true

    sudo deluser "$USER" libvirt >/dev/null 2>&1 || true
    sudo deluser "$USER" kvm >/dev/null 2>&1 || true

    ok "Đã gửi yêu cầu gỡ các package virtualization. Không chạy autoremove."
    warn "Hãy đăng xuất/đăng nhập lại để nhóm người dùng cập nhật."
}

install_all() {
    check_host
    install_packages
    configure_libvirt
    configure_default_network
    verify_kvm

    echo
    read -r -p "Bạn muốn tạo VM Windows 10 ngay bây giờ? [Y/n]: " ans
    if [[ -z "$ans" || "${ans,,}" == "y" ]]; then
        create_windows_vm
    fi
}

main_menu() {
    while true; do
        clear 2>/dev/null || true
        cat <<'MENU'

========================================
      KVM + WINDOWS 10 INSTALLER
========================================

  1) Cài đặt KVM/QEMU + Libvirt + Virt-Manager
  2) Kiểm tra KVM / Libvirt
  3) Tạo máy ảo Windows 10
  4) Xóa máy ảo Windows 10
  5) Gỡ KVM/Libvirt
  6) Thoát

========================================
MENU

        read -r -p "Chọn [1-6]: " choice
        case "$choice" in
            1) install_all; read -r -p "Nhấn Enter để tiếp tục..." ;;
            2) verify_kvm; show_status; read -r -p "Nhấn Enter để tiếp tục..." ;;
            3) create_windows_vm; read -r -p "Nhấn Enter để tiếp tục..." ;;
            4) remove_vm; read -r -p "Nhấn Enter để tiếp tục..." ;;
            5) uninstall_stack; read -r -p "Nhấn Enter để tiếp tục..." ;;
            6) exit 0 ;;
            *) warn "Lựa chọn không hợp lệ."; sleep 1 ;;
        esac
    done
}

main_menu
