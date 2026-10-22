#!/bin/bash
# Launch all lab services in one container. FTP (python) in background, Apache in foreground.
set -e

# FTP vulnerable: recon anónimo + backdoor vsftpd 2.3.4. PASV_ADDRESS (en Linux
# es la IP del contenedor) lo lee el server para anunciar el modo pasivo.
python3 /usr/local/bin/ftpd.py &

# Apache necesita esto cuando se corre sin el init script
source /etc/apache2/envvars
mkdir -p /var/run/apache2
exec /usr/sbin/apache2 -D FOREGROUND
