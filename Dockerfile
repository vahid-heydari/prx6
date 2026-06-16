FROM alpine:latest

# ========== مشخصات سرور SSH خود را اینجا وارد کنید ==========
ENV SSH_HOST="7149e823-99ec-42a2-a02b-78fcc4467006.hsvc.ir"
ENV SSH_USER="tunnel_user"
ENV SSH_PASSWORD="YourStrongPassword123"
ENV SSH_PORT="22"
# ============================================================

RUN apk add --no-cache openssh-client autossh sshpass bash

RUN adduser -D -s /bin/bash proxyuser

USER proxyuser
WORKDIR /home/proxyuser

RUN mkdir -p .ssh && chmod 700 .ssh
RUN printf "Host *\n    ServerAliveInterval 60\n    AllowTcpForwarding yes\n" > .ssh/config

# اسکریپت ورودی هوشمند که پورت اختصاصی سرویس‌دهنده را تشخیص می‌دهد
RUN printf '#!/bin/bash\n\
# اگر سرویس‌دهنده پورتی داد (مثل Render/Heroku) از همان استفاده کن، وگرنه برو روی 1080\n\
SOCKS_PORT="${PORT:-1080}"\n\
echo "Starting SOCKS5 proxy on 0.0.0.0:$SOCKS_PORT"\n\
\n\
if [ -n "$SSH_PORT" ]; then PORT_OPT="-p $SSH_PORT"; else PORT_OPT=""; fi\n\
\n\
if [ -z "$SSH_PASSWORD" ]; then\n\
    exec autossh -M 0 $PORT_OPT -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -D "0.0.0.0:$SOCKS_PORT" -N "$SSH_USER@$SSH_HOST"\n\
else\n\
    exec sshpass -p "$SSH_PASSWORD" autossh -M 0 $PORT_OPT -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -D "0.0.0.0:$SOCKS_PORT" -N "$SSH_USER@$SSH_HOST"\n\
fi' > /home/proxyuser/entry.sh

RUN chmod +x /home/proxyuser/entry.sh

# پورت را برای سرویس‌دهنده اعلام می‌کنیم (اما سرویس‌دهنده معمولاً آن را بازنویسی می‌کند)
EXPOSE 1080

ENTRYPOINT ["/home/proxyuser/entry.sh"]
