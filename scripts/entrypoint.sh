#!/bin/bash
set -e

echo "=== Avocent KVM Console Container Starting (KasmVNC) ==="

# Создание htpasswd файла из переменных окружения
if [ ! -z "$WEB_USERNAME" ] && [ ! -z "$WEB_PASSWORD" ]; then
    echo "Creating htpasswd file for user: $WEB_USERNAME"
    htpasswd -bc /etc/nginx/auth/.htpasswd "$WEB_USERNAME" "$WEB_PASSWORD"
else
    echo "Warning: WEB_USERNAME or WEB_PASSWORD not set, creating default credentials"
    htpasswd -bc /etc/nginx/auth/.htpasswd "admin" "secure123"
fi

# Настройка VNC разрешения
# Максимальное разрешение для Avocent SVIP1020 составляет 1280x1024,
# поэтому при превышении этих значений разрешение принудительно
# ограничивается указанным максимумом.
MAX_WIDTH=1280
MAX_HEIGHT=1024
VNC_RESOLUTION=${VNC_RESOLUTION:-"1280x1024"}

REQ_WIDTH=$(echo "$VNC_RESOLUTION" | cut -d'x' -f1)
REQ_HEIGHT=$(echo "$VNC_RESOLUTION" | cut -d'x' -f2)
if [ "$REQ_WIDTH" -gt "$MAX_WIDTH" ] || [ "$REQ_HEIGHT" -gt "$MAX_HEIGHT" ]; then
    echo "Requested resolution $VNC_RESOLUTION exceeds maximum ${MAX_WIDTH}x${MAX_HEIGHT}. Using ${MAX_WIDTH}x${MAX_HEIGHT}."
    VNC_RESOLUTION="${MAX_WIDTH}x${MAX_HEIGHT}"
fi

export VNC_RESOLUTION
echo "Setting VNC resolution to: $VNC_RESOLUTION"

# Создание и настройка VNC директории
mkdir -p /home/appuser/.vnc
chown -R appuser:appuser /home/appuser/.vnc

# Создание конфигурации KasmVNC
cat > /home/appuser/.vnc/kasmvnc.yaml << EOF
desktop:
  resolution:
    width: $(echo $VNC_RESOLUTION | cut -d'x' -f1)
    height: $(echo $VNC_RESOLUTION | cut -d'x' -f2)
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
