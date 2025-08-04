#!/bin/bash
set -euo pipefail

echo "=== Avocent KVM Console Container Starting (KasmVNC) ==="

# Создание htpasswd файла из переменных окружения
if [[ -n "$WEB_USERNAME" && -n "$WEB_PASSWORD" ]]; then
    echo "Creating htpasswd file for user: $WEB_USERNAME"
    htpasswd -bc /etc/nginx/auth/.htpasswd "$WEB_USERNAME" "$WEB_PASSWORD"
else
    echo "Warning: WEB_USERNAME or WEB_PASSWORD not set, creating default credentials"
    htpasswd -bc /etc/nginx/auth/.htpasswd "admin" "secure123"
fi

# Создание директорий для xvfb
mkdir -p /tmp/.X11-unix
chown root:root /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix

# Создание и настройка VNC директории
mkdir -p /home/appuser/.vnc
chown -R appuser:appuser /home/appuser/.vnc

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
  interface: 0.0.0.0
logging:
  level: 30
encoding:
  max_frame_rate: 60
  rect_encoding_mode: 0
  webp_image_quality: 80
  jpeg_image_quality: 80
security:
  authentication: none
EOF

# Настройка прав доступа
chown appuser:appuser /home/appuser/.vnc/kasmvnc.yaml

echo "=== KasmVNC Configuration Complete ==="

# Запуск переданной команды
exec "$@"
