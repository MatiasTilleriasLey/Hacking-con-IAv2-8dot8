# Laboratorios de entrenamiento — Curso de Hacking con IA (clase final)

> **Solo para uso de entrenamiento autorizado.** Ambos laboratorios son
> vulnerables a propósito. Escuchan únicamente en `127.0.0.1`. Nunca los
> expongas a una red no confiable.

Dos targets CTF de un solo contenedor:

| Lab | Carpeta | Propósito | Cadena |
|-----|---------|-----------|--------|
| **Demo** | `demo/` | Recorrido guiado en clase | recon FTP → bypass de login por SQLi → command injection (RCE) → privesc (SUID PATH hijack **o** `sudo find`) + LFI como ruta lateral + **backdoor de vsftpd 2.3.4** (root instantáneo) |
| **Examen** | `exam/` | Práctica evaluada / prueba | recon HTTP → **SSTI** en Jinja2 (RCE) → privesc por `cap_setuid` en una copia de python |

Los dos laboratorios usan stacks y clases de vulnerabilidad distintas a propósito,
para que el examen no se resuelva copiando el demo.

## Requisitos
- Docker Desktop (Windows/macOS) o Docker Engine + plugin compose (Linux).

## Levantar ambos laboratorios

**Linux / macOS:**
```bash
./lab.sh          # construye + levanta ambos, imprime cómo conectarse
./lab.sh down     # detiene + elimina ambos
```

**Windows (PowerShell):**
```powershell
.\lab.ps1         # construye + levanta ambos, imprime cómo conectarse
.\lab.ps1 down    # detiene + elimina ambos
```

### Los puertos son automáticos
Cada servicio se publica en un **puerto host libre al azar en `127.0.0.1`**, así
nunca choca con nada que ya tengas corriendo. El launcher lee los puertos que
eligió Docker e imprime una tabla de conexión como esta:

```
Lab DEMO (recorrido en clase):
  Web   : http://127.0.0.1:49173
  FTP   : ftp 127.0.0.1 49174      (usuario: anonymous, sin contraseña)
Lab EXAMEN:
  Web   : http://127.0.0.1:49175
```

En **Linux** cada target es además un host real con una **IP fija** y todos sus
servicios en ella — ideal para recon asistido por IA (`nmap -sV <ip>`,
banner/versión → CVE). El launcher configura el FTP pasivo para que anuncie esa
IP y funcione de punta a punta:

| Lab | IP | Servicios |
|-----|----|-----------|
| Demo | `172.30.0.10` | FTP 21 (+pasivo 21000-21010), HTTP 80 |
| Examen | `172.31.0.10` | HTTP 5000 |

Los puertos publicados en `127.0.0.1` siguen disponibles como alternativa.
Windows/macOS usan los puertos de `127.0.0.1` (Docker Desktop no puede rutear a
las IP de los contenedores).

### Un laboratorio a la vez
```bash
cd demo && docker compose up -d --build     # solo el demo
docker compose port lab 80                   # ver su puerto web
docker compose down
```

## Flags
Cada laboratorio tiene una flag de `user` (tras el foothold) y una de `root`
(tras la escalada). Las soluciones previstas para el instructor están en el
`README.md` de cada laboratorio.
