#!/bin/bash
set -eou pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
log="/tmp/$(basename "$0")-$(date +%s).log"
run_with_spinner() {
  local cmd="$1"
  local msg="$2"

  # Запускаем команду в фоне
  ( eval "$cmd" >> "$log" 2>&1 ) &
  pid=$!

  i=0
  while kill -0 $pid 2>/dev/null; do
    i=$(( (i+1) % ${#spin} ))
    printf "\r${YELLOW}${spin:$i:1}${NC} %s" "$msg"
    sleep 0.1
  done

  wait $pid
  status=$?

  if [ $status -eq 0 ]; then
    printf "\r[${GREEN}✔${NC}] %s\n" "$msg"
  else
    printf "\r[${RED}✘${NC}] %s (см. лог: %s)\n" "$msg" "$log"
  fi
  return $status
}

sudo whoami > /dev/null
#run_with_spinner "whoami" "Авторизация"
# Set timezone to Moscow
run_with_spinner "sudo timedatectl set-timezone Europe/Moscow" "Установка часового пояса"



run_with_spinner "sudo rm -f /etc/apt/sources.list.d/docker.list" "Удаление старых источников Docker"

run_with_spinner "
sudo tee /etc/apt/sources.list >/dev/null <<'EOF'
deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
deb http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
EOF
" "Обновление списка источников APT"

run_with_spinner "sudo apt-get update -y" "Обновление репозиториев"

run_with_spinner "
sudo sed -i '/^overlays/d' /boot/orangepiEnv.txt;
echo 'overlays=disable-uart0 ph-uart5 pi-pwm3 pi-pwm4' | sudo tee -a /boot/orangepiEnv.txt
" "Настройка контактов на плате"

run_with_spinner "
sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config && sudo systemctl restart ssh
" "Отключение входа по SSH для root"


run_with_spinner "
echo \"$USER ALL=(ALL) NOPASSWD:ALL\" | sudo tee /etc/sudoers.d/010-nopasswd-$USER
" "Настройка sudo без пароля для пользователя"


read -p "Введите номер для имени контроллера (rpiXXX): " num < /dev/tty

run_with_spinner "
sudo hostnamectl set-hostname \"rpi${num}\"
" "Обновление имени хоста"


read -p "Введите новый пароль: " newpass < /dev/tty

run_with_spinner "
echo \"$USER:$newpass\" | sudo chpasswd
" "Смена пароля пользователя"

exit 0
