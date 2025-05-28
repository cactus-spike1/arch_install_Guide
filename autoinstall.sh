#!/bin/bash

# Установка необходимых пакетов
pacman -Sy --noconfirm archlinux-keyring
pacman -S --noconfirm base linux linux-firmware nano grub efibootmgr networkmanager

# Настройка системного времени
timedatectl set-ntp true

# Разметка диска
(
echo o # Создать новую таблицу разделов
echo n # Новый раздел
echo 1 # Номер раздела
echo   # Начало (по умолчанию)
echo +515M # Размер EFI раздела
echo t # Изменить тип раздела
echo 1 # Номер раздела
echo 1 # Тип EFI System
echo n # Новый раздел
echo 2 # Номер раздела
echo   # Начало (по умолчанию)
echo   # Конец (по умолчанию, использовать всё оставшееся пространство)
echo w # Записать изменения
) | fdisk /dev/sda

# Форматирование разделов
mkfs.fat -F32 /dev/sda1
mkfs.ext4 /dev/sda2

# Монтирование разделов
mount /dev/sda2 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

# Установка базовой системы
pacstrap /mnt base linux linux-firmware nano grub efibootmgr networkmanager

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
echo "root:password" | chpasswd

# Создание пользователя
useradd -m -G wheel -s /bin/bash user
echo "user:password" | chpasswd

# Установка загрузчика GRUB
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Включение NetworkManager
systemctl enable NetworkManager

EOF

# Завершение установки
umount -R /mnt
reboot
