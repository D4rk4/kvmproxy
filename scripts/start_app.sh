#!/bin/bash
export DISPLAY=:99

# Ожидание запуска X сервера и KasmVNC
echo "Waiting for X server and KasmVNC to start..."
sleep 10

# Проверка что X сервер запущен
while ! xdpyinfo -display :99 >/dev/null 2>&1; do
    echo "Waiting for X server..."
    sleep 2
done

# Получение параметров из переменных окружения
HOSTNAME=${KVM_HOSTNAME:-""}
USERNAME=${KVM_USERNAME:-"Admin"}
PASSWORD=${KVM_PASSWORD:-""}
TITLE=${KVM_TITLE:-"KVM Console"}

# Формирование команды запуска
CMD="/app/Avocent_KVM_Console_viewer-.glibc2.3-x86_64.AppImage"

if [ ! -z "$TITLE" ]; then
    CMD="$CMD -t \"$TITLE\""
fi

if [ ! -z "$USERNAME" ]; then
    CMD="$CMD -u \"$USERNAME\""
fi

if [ ! -z "$PASSWORD" ]; then
    CMD="$CMD -P \"$PASSWORD\""
fi

if [ ! -z "$HOSTNAME" ]; then
    CMD="$CMD \"$HOSTNAME\""
fi

echo "Starting KVM Console with command: $CMD"

# Установка переменных для лучшей производительности с KasmVNC
export XDG_RUNTIME_DIR=/tmp/runtime-appuser
mkdir -p $XDG_RUNTIME_DIR
chmod 700 $XDG_RUNTIME_DIR

# Запуск приложения
eval $CMD
