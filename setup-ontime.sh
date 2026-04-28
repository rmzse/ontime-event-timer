#!/usr/bin/env bash
#
# setup-ontime.sh — installera Docker + clona detta repo + starta Ontime
#
# Körs på en fräsch Ubuntu 22.04 eller 24.04 VPS (t.ex. Hetzner CX23).
# Logga in som root, klistra in följande:
#
#   curl -fsSL https://raw.githubusercontent.com/DITT-USERNAME/ontime-event-setup/main/setup-ontime.sh | bash
#
# (Byt DITT-USERNAME mot ditt GitHub-användarnamn.)
#
# Eller manuellt:
#   wget https://raw.githubusercontent.com/DITT-USERNAME/ontime-event-setup/main/setup-ontime.sh
#   chmod +x setup-ontime.sh
#   ./setup-ontime.sh

set -euo pipefail

REPO_URL="https://github.com/DITT-USERNAME/ontime-event-setup.git"
INSTALL_DIR="/opt/ontime-event-setup"

echo "==> Uppdaterar paketlistor"
apt-get update -y

echo "==> Installerar grundläggande verktyg"
apt-get install -y ca-certificates curl gnupg git

echo "==> Lägger till Dockers officiella GPG-nyckel"
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "==> Konfigurerar Dockers apt-repository"
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  > /etc/apt/sources.list.d/docker.list

echo "==> Installerar Docker Engine"
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "==> Klonar repo"
if [ -d "$INSTALL_DIR" ]; then
  echo "    $INSTALL_DIR finns redan, hoppar över klon"
else
  git clone "$REPO_URL" "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"

if [ ! -f .env ]; then
  echo ""
  echo "==> .env saknas. Kopierar från .env.example."
  cp .env.example .env
  echo ""
  echo "    !!  VIKTIGT  !!"
  echo "    Öppna $INSTALL_DIR/.env och fyll i CLOUDFLARE_TUNNEL_TOKEN."
  echo "    Hämta token från: Cloudflare Dashboard → Zero Trust → Networks → Tunnels"
  echo ""
  echo "    När du är klar, kör:"
  echo "      cd $INSTALL_DIR && docker compose up -d"
  echo ""
  exit 0
fi

echo "==> Startar Ontime + Cloudflare Tunnel"
docker compose up -d

echo ""
echo "==> Klart!"
echo "    Kontrollera status:  docker compose ps"
echo "    Se loggar:           docker compose logs -f"
echo "    Stoppa allt:         docker compose down"
