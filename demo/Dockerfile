# Vulnerable training lab - single container, multi-service CTF
# Chain: anonymous FTP recon -> web SQLi login bypass -> command injection (RCE as www-data)
#        -> SUID PATH-hijack privesc -> root -> /root/flag.txt
# Extra paths (for class demo): LFI in the diagnostics page, an alternate privesc
#        via `sudo find` (GTFOBins) besides the SUID PATH hijack, and the classic
#        vsftpd 2.3.4 backdoor (USER with ":)" -> root shell on tcp/6200).
#
# FOR AUTHORIZED TRAINING / CTF USE ONLY. Never expose to an untrusted network.
FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        python3 python3-pyftpdlib apache2 php libapache2-mod-php php-sqlite3 sqlite3 gcc libc6-dev iputils-ping sudo ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# --- Web app (SQLi login -> command injection -> LFI) ---
COPY web/index.php web/login.php web/logout.php web/style.css /var/www/html/
COPY web/pages/ /var/www/html/pages/
RUN rm -f /var/www/html/index.html

# --- App database (SQLi target), kept OUT of the web root so it can't be downloaded ---
COPY web/seed.sql /tmp/seed.sql
RUN sqlite3 /var/www/app.db < /tmp/seed.sql \
    && rm -f /tmp/seed.sql \
    && chown www-data:www-data /var/www/app.db \
    && chmod 644 /var/www/app.db

# --- FTP: anonymous recon content + vulnerable server (vsftpd 2.3.4 backdoor) ---
COPY ftp/notes.txt /srv/ftp/notes.txt
COPY config/ftpd.py /usr/local/bin/ftpd.py
RUN chmod +x /usr/local/bin/ftpd.py \
    && chmod 555 /srv/ftp \
    && chmod 444 /srv/ftp/notes.txt

# --- SUID privesc binary (PATH hijack: calls `tar` without absolute path) ---
COPY privesc/backup.c /root/backup.c
RUN gcc -o /usr/local/bin/backup /root/backup.c \
    && chown root:root /usr/local/bin/backup \
    && chmod 4755 /usr/local/bin/backup \
    && rm -f /root/backup.c

# --- Alternate privesc (VULNERABLE BY DESIGN): www-data may run `find` as root
#     with no password -> GTFOBins shell: sudo find . -exec /bin/sh \; -quit ---
RUN echo 'www-data ALL=(root) NOPASSWD: /usr/bin/find' > /etc/sudoers.d/www-data \
    && chmod 440 /etc/sudoers.d/www-data

# --- Flags ---
COPY flags/user.txt /var/www/user.txt
COPY flags/root.txt /root/flag.txt
RUN chown www-data:www-data /var/www/user.txt && chmod 644 /var/www/user.txt \
    && chown root:root /root/flag.txt && chmod 600 /root/flag.txt

COPY config/start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 21 80 21000-21010 6200
CMD ["/start.sh"]
