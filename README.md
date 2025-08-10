# Custom Arch Linux Live ISO with Persistence | ARCHISO

This project provides a complete, automated framework for building a personalized and persistent Arch Linux live USB. It transforms the standard, read-only Arch installation media into a powerful, portable, and permanent toolkit customized to your exact needs.

## Index

- [1. Project Overview & Features](#1-project-overview--features)
- [2. How to Customize Your ISO](#2-how-to-customize-your-iso)
- [3. Getting Started](#3-getting-started)
- [4. The Automated Workflow](#4-the-automated-workflow)
- [5. Manual Procedure](#5-manual-procedure)

## 1. Project Overview & Features

This framework builds a bootable USB drive with a sophisticated set of features designed for flexibility and power. At a glance, the final key provides:

*   **True System Persistence:** All changes you make—shell history, system settings, newly installed packages, and created files—are saved and persist across reboots.
*   **3-Partition Layout:**
    *   **`ARCHISO`:** A dynamically-sized partition for the OS, ensuring no wasted space.
    *   **`persistence`:** A large partition using all remaining space to save your data.
    *   **`STORAGE`:** A cross-platform `vfat` partition for easy file sharing, automatically mounted at `/mnt/storage`.
*   **Customizable Package Set:** The ISO is pre-loaded with a curated list of tools like `neovim`, `git`, `btop`, `fastfetch`, and `tmux`. This list is easily editable.
*   **Automated Terminal Experience:** On boot, `tmux` is automatically launched, providing a modern, multi-pane terminal environment out-of-the-box.
*   **Enhanced Zsh Shell:** The root user's Zsh shell is pre-configured with a clean prompt, command history, and useful aliases.
*   **Custom Scripts:** The environment is pre-loaded with helper scripts (like `Installation_guide`) available as system-wide commands.
*   **Fully Automated Workflow:** Three robust helper scripts (`custom_releng.sh`, `build_iso.sh`, `format_key.sh`) manage the entire process, from applying your customizations to writing the final bootable image.

This makes it an ideal solution for system administrators, developers, and Arch Linux enthusiasts who need a reliable, on-the-go environment for system recovery, hardware testing, remote administration, or even as a daily-driver OS.

## 2. How to Customize Your ISO

All customizations are managed by editing files within the `custom_files/` directory. This directory acts as a template; any file you place here will overwrite the default file during the build process.

| Feature                          | What it is                                                                                                                              | File(s) to Edit in `custom_files/releng/`                                                                                      |
| :------------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------- | :----------------------------------------------------------------------------------------------------------------------------- |
| **Persistence**                  | Allows all system changes to be saved across reboots.                                                                                    | `grub/grub.cfg`<br>`syslinux/archiso_sys-linux.cfg`<br>`efiboot/loader/entries/*`                                               |
| **Custom Packages**              | A curated set of useful command-line tools like `neovim`, `git`, `btop`, `fastfetch`, and `tmux`.                                       | `packages.x86_64`                                                                                                              |
| **Automatic Tmux**               | `tmux` launches automatically upon booting into the main TTY for a modern, multi-pane terminal experience.                             | `airootfs/root/.zprofile`                                                                                                      |
| **Welcome Script**               | A startup script runs in the first `tmux` window, displaying system information using `fastfetch` and `lsblk`.                             | `airootfs/root/interactive-script.sh`                                                                                          |
| **Enhanced Zsh Shell**           | The root user's Zsh shell is pre-configured with a clean prompt, command history, and useful aliases like `ll`.                          | `airootfs/root/.zshrc`                                                                                                         |
| **Tmux Configuration**           | `tmux` is configured with an intuitive prefix (`Ctrl+a`), mouse support, and pane-splitting keybinds.                                      | `airootfs/root/tmux/.tmux.conf`                                                                                                |
| **Automount `STORAGE` Partition**| The `STORAGE` partition on the USB key is automatically mounted at `/mnt/storage` for easy access.                                       | `airootfs/etc/systemd/system/mnt-storage.mount`                                                                                |
| **Helper Scripts**               | Additional scripts are available system-wide as commands (e.g., `Installation_guide`, `choose-mirror`).                                  | `airootfs/usr/local/bin/*`                                                                                                     |

## 3. Getting Started

### 3.1. Requirements

This framework was built and tested on an Arch Linux system with the following versions.

| Package    | Version        |
| :--------- | :------------- |
| `archiso`  | `85-1`         |
| `git`      | `2.50.1-3`     |
| `rsync`    | `3.4.1-2`      |
| `gptfdisk` | `1.0.10-1`     |
| **Kernel** | `6.15.9-arch1-1` |

Install the required tools:
```bash
sudo pacman -S --needed archiso git rsync gptfdisk
```

### 3.2. Project Setup

After cloning this repository, simply begin editing the files within the `custom_files/` directory to match your preferences. `git` manages this directory's contents, and the build scripts handle its integration.

## 4. The Automated Workflow

These three scripts automate the entire process. Run them in order from the project's root directory.

### 4.1. Script 1: `./custom_releng.sh`

*   **Purpose:** Prepares the build environment by setting up a fresh `releng` directory and applying your customizations from `custom_files/`.
*   **Usage:**
    ```bash
    ./custom_releng.sh
    ```
*   **Arguments:**
    ```arguments
    -c, --custom <dir>   Path to custom files overlay (default: ./custom_files/releng)
    -h, --help           Display this help message.
    ```
### 4.2. Script 2: `sudo ./build_iso.sh`

*   **Purpose:** Builds the `.iso` file from the prepared `releng` directory.
*   **Usage:**
    ```bash
    sudo ./build_iso.sh
    ```
*   **Arguments:**
    ```arguments
    -l, --label <label>  Set a custom ISO label (default: ARCH_CUSTOM)
    -h, --help           Display this help message.
    ```
### 4.3. Script 3: `sudo ./format_key.sh`

*   **Purpose:** Wipes a target USB drive, creates the dynamic 3-partition layout, and writes the ISO.
*   **Usage:**
    ```bash
    # Standard usage:
    sudo ./format_key.sh -i ./OUT/archlinux-*.iso -d /dev/sdb

    # For stubborn or corrupted drives (slower, but guarantees a clean wipe):
    sudo ./format_key.sh -i ./OUT/archlinux-*.iso -d /dev/sdb --brute-force
    ```
*   **Arguments:**
    ```arguments
    Required:
    -i, --iso <file>         Path to the Arch Linux ISO file to be written.
    -d, --device <path>      Path to the target block device (e.g., /dev/sdb).
    Optional:
    -s, --storage-size <size>  Size for the STORAGE partition (default: 512M).
    -b, --brute-force        Perform a full brute-force wipe of the entire device (writes zeros).
    -y, --no-confirm         Bypass the interactive confirmation prompt.
    -h, --help                 Display this help message.
    ```
## 5. Manual Procedure

This is the underlying command sequence if you prefer to run the steps manually.

### Step 1: Prepare the `releng` Directory
```bash
sudo rm -rf releng/
cp -r /usr/share/archiso/configs/releng/ ./releng/
rsync -a ./custom_files/releng/ ./releng/
ln -sf /etc/systemd/system/mnt-storage.mount ./releng/airootfs/etc/systemd/system/multi-user.target.wants/mnt-storage.mount
```

### Step 2: Build the ISO
```bash
sudo chmod +x -R ./releng/airootfs/usr/local/bin/
sudo rm -rf work/
mkdir -p OUT/
sudo mkarchiso -v -w ./work -o ./OUT -L "ARCH_CUSTOM" ./releng/
sudo mv ./OUT/archlinux-*-x86_64.iso ./OUT/archlinux-custom-$(date +%Y.%m.%d).iso
```

### Step 3: Partition and Format the USB Key
**WARNING:** This is destructive. Ensure `TARGET_DEV` is correct.
```bash
# 1. Define variables
TARGET_DEV=/dev/sdb
ISO_FILE=./OUT/archlinux-custom-$(date +%Y.%m.%d).iso
STORAGE_SIZE="512M"

# 2. Calculate ISO partition size
ISO_SIZE_BYTES=$(stat -c%s "$ISO_FILE")
BUFFER_BYTES=$((100 * 1024 * 1024))
PART1_SIZE_MB=$(( (ISO_SIZE_BYTES + BUFFER_BYTES) / 1024 / 1024 + 1 ))

# 3. Wipe and partition
sudo umount ${TARGET_DEV}* 2>/dev/null || true
sudo sgdisk --zap-all ${TARGET_DEV}
sudo sgdisk --new=1:0:+${PART1_SIZE_MB}M --typecode=1:8300 --change-name=1:"ARCHISO" ${TARGET_DEV}
sudo sgdisk --new=3:-${STORAGE_SIZE}:0 --typecode=3:0700 --change-name=3:"STORAGE" ${TARGET_DEV}
sudo sgdisk --new=2:0:0 --typecode=2:8300 --change-name=2:"persistence" ${TARGET_DEV}

# 4. Format
sudo partprobe ${TARGET_DEV} && sleep 2
sudo mkfs.ext4 -F -L "persistence" ${TARGET_DEV}2
sudo mkfs.vfat -F32 -n "STORAGE" ${TARGET_DEV}3
```

### Step 4: Write the ISO to the Key
```bash
sudo dd if="$ISO_FILE" of="${TARGET_DEV}1" bs=4M status=progress conv=fsync
```
