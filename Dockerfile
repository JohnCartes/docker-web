FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Jakarta
ENV USER=root

RUN apt-get update && apt-get install -y --no-install-recommends \
    xfce4 \
    xfce4-goodies \
    tigervnc-standalone-server \
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
    && rm -rf /var/lib/apt/lists/*

RUN touch /root/.Xauthority
RUN mkdir -p /root/.vnc

# Perbaikan xstartup script
RUN printf '#!/bin/bash\n\
export USER=root\n\
startxfce4\n' > /root/.vnc/xstartup

RUN chmod +x /root/.vnc/xstartup

EXPOSE 5901
EXPOSE 6080

CMD bash -c '\
vncserver :1 \
    -localhost no \
    -SecurityTypes None \
    --I-KNOW-THIS-IS-INSECURE \
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
