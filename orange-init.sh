#!/bin/bash

# Set timezone to Moscow
sudo timedatectl set-timezone Europe/Moscow


rm -f /etc/apt/sources.list.d/docker.list

sudo tee /etc/apt/sources.list >/dev/null <<'EOF'
deb http://deb.debian.org/debian bullseye main contrib non-free
deb-src http://deb.debian.org/debian bullseye main contrib non-free

deb http://deb.debian.org/debian bullseye-updates main contrib non-free
deb-src http://deb.debian.org/debian bullseye-updates main contrib non-free

deb http://security.debian.org/debian-security/ bullseye-security main contrib non-free
deb-src http://security.debian.org/debian-security/ bullseye-security main contrib non-free
EOF

apt-get update

# Configure GPIO
echo "overlays=$(grep -oP '^overlays=\K.*' /boot/orangepiEnv.txt) disable-uart0 ph-uart5 pi-pwm3 pi-pwm4" >> /boot/orangepiEnv.txt

# Disable root SSH login
sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config && sudo systemctl restart ssh

# Allow passwordless sudo for the 'orange' user
echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/010-nopasswd-$USER

# Update hostname
read -p "Введите номер для имени контроллера (rpiXXX): " num

sudo hostnamectl set-hostname "rpi${num}"
echo "Имя хоста изменено на: rpi${num}"

# Change password for the 'orangepi' user
echo "Введите новый пароль: "
read newpass
echo
echo "$USER:$newpass" | sudo chpasswd
echo "Пароль для пользователя $USER изменён."