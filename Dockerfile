# استفاده از image رسمی Ubuntu به عنوان پایه
FROM ubuntu:latest

# به‌روزرسانی و نصب OpenSSH Server
RUN apt-get update && apt-get install -y openssh-server

# ایجاد پوشه مورد نیاز SSH
RUN mkdir /var/run/sshd

# تنظیم رمز عبور برای کاربر root (رمز را به دلخواه تغییر دهید)
RUN echo "root:your_strong_password" | chpasswd

# فعال کردن لاگین با رمز عبور و اجازه به root برای لاگین
RUN echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config && \
    echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config

# پورت ۲۲ را در معرض دید قرار دهید
EXPOSE 22

# اجرای سرور SSH در حالت foreground
CMD ["/usr/sbin/sshd", "-D"]
