#!/usr/bin/env bash
# Lanzador único para AMBOS laboratorios (demo + examen).
# Funciona en Linux y macOS. En Windows usar lab.ps1.
#
#   ./lab.sh          construye + levanta ambos labs, muestra cómo conectarse
#   ./lab.sh down     detiene y elimina ambos labs
#
# Los puertos del host los elige Docker automáticamente (puerto libre al azar
# en 127.0.0.1), así nada choca con servicios que ya tengas corriendo. Este
# script solo lee de vuelta qué puertos eligió Docker y los muestra.
set -euo pipefail

cd "$(dirname "$0")"

OS="$(uname -s)"
# IP fija de cada target (definida en los docker-compose).
DEMO_IP=172.30.0.10
EXAM_IP=172.31.0.10
# En Linux el target se accede por su IP (como un host real escaneable). El FTP
# pasivo tiene que anunciar esa IP, así que la pasamos al contenedor.
if [ "$OS" = "Linux" ]; then
    export PASV_ADDRESS="$DEMO_IP"
fi

# Usa `docker compose` (v2); si no, cae a `docker-compose` (legacy).
compose() {
    if docker compose version >/dev/null 2>&1; then
        docker compose "$@"
    else
        docker-compose "$@"
    fi
}

if [ "${1:-}" = "down" ] || [ "${1:-}" = "stop" ]; then
    echo "==> Deteniendo ambos labs..."
    (cd demo && compose down)
    (cd exam && compose down)
    echo "Listo."
    exit 0
fi

# puerto del host para un puerto del contenedor: quita el prefijo "IP:" de `compose port`
port_of() { (cd "$1" && compose port lab "$2" 2>/dev/null | head -n1 | sed 's/.*://'); }

echo "==> Construyendo y levantando el lab DEMO..."
(cd demo && compose up -d --build)

echo "==> Construyendo y levantando el lab EXAMEN..."
(cd exam && compose up -d --build)

demo_web="$(port_of demo 80)"
demo_ftp="$(port_of demo 21)"
exam_web="$(port_of exam 5000)"

echo
echo "=================================================================="
echo "  Laboratorios ARRIBA"
echo "=================================================================="
echo
echo "Lab DEMO (recorrido en clase):"
echo "  Web   : http://127.0.0.1:${demo_web}"
echo "  FTP   : ftp 127.0.0.1 ${demo_ftp}      (usuario: anonymous, sin contraseña)"
echo "  (puertos de datos FTP pasivo: 21000-21010)"
echo
echo "Lab EXAMEN:"
echo "  Web   : http://127.0.0.1:${exam_web}"

if [ "$OS" = "Linux" ]; then
    echo
    echo "------------------------------------------------------------------"
    echo "Linux: cada target es un HOST con IP fija (escaneable con nmap)."
    echo "Todos los servicios viven en esa IP — usá esto para el recon con IA:"
    echo
    echo "  DEMO : ${DEMO_IP}   (FTP 21, HTTP 80, FTP pasivo 21000-21010)"
    echo "         nmap -sV ${DEMO_IP}     ftp ${DEMO_IP}     http://${DEMO_IP}/"
    echo "  EXAM : ${EXAM_IP}   (HTTP 5000)"
    echo "         nmap -sV ${EXAM_IP}     http://${EXAM_IP}:5000/"
    echo
    echo "(Los puertos en 127.0.0.1 de arriba siguen como alternativa.)"
fi

echo
echo "Para detener todo:  ./lab.sh down"
