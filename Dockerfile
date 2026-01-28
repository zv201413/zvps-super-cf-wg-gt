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
RUN mkdir -p /run/sshd /etc/supervisor/conf.d && \
    sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config && \
    sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config && \
    ssh-keygen -A

# 4. 用户设置 (保持不变)
RUN useradd -m -s /bin/bash zv && \
    echo "zv:105106" | chpasswd && \
    echo "root:105106" | chpasswd && \
    echo "zv ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 5. 【修改点】不要直接用软链接指向硬盘，先在镜像里放一个“保底”配置
# 这样即使硬盘没挂载成功，SSH 也能起来，方便你进去修
COPY supervisord.conf /etc/supervisord.conf

# 6. 设置工作目录
WORKDIR /home/zv

# 7. 【修改点】启动脚本
# 检查硬盘里有没有配置，有就用硬盘的，没有就用镜像自带的
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]
