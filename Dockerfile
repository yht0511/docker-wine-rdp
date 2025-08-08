FROM scottyhardy/docker-wine:latest

RUN apt update && apt install -y \
    mesa-utils \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    libgl1 \
    libglx0 \
    libglx-mesa0

RUN dpkg --add-architecture i386 && \
    apt update && \
    apt install -y \
    libgl1:i386 \
    libglx0:i386 \
    libglx-mesa0:i386

RUN apt install -y \
    mesa-vulkan-drivers \
    libvulkan1 \
    mesa-vulkan-drivers:i386 \
    libvulkan1:i386

RUN apt install -y \
    libdrm2 \
    libdrm2:i386 \
    libx11-6 \
    libx11-6:i386 \
    libxext6 \
    libxext6:i386 \
    libxrender1 \
    libxrender1:i386 \
    xvfb \
    x11vnc

RUN export DISPLAY=:99 && \
    Xvfb :99 -screen 0 1024x768x24 > /dev/null 2>&1 & \
    sleep 3 && \
    export WINEDEBUG=-all && \
    wineboot --init && \
    winetricks --unattended d3dx9 vcrun2019 corefonts && \
    pkill Xvfb || true

# 创建 Wine 配置脚本，在运行时执行
RUN echo '#!/bin/bash' > /usr/local/bin/wine-config.sh && \
    echo 'echo "Configuring Wine..."' >> /usr/local/bin/wine-config.sh && \
    echo 'wine reg add "HKCU\\Software\\Wine\\Direct3D" /v VideoMemorySize /t REG_SZ /d 512 /f' >> /usr/local/bin/wine-config.sh && \
    echo 'wine reg add "HKCU\\Software\\Wine\\X11 Driver" /v UseXVidMode /t REG_SZ /d N /f' >> /usr/local/bin/wine-config.sh && \
    echo 'wine reg add "HKCU\\Software\\Wine\\X11 Driver" /v UseXRandR /t REG_SZ /d N /f' >> /usr/local/bin/wine-config.sh && \
    chmod +x /usr/local/bin/wine-config.sh

# 创建启动包装脚本
RUN echo '#!/bin/bash' > /usr/local/bin/startup-wrapper.sh && \
    echo '# 启动原始入口点（后台运行）' >> /usr/local/bin/startup-wrapper.sh && \
    echo '/usr/bin/entrypoint "$@" &' >> /usr/local/bin/startup-wrapper.sh && \
    echo 'ENTRYPOINT_PID=$!' >> /usr/local/bin/startup-wrapper.sh && \
    echo '# 等待系统启动和用户创建' >> /usr/local/bin/startup-wrapper.sh && \
    echo 'sleep 5' >> /usr/local/bin/startup-wrapper.sh && \
    echo '# 检查 wineuser 是否存在' >> /usr/local/bin/startup-wrapper.sh && \
    echo 'if id "wineuser" &>/dev/null; then' >> /usr/local/bin/startup-wrapper.sh && \
    echo '    echo "Configuring Wine for wineuser..."' >> /usr/local/bin/startup-wrapper.sh && \
    echo '    su - wineuser -c "export DISPLAY=:10.0 && /usr/local/bin/wine-config.sh" || true' >> /usr/local/bin/startup-wrapper.sh && \
    echo 'else' >> /usr/local/bin/startup-wrapper.sh && \
    echo '    echo "wineuser not found, skipping Wine configuration"' >> /usr/local/bin/startup-wrapper.sh && \
    echo 'fi' >> /usr/local/bin/startup-wrapper.sh && \
    echo '# 等待入口点进程' >> /usr/local/bin/startup-wrapper.sh && \
    echo 'wait $ENTRYPOINT_PID' >> /usr/local/bin/startup-wrapper.sh && \
    chmod +x /usr/local/bin/startup-wrapper.sh

RUN apt install -y \
    fonts-wqy-zenhei \
    fonts-wqy-microhei \
    fonts-noto-cjk \
    fonts-noto-cjk-extra \
    fonts-arphic-ukai \
    fonts-arphic-uming \
    xfonts-intl-chinese \
    language-pack-zh-hans

ENV LANG=zh_CN.UTF-8
ENV LANGUAGE=zh_CN:zh
ENV LC_ALL=zh_CN.UTF-8

RUN apt install -y \
    fcitx \
    fcitx-pinyin \
    fcitx-config-gtk

RUN /root/download_gecko_and_mono.sh  "$(wine --version | sed -E 's/^wine-//')"

ENV DISPLAY=:10.0
ENV WINE_NO_GAMMA_CORRECTION=1
ENV LIBGL_ALWAYS_INDIRECT=1
ENV MESA_GL_VERSION_OVERRIDE=4.5
ENV RDP_SERVER=yes
ENV TZ=Asia/Shanghai

ENTRYPOINT ["/usr/local/bin/startup-wrapper.sh"]
