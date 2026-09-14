FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Jakarta
ENV USER=root

RUN apt-get update && apt-get install -y --no-install-recommends \
    xfce4 \
    xfce4-goodies \
    tigervnc-standalone-server \
    tigervnc-common \
    tigervnc-tools \
    novnc \
    websockify \
    dbus-x11 \
    x11-utils \
    x11-xserver-utils \
    x11-apps \
    xterm \
    sudo \
    vim \
    net-tools \
    curl \
    wget \
    git \
    tzdata \
    firefox \
    openssl \
    python3-numpy \
    && rm -rf /var/lib/apt/lists/*

RUN touch /root/.Xauthority
RUN mkdir -p /root/.vnc

RUN printf '#!/bin/bash\n\
export USER=root\n\
startxfce4\n' > /root/.vnc/xstartup

RUN chmod +x /root/.vnc/xstartup

# Modifikasi UI noVNC agar meminta password secara eksplisit melalui URL/Token
RUN sed -i 's/UI.connect()/UI.connect(UI.getSetting("password") || prompt("Masukkan Password:"))/g' /usr/share/novnc/app/ui.js || true

EXPOSE 5901
EXPOSE 6080

CMD bash -c '\
# 1. Jalankan VNC di jaringan internal (localhost) TANPA password (aman karena tidak diekspos keluar)
vncserver :1 \
    -localhost yes \
    -SecurityTypes None \
    -geometry 1024x768 \
    -depth 24 \
    && \
# 2. Buat sertifikat SSL
openssl req \
    -new \
    -subj "/C=ID" \
    -x509 \
    -days 365 \
    -nodes \
    -out /root/self.pem \
    -keyout /root/self.pem \
    && \
# 3. Buat file konfigurasi token untuk websockify
mkdir -p /root/novnc_tokens && \
echo "vnc: localhost:5901" > /root/novnc_tokens/token.conf && \
# 4. Jalankan Websockify yang mengekspos port 6080 dengan password Basic Auth
# Menggunakan VNC_PASSWORD dari Railway, default: kelvin12
PASS=${VNC_PASSWORD:-kelvin12} && \
echo "Memulai Websockify..." && \
websockify \
    --web /usr/share/novnc/ \
    --cert /root/self.pem \
    --auth-plugin=websockify.auth.BasicUIAuth \
    --auth-source=$PASS \
    6080 localhost:5901 \
'
