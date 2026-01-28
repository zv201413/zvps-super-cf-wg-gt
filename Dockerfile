FROM ubuntu:22.04



# 1. 禁用交互模式并安装基础依赖

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \

    openssh-server supervisor curl wget sudo ca-certificates \

    && rm -rf /var/lib/apt/lists/*



# 2. 预装 Cloudflared (官方推荐安装方式)

RUN curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb \

    && dpkg -i cloudflared.deb \

    && rm cloudflared.deb



# 3. 极速修复 SSH 权限与目录

RUN mkdir -p /run/sshd && \

    sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config && \

    sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config && \

    ssh-keygen -A



# 4. 用户权限固化：创建 zv 用户、设置密码、赋予免密 sudo

RUN useradd -m -s /bin/bash zv && \

    echo "zv:105106" | chpasswd && \

    echo "root:105106" | chpasswd && \

    echo "zv ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers



# 5. 核心：建立配置文件软链接

# 就算你以后没带 -c 参数启动，supervisorctl 也会默认去硬盘找配置

RUN ln -sf /home/zv/boot/supervisord.conf /etc/supervisord.conf



# 6. 设置工作目录

WORKDIR /home/zv



# 7. 启动指令：使用 nodaemon 模式作为容器主进程

# 只要 /home/zv/boot/supervisord.conf 存在，它就会接管一切

CMD ["/usr/bin/supervisord", "-n", "-c", "/home/zv/boot/supervisord.conf"]
