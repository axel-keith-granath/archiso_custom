#!/bin/bash
#
# custom_releng.sh - Prepares a custom Archiso 'releng' directory for building.
#

set -e

# --- Configuration & Arguments ---
CUSTOM_FILES_DIR="./custom_files/releng"
RELENG_TARGET_DIR="./releng" # We will work directly in the project root.
ARCHISO_RELENG_PATH="/usr/share/archiso/configs/releng"

usage() {
    echo "Usage: $0 [-c <custom_dir>]"
    echo "Prepares a clean 'releng' directory by overlaying custom files."
    echo "  -c, --custom <dir>   Path to custom files overlay (default: ./custom_files/releng)"
    echo "  -h, --help           Display this help message."
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -c|--custom) CUSTOM_FILES_DIR="$2"; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown parameter passed: $1"; usage; exit 1 ;;
    esac
    shift
done

# --- Functions ---
print_success() { echo -e "\e[32m✔ $1\e[0m"; }
print_info() { echo -e "\e[34mℹ $1\e[0m"; }
print_error() { echo -e "\e[31m✖ $1\e[0m"; exit 1; }

# --- Main Logic ---
print_info "Starting releng setup process..."
[ ! -d "$ARCHISO_RELENG_PATH" ] && print_error "Base archiso profile not found. Is 'archiso' installed?"
[ ! -d "$CUSTOM_FILES_DIR" ] && print_error "Custom files directory not found at '$CUSTOM_FILES_DIR'."

print_info "Creating clean releng directory at '$RELENG_TARGET_DIR'..."
sudo rm -rf "$RELENG_TARGET_DIR"
cp -r "$ARCHISO_RELENG_PATH" "$RELENG_TARGET_DIR"
print_success "Base profile copied."

print_info "Applying custom file overlay from '$CUSTOM_FILES_DIR'..."
rsync -a "${CUSTOM_FILES_DIR}/" "${RELENG_TARGET_DIR}/"
print_success "Custom files applied successfully."

MOUNT_UNIT_PATH="${RELENG_TARGET_DIR}/airootfs/etc/systemd/system/mnt-storage.mount"
WANTS_DIR="${RELENG_TARGET_DIR}/airootfs/etc/systemd/system/multi-user.target.wants"
if [ -f "$MOUNT_UNIT_PATH" ]; then
    print_info "Creating systemd mount unit symlink..."
    mkdir -p "$WANTS_DIR"
    ln -sf "/etc/systemd/system/mnt-storage.mount" "${WANTS_DIR}/mnt-storage.mount"
    print_success "Symlink for mnt-storage.mount created."
fi

print_info "\n✅ Releng preparation complete. Ready to build."