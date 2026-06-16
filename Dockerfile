FROM alpine:latest

# نصب ابزارهای مورد نیاز (autossh برای اتصال مجدد خودکار)
RUN apk add --no-cache openssh-client autossh sshpass bash

# ایجاد کاربر غیرمدیر برای امنیت
RUN adduser -D -s /bin/bash proxyuser

USER proxyuser
WORKDIR /home/proxyuser

# ساخت پوشه .ssh با دسترسی مناسب
RUN mkdir -p .ssh && chmod 700 .ssh

# تنظیمات SSH (مثلاً برای جلوگیری از قطعی اتصال)
RUN printf "Host *\n    ServerAliveInterval 60\n    ForwardAgent yes\n    AllowTcpForwarding yes\n" > .ssh/config

# ساختن اسکریپت ورودی (Entrypoint) در همان فایل
RUN printf '#!/bin/bash\n\
if [ -n "$SSH_PORT" ]; then\n\
    PORT_OPT="-p $SSH_PORT"\n\
else\n\
    PORT_OPT=""\n\
fi\n\
if [ -z "$SSH_PASSWORD" ]; then\n\
    exec autossh -M 0 $PORT_OPT -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -D 0.0.0.0:1080 -N "$SSH_USER@$SSH_HOST"\n\
else\n\
    exec sshpass -p "$SSH_PASSWORD" autossh -M 0 $PORT_OPT -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -D 0.0.0.0:1080 -N "$SSH_USER@$SSH_HOST"\n\
fi' > /home/proxyuser/entrypoint.sh

RUN chmod +x /home/proxyuser/entrypoint.sh

ENTRYPOINT ["/home/proxyuser/entrypoint.sh"]
