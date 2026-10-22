# Training labs — AI-assisted hacking course (final class)

> **Authorized training use only.** Both labs are vulnerable by design. They
> bind only to `127.0.0.1`. Never expose them to an untrusted network.

Two single-container CTF targets:

| Lab | Folder | Purpose | Chain |
|-----|--------|---------|-------|
| **Demo** | `demo/` | Guided walkthrough in class | FTP recon → SQLi login bypass → command injection (RCE) → privesc (SUID PATH hijack **or** `sudo find`) + LFI side-path + **vsftpd 2.3.4 backdoor** (instant root) |
| **Exam** | `exam/` | Graded practice / test | HTTP recon → Jinja2 **SSTI** (RCE) → privesc via `cap_setuid` on a python copy |

The two labs use different stacks and different vulnerability classes on
purpose, so the exam can't be solved by copying the demo.

## Requirements
- Docker Desktop (Windows/macOS) or Docker Engine + compose plugin (Linux).

## Launch both labs

**Linux / macOS:**
```bash
./lab.sh          # build + start both, prints how to connect
./lab.sh down     # stop + remove both
```

**Windows (PowerShell):**
```powershell
.\lab.ps1         # build + start both, prints how to connect
.\lab.ps1 down    # stop + remove both
```

### Ports are automatic
Each service is published to a **random free host port on `127.0.0.1`**, so it
never collides with anything you already run. The launcher reads back the ports
Docker chose and prints a connection table like:

```
DEMO lab (class walkthrough):
  Web   : http://127.0.0.1:49173
  FTP   : ftp 127.0.0.1 49174      (user: anonymous, no password)
EXAM lab:
  Web   : http://127.0.0.1:49175
```

On **Linux** each target is also a real host at a **fixed container IP** with
every service on it — ideal for AI-driven recon (`nmap -sV <ip>`, banner/version
→ CVE). The launcher sets passive FTP to advertise that IP so it works end to end:

| Lab | IP | Services |
|-----|----|----|
| Demo | `172.30.0.10` | FTP 21 (+passive 21000-21010), HTTP 80 |
| Exam | `172.31.0.10` | HTTP 5000 |

The `127.0.0.1` published ports stay available as a fallback. Windows/macOS use
the `127.0.0.1` ports (Docker Desktop can't route to container IPs).

### One lab at a time
```bash
cd demo && docker compose up -d --build     # just the demo
docker compose port lab 80                   # see its web port
docker compose down
```

## Flags
Each lab has a `user` flag (after foothold) and a `root` flag (after privesc).
Intended solutions for instructors are in each lab's own `README.md`.
