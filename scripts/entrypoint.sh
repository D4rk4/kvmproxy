#!/bin/bash
set -euo pipefail
export DISPLAY=:99


echo "=== Avocent KVM Console Container Starting (KasmVNC) ==="

# Создание htpasswd файла из переменных окружения
if [[ -n "$WEB_USERNAME" && -n "$WEB_PASSWORD" ]]; then
    echo "Creating htpasswd file for user: $WEB_USERNAME"
    htpasswd -bc /etc/nginx/auth/.htpasswd "$WEB_USERNAME" "$WEB_PASSWORD"
else
    echo "Warning: WEB_USERNAME or WEB_PASSWORD not set, creating default credentials"
    htpasswd -bc /etc/nginx/auth/.htpasswd "admin" "secure123"
fi

# Создание директорий для Xvnc
mkdir -p /tmp/.X11-unix
chown root:root /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix

# Создание и настройка VNC директории
mkdir -p /home/appuser/.vnc
chown -R appuser:appuser /home/appuser/.vnc

# Настройка запуска fluxbox через xstartup
cat > /home/appuser/.vnc/xstartup << 'EOF'
#!/bin/sh
exec fluxbox
EOF
chmod +x /home/appuser/.vnc/xstartup
chown appuser:appuser /home/appuser/.vnc/xstartup

# Создание и настройка Xauthority
touch /home/appuser/.Xauthority
chown appuser:appuser /home/appuser/.Xauthority
export XAUTHORITY=/home/appuser/.Xauthority
#xauth generate "$DISPLAY" . trusted
#xauth add "$(hostname)/unix:$DISPLAY" . "$(xauth list "$DISPLAY" | awk '{print $3}')"


# Создание конфигурации KasmVNC
cat > /home/appuser/.vnc/kasmvnc.yaml << EOF
desktop:
  resolution:
    width: 1280
    height: 1024
network:
  websocket_port: 6901
  ssl:
    require_ssl: false
  interface: 127.0.0.1
logging:
  level: 10
encoding:
  max_frame_rate: 30
EOF

# Настройка прав доступа
chown appuser:appuser /home/appuser/.vnc/kasmvnc.yaml

echo "=== KasmVNC Configuration Complete ==="

# Запуск переданной команды
exec "$@"
