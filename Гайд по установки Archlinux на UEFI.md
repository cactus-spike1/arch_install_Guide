# Установка Arch Linux

## 1. Запуск LiveCD Arch Linux

## 2. Проверка интернет-соединения и обновление системного времени
```bash
ping google.com
```

```bash
timedatectl set-ntp true
```

## 3. Разметка диска с помощью `cfdisk`
sudo cfdisk /dev/sdX
- **Раздел EFI**: 515M, тип `EFI System`
- **Корневой раздел**: стандарт, всё пространство
- **Swap**: 50% от объёма ОЗУ

## 4. Форматирование разделов
- Для EFI раздела:
```bash
mkfs.fat -F32 /dev/sdX1
```
- Для корневого раздела:
```bash
mkfs.ext4 /dev/sdX2
```
- Если есть swap:
```bash
mkswap /dev/sdX3
swapon /dev/sdX3
```

## 5. Монтирование разделов
```bash
mount /dev/sdX2 /mnt
mkdir /mnt/boot
mount /dev/sdX1 /mnt/boot
```

## 6. Установка базовой системы (pacstrap)
```bash
pacstrap /mnt base linux linux-firmware nano
```
- **base**: стандартные пакеты
- **linux**: ядро
- **linux-firmware**: пакеты с прошивками
- **nano**: консольный текстовый редактор
- Дополнительно можно установить:
  - **sddm**: менеджер входа для X11 и Wayland
  - **hyprland**: современный динамический композитор для Wayland

## 7. Настройка fstab
```bash
genfstab -U /mnt >> /mnt/etc/fstab
```

## 8. Chroot в новую систему и базовая настройка
```bash
arch-chroot /mnt
```

### 8.1 Установка временной зоны
```bash
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc
```

### 8.2 Настройка локали
```bash
locale-gen
echo "LANG=ru_RU.UTF-8" > /etc/locale.conf
```

### 8.3 Настройка hostname
```bash
echo "{namehost}" > /etc/hostname
```
#### Настройка `/etc/hosts`
```hosts
127.0.0.1 localhost
::1 localhost
127.0.0.1 {namehost}
```

### 8.4 Установка пароля для root
```bah
passwd
```

### 8.5 Создание пользователя
```bash
useradd -m -G wheel -s /bin/bash {username}
```

### 8.6 Установка пароля для пользователя
```bash
passwd {username}
```

## 9. Установка загрузчика GRUB

### 9.1 Установка необходимых пакетов
```bash
pacman -S grub efibootmgr
```

### 9.2 Установка GRUB в EFI-раздел
```bash
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
```

### 9.3 Генерация конфигурации GRUB
```bash
grub-mkconfig -o /boot/grub/grub.cfg
```

## 10. Завершение установки

### 10.1 Выход из chroot
```bash
exit
```

### 10.2 Отмонтирование всех разделов
```bash
umount -R /mnt
```

### 10.3 Перезагрузка системы
```bash
reboot
```

