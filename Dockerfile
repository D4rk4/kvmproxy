FROM bitnami/minideb:bookworm

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:99

# Установка необходимых пакетов
RUN apt-get update && apt-get install -y \
    xvfb \
    xauth \
    fluxbox \
    supervisor \
    nginx \
    wget \
    apache2-utils \
    procps \
    net-tools \
    ca-certificates \
    && wget -O /tmp/kasmvnc.deb https://github.com/kasmtech/KasmVNC/releases/download/v1.3.4/kasmvncserver_bookworm_1.3.4_amd64.deb \
    && apt-get install -y /tmp/kasmvnc.deb \
    && rm /tmp/kasmvnc.deb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Создание пользователя для запуска приложений
RUN useradd -m -s /bin/bash appuser

# Создание директорий
RUN mkdir -p /app /var/log/supervisor /etc/supervisor/conf.d /etc/nginx/auth

# Создание пароля VNC для KasmVNC (требуется для работы)
RUN mkdir -p /home/appuser/.vnc \
    && echo "appuser\nappuser\n" | vncpasswd -u appuser -o /home/appuser/.vnc/passwd \
    && chmod 600 /home/appuser/.vnc/passwd \
    && chown -R appuser:appuser /home/appuser/.vnc


# Копирование AppImage в контейнер
COPY Avocent_KVM_Console_viewer-.glibc2.3-x86_64.AppImage /app/
RUN chmod +x /app/Avocent_KVM_Console_viewer-.glibc2.3-x86_64.AppImage \
    && chown appuser:appuser /app/Avocent_KVM_Console_viewer-.glibc2.3-x86_64.AppImage

# Копирование конфигурационных файлов
COPY configs/nginx.conf /etc/nginx/sites-available/default
COPY configs/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY scripts/start_app.sh /app/start_app.sh
COPY scripts/entrypoint.sh /entrypoint.sh

RUN chmod +x /app/start_app.sh /entrypoint.sh

# Настройка прав доступа для appuser
RUN chown -R appuser:appuser /home/appuser

# Открытие портов
EXPOSE 8080

# Переменные окружения по умолчанию
ENV WEB_USERNAME=admin \
    WEB_PASSWORD=secure123 \
    KVM_USERNAME=Admin \
    KVM_PASSWORD= \
    KVM_HOSTNAME= \
    KVM_TITLE="Avocent KVM Console"

# Команда запуска
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
