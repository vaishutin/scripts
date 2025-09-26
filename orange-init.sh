#!/bin/bash

exec </dev/tty

#!/bin/bash
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

# Пример использования
run_with_spinner "sudo apt-get update -y" "Обновление репозиториев"
run_with_spinner "sleep 3" "Имитация долгой команды"
run_with_spinner "exit 1" "Опа"

# Set timezone to Moscow
run_with_spinner "sudo timedatectl set-timezone Europe/Moscow" "Установка часового пояса"



run_with_spinner "sudo rm -f /etc/apt/sources.list.d/docker.list" "Удаление старых источников Docker"

run_with_spinner "
sudo tee /etc/apt/sources.list >/dev/null <<'EOF'
deb http://deb.debian.org/debian bullseye main contrib non-free
deb-src http://deb.debian.org/debian bullseye main contrib non-free

deb http://deb.debian.org/debian bullseye-updates main contrib non-free
deb-src http://deb.debian.org/debian bullseye-updates main contrib non-free

deb http://security.debian.org/debian-security/ bullseye-security main contrib non-free
deb-src http://security.debian.org/debian-security/ bullseye-security main contrib non-free
EOF
" "Обновление списка источников APT"

run_with_spinner "sudo apt-get update -y" "Обновление репозиториев"

run_with_spinner "
sudo echo "overlays=$(grep -oP '^overlays=\K.*' /boot/orangepiEnv.txt) disable-uart0 ph-uart5 pi-pwm3 pi-pwm4" >> /boot/orangepiEnv.txt
" "Настройка контактов на плате"

run_with_spinner "
sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config && sudo systemctl restart ssh
" "Отключение входа по SSH для root"


run_with_spinner "
echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/010-nopasswd-$USER
" "Настройка sudo без пароля для пользователя"


read -p "Введите номер для имени контроллера (rpiXXX): " num

run_with_spinner "
sudo hostnamectl set-hostname "rpi${num}"
" "Обновление имени хоста"


read -p "Введите новый пароль: " newpass

run_with_spinner "
echo "$USER:$newpass" | sudo chpasswd
" "Смена пароля пользователя"

exit 0