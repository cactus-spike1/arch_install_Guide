#!/bin/bash

# Настройки по умолчанию
USERNAME="${USERNAME:-user}"        # Имя пользователя (по умолчанию "user")
PASSWORD="${PASSWORD:-password}"    # Пароль для пользователя (по умолчанию "password")
ROOT_PASSWORD="${ROOT_PASSWORD:-rootpassword}"  # Пароль для root (по умолчанию "rootpassword")
EFI_SIZE="${EFI_SIZE:-512M}"        # Размер EFI раздела (по умолчанию 512M)
DISK="/dev/sda"                     # Диск для установки (по умолчанию /dev/sda)

# Установка необходимых пакетов
pacman -Sy --noconfirm archlinux-keyring
pacman -S --noconfirm base linux linux-firmware nano grub efibootmgr networkmanager sudo

# Настройка системного времени
timedatectl set-ntp true

# Разметка диска
(
echo g # Создать новую GPT таблицу
echo n # Новый раздел
echo 1 # Номер раздела
echo   # Начало (по умолчанию)
echo +$EFI_SIZE # Размер EFI раздела
echo t # Изменить тип раздела
echo 1 # Номер раздела
echo 1 # Тип EFI System
echo n # Новый раздел
echo 2 # Номер раздела
echo   # Начало (по умолчанию)
echo   # Конец (по умолчанию, использовать всё оставшееся пространство)
echo w # Записать изменения
) | fdisk $DISK

# Форматирование разделов
mkfs.fat -F32 ${DISK}1
mkfs.ext4 ${DISK}2

# Монтирование разделов
mount ${DISK}2 /mnt
mkdir /mnt/boot
mount ${DISK}1 /mnt/boot

# Установка базовой системы
pacstrap /mnt base linux linux-firmware nano grub efibootmgr networkmanager sudo

# Настройка fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot в новую систему
arch-chroot /mnt /bin/bash <<EOF

# Установка временной зоны
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc

# Настройка локали
locale-gen
echo "LANG=ru_RU.UTF-8" > /etc/locale.conf

# Настройка hostname
echo "myarch" > /etc/hostname
cat <<EOL >> /etc/hosts
127.0.0.1 localhost
::1 localhost
127.0.0.1 myarch
EOL

# Установка пароля для root
echo "root:$ROOT_PASSWORD" | chpasswd

# Создание пользователя
useradd -m -G wheel -s /bin/bash $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd

# Настройка sudo
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# Установка загрузчика GRUB
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Включение NetworkManager
systemctl enable NetworkManager

EOF

# Завершение установки
umount -R /mnt
reboot
