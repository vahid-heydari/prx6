FROM alpine:latest

# ========== مشخصات سرور SSH ==========
ENV SSH_HOST="7149e823-99ec-42a2-a02b-78fcc4467006.hsvc.ir"
ENV SSH_USER="tunnel_user"
ENV SSH_PORT="22"

# ========== کلید خصوصی خود را اینجا قرار دهید ==========
# (تمام خطوط کلید را بین دو علامت EOF قرار دهید)
RUN mkdir -p /home/proxyuser/.ssh && chmod 700 /home/proxyuser/.ssh && \
    cat > /home/proxyuser/.ssh/id_rsa << 'EOF'
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACBPfYx8Ld6ZTdL/JaWpSQXPqh2usBfm+kJL5x/PoRxZowAAAKC+wUyIvsFM
iAAAAAtzc2gtZWQyNTUxOQAAACBPfYx8Ld6ZTdL/JaWpSQXPqh2usBfm+kJL5x/PoRxZow
AAAECTcNTcVVmkP16u4H1pfXlyNNG0TNZbrSR0m7hiuk8rrU99jHwt3plN0v8lpalJBc+q
Ha6wF+b6QkvnH8+hHFmjAAAAFnlvdXJfZW1haWxAZXhhbXBsZS5jb20BAgMEBQYH
-----END OPENSSH PRIVATE KEY-----
EOF
RUN chmod 600 /home/proxyuser/.ssh/id_rsa && chown -R proxyuser:proxyuser /home/proxyuser/.ssh
# ========================================================

RUN apk add --no-cache openssh-client autossh bash

RUN adduser -D -s /bin/bash proxyuser

USER proxyuser
WORKDIR /home/proxyuser

# تنظیمات SSH کلاینت
RUN printf "Host *\n    ServerAliveInterval 60\n" > .ssh/config

# اسکریپت ورودی ساده (بدون نیاز به متغیر محیطی)
RUN printf '#!/bin/bash\n\
SOCKS_PORT="${PORT:-1080}"\n\
echo "Starting SOCKS5 proxy on 0.0.0.0:$SOCKS_PORT"\n\
\n\
if [ -n "$SSH_PORT" ]; then PORT_OPT="-p $SSH_PORT"; else PORT_OPT=""; fi\n\
\n\
exec autossh -M 0 $PORT_OPT -i .ssh/id_rsa -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -D "0.0.0.0:$SOCKS_PORT" -N "$SSH_USER@$SSH_HOST"\n\
' > /home/proxyuser/entry.sh

RUN chmod +x /home/proxyuser/entry.sh

EXPOSE 1080

ENTRYPOINT ["/home/proxyuser/entry.sh"]
