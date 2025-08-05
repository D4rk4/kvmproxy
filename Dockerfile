# ─────────────────────────────────────────────────────────────
# Build an Avocent-only desktop container on top of KasmVNC
# ─────────────────────────────────────────────────────────────
FROM ghcr.io/linuxserver/baseimage-kasmvnc:debianbookworm


# Copy the viewer
COPY Avocent_KVM_Console_viewer-.glibc2.3-x86_64.AppImage /opt/avocent.appimage
RUN chmod +x /opt/avocent.appimage && \
    /opt/avocent.appimage --appimage-extract && \
    mkdir -p /opt/avocent && \
    mv squashfs-root/* /opt/avocent/ && \
    rm -rf squashfs-root && \
    rm /opt/avocent.appimage

# Autostart wrapper that consumes the four KVM_* vars
RUN printf '%s\n' \
   '#!/bin/bash' \
   'export APPDIR=/opt/avocent' \
   'CMD="xterm -e /opt/avocent/AppRun ${KVM_HOSTNAME:-}"' \
   '[ -n "$KVM_TITLE"    ] &&   CMD="$CMD -t \"$KVM_TITLE\""' \
   '[ -n "$KVM_USERNAME" ] &&   CMD="$CMD -u \"$KVM_USERNAME\""' \
   '[ -n "$KVM_PASSWORD" ] &&   CMD="$CMD -P \"$KVM_PASSWORD\""' \
   'exec $CMD' \
   > /usr/bin/avocent \
 && chmod +x /usr/bin/avocent \
 && echo "avocent" > /defaults/startwm.sh && chmod +x /defaults/startwm.sh

 # Copy KasmWeb configuration
 COPY config.json /usr/share/nginx/html/kasmvnc/config.json
