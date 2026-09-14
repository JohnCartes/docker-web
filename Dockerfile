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

EXPOSE 5901
EXPOSE 6080

CMD bash -c '\
# Membaca variabel dari Railway dan membuang HAPUS SEMUA karakter KECUALI huruf dan angka
PASS=$(echo "${VNC_PASSWORD}" | grep -o "[a-zA-Z0-9]*" | tr -d "\n") && \
\
# Jika ternyata kosong, gunakan password cadangan
if [ -z "$PASS" ]; then PASS="AcakAman99"; fi && \
\
echo "=== CEK VARIABEL RAILWAY ===" && \
echo "Panjang karakter password yang terbaca adalah: ${#PASS} huruf." && \
echo "Password yang akan digunakan adalah murni: $PASS" && \
echo "============================" && \
\
mkdir -p /root/.vnc && \
# Buat password VNC
printf "%s\n%s\n" "$PASS" "$PASS" | vncpasswd -f > /root/.vnc/passwd && \
chmod 600 /root/.vnc/passwd && \
\
vncserver :1 \
    -localhost no \
    -SecurityTypes VncAuth \
    -PasswordFile /root/.vnc/passwd \
    -geometry 1024x768 \
    -depth 24 \
    && \
openssl req \
    -new \
    -subj "/C=ID" \
    -x509 \
    -days 365 \
    -nodes \
    -out /root/self.pem \
    -keyout /root/self.pem \
    && \
websockify \
    --web /usr/share/novnc/ \
    6080 \
    localhost:5901 \
    --cert /root/self.pem \
'
