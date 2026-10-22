# Vulnerable training lab - EXAM target, single container.
# Chain: HTTP recon (hint in homepage source) -> Jinja2 SSTI -> RCE as `app`
#        -> privesc via cap_setuid on a python copy -> root -> /root/flag.txt
#
# FOR AUTHORIZED TRAINING / CTF USE ONLY. Never expose to an untrusted network.
FROM python:3.12-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends libcap2-bin \
    && rm -rf /var/lib/apt/lists/*
RUN pip install --no-cache-dir flask==3.0.3

# Low-privilege service account the web app runs as.
RUN useradd -m -s /bin/bash app

# --- Privesc (VULNERABLE BY DESIGN): a python copy carries cap_setuid, so any
#     user can escalate: pythonpriv -c 'import os;os.setuid(0);os.execl("/bin/bash","bash","-p")'
RUN cp "$(readlink -f "$(command -v python3)")" /usr/local/bin/pythonpriv \
    && setcap cap_setuid+ep /usr/local/bin/pythonpriv

# --- Web app (SSTI) ---
COPY app/ /app/
WORKDIR /app

# --- User flag + privesc recon hint (readable by the app user after foothold) ---
COPY flags/user.txt /home/app/user.txt
COPY notes.txt /home/app/notes.txt
RUN chown app:app /home/app/user.txt /home/app/notes.txt \
    && chmod 644 /home/app/user.txt /home/app/notes.txt

# --- Root flag ---
COPY flags/root.txt /root/flag.txt
RUN chown root:root /root/flag.txt && chmod 600 /root/flag.txt

USER app
EXPOSE 5000
CMD ["python", "app.py"]
