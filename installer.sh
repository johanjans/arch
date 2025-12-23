#!/bin/bash

# --- LOGGING CONFIGURATION ---
LOG_FILE="./install_log.txt"
# Redirect stdout (1) and stderr (2) to both the console and the log file
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Log started at: $(date)"
echo "Writing output to: $LOG_FILE"
# -----------------------------

TARGET_DISK="/dev/nvme1n1" # modify this as needed....
CONFIG_SOURCE="./dotfiles" # a folder named 'dotfiles' next to this script.

# --- SAFETY CHECK START ---
echo "################################################################"
echo "!!! DANGER: DATA DESTRUCTION IMMINENT !!!"
echo "################################################################"
echo "The following disk will be COMPLETELY WIPED:"
echo ""
echo "    >>  ${TARGET_DISK}  <<"
echo ""
echo "Double check this matches your target using 'lsblk'."
echo "Are you absolutely sure you want to continue?"
read -p "Type 'y' to confirm destruction: " -n 1 -r
echo    # move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborting script. No changes made."
    exit 1
fi
echo "Proceeding with installation..."
sleep 2
# --- SAFETY CHECK END ---

PART_BOOT="${TARGET_DISK}p1"
PART_ROOT="${TARGET_DISK}p2"

echo "Installing to NVMe Drive: ${TARGET_DISK}"

loadkeys sv-latin1
timedatectl set-ntp true

# Partitioning (1025MiB boot partition)
parted -s "${TARGET_DISK}" mklabel gpt
parted -s "${TARGET_DISK}" unit mib
parted -s "${TARGET_DISK}" mkpart primary 1 1025
parted -s "${TARGET_DISK}" name 1 boot
parted -s "${TARGET_DISK}" set 1 boot on
parted -s "${TARGET_DISK}" mkpart primary 1025 100%
parted -s "${TARGET_DISK}" name 2 archlinux

# Filesystems
mkfs.ext4 "${PART_ROOT}"
mount "${PART_ROOT}" /mnt
mkfs.fat -F32 "${PART_BOOT}"
mkdir /mnt/boot
mount "${PART_BOOT}" /mnt/boot

# Install Packages
pacstrap /mnt base efibootmgr grub mkinitcpio e2fsprogs                   # boot/fs
pacstrap /mnt linux-zen linux-zen-headers linux-firmware intel-ucode      # kernel/drivers
pacstrap /mnt networkmanager bluez bluez-utils                            # network/bt
pacstrap /mnt pipewire pipewire-pulse wireplumber alsa-utils pavucontrol  # audio
pacstrap /mnt nvidia-open-dkms nvidia-utils egl-wayland                   # gpu
pacstrap /mnt wayland xorg-xwayland wayland-protocols libva-nvidia-driver # wayland
pacstrap /mnt neovim git base-devel man-db openssh curl                   # utils
pacstrap /mnt hyprland uwsm swww kitty mako hypridle                      # hyprland core
pacstrap /mnt brightnessctl hyprpolkitagent hyprlock hyprpicker           # hyprland utils
pacstrap /mnt wofi dolphin                                                # gui apps
pacstrap /mnt nerd-fonts noto-fonts fastfetch                             # fonts/rice
pacstrap /mnt xdg-desktop-portal-hyprland                                 # portals
pacstrap /mnt qt5-wayland qt6-wayland xwaylandvideobridge                 # qt theming
pacstrap /mnt nwg-displays                                                # display manager
pacstrap /mnt pdf2svg rtmpdump atomicparsley xdotool                      # vim deps
pacstrap /mnt python-neovim python-pdftotext python-sympy                 # python deps
pacstrap /mnt nodejs yarn fzf ripgrep bat pacman-contrib                  # dev tools
pacstrap /mnt npm                                                         # for gemini cli installation
pacstrap /mnt python python-gpustat                                       # for hyprpanel

# Configuration
genfstab -pU /mnt >> /mnt/etc/fstab
arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/Stockholm /etc/localtime
arch-chroot /mnt hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
echo "KEYMAP=sv-latin1" > /mnt/etc/vconsole.conf
echo "syskill" > /mnt/etc/hostname

arch-chroot /mnt systemctl enable NetworkManager
arch-chroot /mnt systemctl enable bluetooth

# User Setup
# FIX: Use NOPASSWD temporarily so makepkg/yay can sudo without a TTY
echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /mnt/etc/sudoers

arch-chroot /mnt useradd -m -g users -G wheel,audio,video -s /bin/bash johan
arch-chroot /mnt passwd johan
arch-chroot /mnt passwd -d root
arch-chroot /mnt sed -i 's/MODULES=()/MODULES=(i915 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
arch-chroot /mnt mkinitcpio -P
arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot
arch-chroot /mnt sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet"/GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet nvidia_drm.modeset=1"/' /etc/default/grub
arch-chroot /mnt sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/' /etc/default/grub
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

# dotfiles
cp -r "$CONFIG_SOURCE"/. /mnt/home/johan/

# claude cli
arch-chroot /mnt /bin/bash -c "su - johan -c 'curl -fsSL https://claude.ai/install.sh | bash'"

# gemini cli
arch-chroot /mnt /bin/bash -c "su - johan -c 'mkdir -p ~/.local && npm config set prefix \"~/.local\"'"
arch-chroot /mnt /bin/bash -c "su - johan -c 'npm install -g @google/gemini-cli'"

# yay and yay-stuff
arch-chroot /mnt chown -R johan:users /home/johan
arch-chroot /mnt /bin/bash -c "su - johan -c 'git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si --noconfirm'"
arch-chroot /mnt /bin/bash -c "rm -rf /home/johan/yay"
arch-chroot /mnt /bin/bash -c "su - johan -c 'yay -S --noconfirm --answerdiff=None --answerclean=None ags-hyprpanel-git aylurs-gtk-shell-git libgtop btop dart-sass wl-clipboard upower power-profiles-daemon gvfs gtksourceview3 libsoup3 grimblast-git wf-recorder-git matugen-bin hyprsunset-git'"
arch-chroot /mnt /bin/bash -c "su - johan -c 'yay -S --noconfirm --answerdiff=None --answerclean=None google-chrome'"

# REVERT SUDOERS (Security Fix)
# This removes NOPASSWD so the user must type their password after reboot
arch-chroot /mnt sed -i 's/%wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

# Finish
umount -R /mnt
echo "---------------------------------------------------------"
echo "Installation complete! Logs saved to $LOG_FILE."
echo "You can now reboot manually by typing 'reboot'."
echo "---------------------------------------------------------"