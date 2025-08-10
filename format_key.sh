#!/bin/bash
#
# format_key.sh - Prepares a USB key with dynamic partitioning and writes the ISO.
# Must be run with sudo.
#

set -e

# --- Configuration & Arguments ---
ISO_FILE=""
TARGET_DEV=""
STORAGE_SIZE="512M"
BRUTE_FORCE=false
NO_CONFIRM=false
ARCHISO_PART_NAME="ARCHISO"
PERSISTENCE_PART_NAME="persistence"
STORAGE_PART_NAME="STORAGE"

usage() {
    echo "Usage: $0 -i <iso_file> -d <device> [options]"
    echo ""
    echo "Required:"
    echo "  -i, --iso <file>         Path to the Arch Linux ISO file to be written."
    echo "  -d, --device <path>      Path to the target block device (e.g., /dev/sdb)."
    echo ""
    echo "Optional:"
    echo "  -s, --storage-size <size>  Size for the STORAGE partition (default: 512M)."
    echo "  -b, --brute-force        Perform a full brute-force wipe of the entire device (writes zeros)."
    echo "  -y, --no-confirm         Bypass the interactive confirmation prompt."
    echo "  -h, --help                 Display this help message."
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -i|--iso) ISO_FILE="$2"; shift ;;
        -d|--device) TARGET_DEV="$2"; shift ;;
        -s|--storage-size) STORAGE_SIZE="$2"; shift ;;
        -b|--brute-force) BRUTE_FORCE=true ;;
        -y|--no-confirm) NO_CONFIRM=true ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown parameter passed: $1"; usage; exit 1 ;;
    esac
    shift
done

# --- Functions ---
print_success() { echo -e "\e[32m✔ $1\e[0m"; }
print_info() { echo -e "\e[34mℹ $1\e[0m"; }
print_error() { echo -e "\e[31m✖ $1\e[0m"; exit 1; }

# --- Validation ---
[ "$EUID" -ne 0 ] && print_error "This script must be run as root (or with sudo)."
[ -z "$ISO_FILE" ] || [ -z "$TARGET_DEV" ] && usage && print_error "ISO file and target device must be specified."
[ ! -f "$ISO_FILE" ] && print_error "ISO file not found at '$ISO_FILE'."
[ ! -b "$TARGET_DEV" ] && print_error "Target device '$TARGET_DEV' is not a valid block device."

# --- Main Logic ---
ISO_SIZE_BYTES=$(stat -c%s "$ISO_FILE")
BUFFER_BYTES=$((100 * 1024 * 1024))
PART1_SIZE_MB=$(( (ISO_SIZE_BYTES + BUFFER_BYTES) / 1024 / 1024 + 1 ))

print_info "--- Configuration Summary ---"
echo "  ISO File:           $ISO_FILE ($(numfmt --to=iec-i --suffix=B $ISO_SIZE_BYTES))"
echo "  Target Device:      $TARGET_DEV"
echo "  ARCHISO Partition:  ${PART1_SIZE_MB}M"
echo "  STORAGE Partition:  $STORAGE_SIZE"
echo "  Full Brute-force Wipe: $BRUTE_FORCE"
echo "-------------------------------"

if [ "$NO_CONFIRM" = false ]; then
    echo "WARNING: This will completely WIPE the device $TARGET_DEV."
    if [ "$BRUTE_FORCE" = true ]; then
        echo "The --brute-force option will write zeros to the ENTIRE disk. This may take a long time."
    fi
    read -p "Are you absolutely sure you want to proceed? (yes/no): " CONFIRM
    [ "$CONFIRM" != "yes" ] && echo "Operation cancelled." && exit 0
fi

print_info "Wiping device..."
sudo umount "${TARGET_DEV}"* 2>/dev/null || true

# --- FIX: Implement TRUE Brute-Force Wipe ---
if [ "$BRUTE_FORCE" = true ]; then
    print_info "Performing full brute-force wipe. This will take a while..."
    # Writing zeros to the entire disk is the ultimate way to erase it.
    sudo dd if=/dev/zero of="$TARGET_DEV" bs=4M status=progress conv=fsync || true
else
    # The standard wipe is sufficient for most cases. It's much faster.
    sudo sgdisk --zap-all "$TARGET_DEV"
fi
print_success "Device wipe complete."

print_info "Creating new 3-partition layout..."
# Even after a dd wipe, running zap-all is good practice to ensure a clean GPT state.
sudo sgdisk --zap-all "$TARGET_DEV"
sudo sgdisk --new=1:0:+${PART1_SIZE_MB}M --typecode=1:8300 --change-name=1:"${ARCHISO_PART_NAME}" "$TARGET_DEV"
sudo sgdisk --new=3:-${STORAGE_SIZE}:0 --typecode=3:0700 --change-name=3:"${STORAGE_PART_NAME}" "$TARGET_DEV"
sudo sgdisk --new=2:0:0 --typecode=2:8300 --change-name=2:"${PERSISTENCE_PART_NAME}" "$TARGET_DEV"
print_success "Device partitioned."

print_info "Formatting partitions..."
sudo partprobe "$TARGET_DEV" && sleep 2
sudo mkfs.ext4 -F -L "${PERSISTENCE_PART_NAME}" "${TARGET_DEV}2"
sudo mkfs.vfat -F32 -n "${STORAGE_PART_NAME}" "${TARGET_DEV}3"
print_success "Partitions formatted."

print_info "Writing ISO to ${TARGET_DEV}1..."
sudo dd if="$ISO_FILE" of="${TARGET_DEV}1" bs=4M status=progress conv=fsync
print_success "ISO written successfully."

print_info "\n✅ USB Key preparation complete!"