FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Jakarta
ENV USER=root

# Penanda versi Dockerfile
ENV DOCKERFILE_VERSION=2026-09-14-VNC-FIX-02

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

# Xauthority dan VNC directory
RUN touch /root/.Xauthority
RUN mkdir -p /root/.vnc

# XFCE startup
RUN printf '#!/bin/bash\n\
export USER=root\n\
startxfce4\n' > /root/.vnc/xstartup

RUN chmod +x /root/.vnc/xstartup

EXPOSE 5901
EXPOSE 6080

CMD ["/bin/bash", "-c", "\
echo ''; \
echo '========================================'; \
echo '       RAILWAY VNC CONTAINER'; \
echo '========================================'; \
echo \"Dockerfile version : ${DOCKERFILE_VERSION}\"; \
echo \"Container hostname : $(hostname)\"; \
echo '========================================'; \
echo ''; \
\
RAW_PASSWORD=\"${VNC_PASSWORD:-}\"; \
\
PASS=\"$(printf '%s' \"$RAW_PASSWORD\" | tr -d '\\r\\n')\"; \
\
if [ -z \"$PASS\" ]; then \
    echo '[WARN] VNC_PASSWORD kosong.'; \
    echo '[WARN] Menggunakan password fallback.'; \
    PASS='AcakAman99'; \
    USING_FALLBACK='YES'; \
else \
    USING_FALLBACK='NO'; \
fi; \
\
PASS_LENGTH=\"${#PASS}\"; \
\
echo '=== CEK VARIABEL RAILWAY ==='; \
echo 'VNC_PASSWORD tersedia : YES'; \
echo \"Password fallback     : $USING_FALLBACK\"; \
echo \"Panjang password      : $PASS_LENGTH\"; \
echo '============================'; \
\
if [ \"$PASS_LENGTH\" -lt 8 ]; then \
    echo ''; \
    echo '[ERROR] Password VNC kurang dari 8 karakter.'; \
    echo \"[ERROR] Panjang yang terbaca: $PASS_LENGTH\"; \
    echo ''; \
    exit 1; \
fi; \
\
PASSWORD_FINGERPRINT=\"$(printf '%s' \"$PASS\" | sha256sum | awk '{print $1}' | cut -c1-12)\"; \
\
echo \"Password fingerprint : $PASSWORD_FINGERPRINT\"; \
echo ''; \
\
mkdir -p /root/.vnc; \
rm -f /root/.vnc/passwd; \
\
printf '%s\\n' \"$PASS\" | vncpasswd -f > /root/.vnc/passwd; \
chmod 600 /root/.vnc/passwd; \
\
echo '[OK] VNC password file dibuat.'; \
echo ''; \
\
vncserver -kill :1 >/dev/null 2>&1 || true; \
\
echo '[INFO] Starting TigerVNC...'; \
\
vncserver :1 \
    -localhost no \
    -SecurityTypes VncAuth \
    -PasswordFile /root/.vnc/passwd \
    -geometry 1024x768 \
    -depth 24; \
\
if [ $? -ne 0 ]; then \
    echo ''; \
    echo '[ERROR] Gagal menjalankan TigerVNC.'; \
    exit 1; \
fi; \
\
echo '[OK] TigerVNC started.'; \
echo ''; \
\
echo '[INFO] Generating SSL certificate...'; \
\
rm -f /root/self.pem; \
\
openssl req \
    -new \
    -subj '/C=ID' \
    -x509 \
    -days 365 \
    -nodes \
    -out /root/self.pem \
    -keyout /root/self.pem \
    >/dev/null 2>&1; \
\
if [ $? -ne 0 ]; then \
    echo ''; \
    echo '[ERROR] Gagal membuat SSL certificate.'; \
    exit 1; \
fi; \
\
echo '[OK] SSL certificate generated.'; \
echo ''; \
\
echo '========================================'; \
echo '             VNC READY'; \
echo '========================================'; \
echo 'VNC port    : 5901'; \
echo 'noVNC port  : 6080'; \
echo 'Display     : :1'; \
echo 'Geometry    : 1024x768'; \
echo \"Password    : $PASS_LENGTH characters\"; \
echo \"Fingerprint : $PASSWORD_FINGERPRINT\"; \
echo '========================================'; \
echo ''; \
echo '[INFO] Starting noVNC...'; \
\
exec websockify \
    --web /usr/share/novnc/ \
    6080 \
    localhost:5901 \
    --cert /root/self.pem \
"]
