#!/bin/bash
#
# build_iso.sh - Builds the custom Arch Linux ISO.
# Must be run with sudo.
#

set -e

# --- Configuration & Arguments ---
RELENG_SOURCE_DIR="./releng"
ISO_OUTPUT_DIR="./OUT"
WORK_DIR="./work"
ISO_LABEL="ARCH_CUSTOM"

usage() {
    echo "Usage: $0 [-l <label>]"
    echo "Builds the ISO from the './releng' directory."
    echo "  -l, --label <label>  Set a custom ISO label (default: ARCH_CUSTOM)"
    echo "  -h, --help           Display this help message."
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -l|--label) ISO_LABEL="$2"; shift ;;
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
[ "$EUID" -ne 0 ] && print_error "This script must be run as root (or with sudo)."
[ ! -d "$RELENG_SOURCE_DIR" ] && print_error "Releng source directory not found. Run 'custom_releng.sh' first."

print_info "Setting executable permissions on custom scripts..."
chmod +x -R "${RELENG_SOURCE_DIR}/airootfs/usr/local/bin"
chmod +x "${RELENG_SOURCE_DIR}/airootfs/root/interactive-script.sh"
print_success "Permissions set."

print_info "Cleaning previous work directory and creating output directory..."
sudo rm -rf "$WORK_DIR"
mkdir -p "$ISO_OUTPUT_DIR"

print_info "Starting ISO build process (Label: $ISO_LABEL)..."
sudo mkarchiso -v -w "$WORK_DIR" -o "$ISO_OUTPUT_DIR" -L "$ISO_LABEL" "$RELENG_SOURCE_DIR"

ISO_FILE=$(find "$ISO_OUTPUT_DIR" -name "archlinux-*-x86_64.iso")
if [ -f "$ISO_FILE" ]; then
    VERSIONED_FILENAME="archlinux-custom-$(date +%Y.%m.%d).iso"
    sudo mv "$ISO_FILE" "${ISO_OUTPUT_DIR}/${VERSIONED_FILENAME}"
    print_success "Created versioned copy: ${VERSIONED_FILENAME}"
    print_info "\n✅ ISO build complete. Image is located in '${ISO_OUTPUT_DIR}'."
else
    print_error "mkarchiso did not produce an ISO file. Build failed."
fi