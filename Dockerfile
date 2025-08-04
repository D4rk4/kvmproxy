FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:99

# Установка необходимых пакетов
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    xvfb \
    fluxbox \
    supervisor \
    nginx \
    apache2-utils \
    procps \
    net-tools \
    software-properties-common \
    gpg-agent \
    ca-certificates \
    libjpeg-turbo8-dev \
    libpng-dev \
    libtiff5-dev \
    libgif-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Создание пользователя для запуска приложений
RUN useradd -m -s /bin/bash appuser

# Создание директорий
RUN mkdir -p /app /var/log/supervisor /etc/supervisor/conf.d /etc/nginx/auth

# Установка KasmVNC
RUN wget -O /tmp/kasmvnc.deb https://github.com/kasmtech/KasmVNC/releases/download/v1.3.3/kasmvncserver_jammy_1.3.3_amd64.deb \
    && dpkg -i /tmp/kasmvnc.deb || true \
    && apt-get update \
    && apt-get install -f -y \
    && rm /tmp/kasmvnc.deb

# Создание пароля VNC для KasmVNC (требуется для работы)
RUN mkdir -p /home/appuser/.vnc \
    && echo -e "password\npassword\n" | vncpasswd /home/appuser/.vnc/passwd \
    && chmod 600 /home/appuser/.vnc/passwd \
    && chown -R appuser:appuser /home/appuser/.vnc

# Копирование конфигурационных файлов
COPY configs/nginx.conf /etc/nginx/sites-available/default
COPY configs/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY scripts/start_app.sh /app/start_app.sh
COPY scripts/entrypoint.sh /entrypoint.sh

RUN chmod +x /app/start_app.sh /entrypoint.sh

# Копирование AppImage в контейнер
COPY Avocent_KVM_Console_viewer-.glibc2.3-x86_64.AppImage /app/
RUN chmod +x /app/Avocent_KVM_Console_viewer-.glibc2.3-x86_64.AppImage \
    && chown appuser:appuser /app/Avocent_KVM_Console_viewer-.glibc2.3-x86_64.AppImage

# Настройка прав доступа для appuser
RUN chown -R appuser:appuser /home/appuser

# Открытие портов
EXPOSE 80 6901

# Переменные окружения по умолчанию
ENV WEB_USERNAME=admin
ENV WEB_PASSWORD=secure123
ENV KVM_USERNAME=Admin
ENV KVM_PASSWORD=""
ENV KVM_HOSTNAME=""
ENV KVM_TITLE="Avocent KVM Console"
ENV VNC_RESOLUTION=1920x1080

# Команда запуска
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
