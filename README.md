# Ontime Event Setup

Self-hosted [Ontime](https://www.getontime.no/) på Hetzner Cloud, exponerad via Cloudflare Tunnel. Designat för "spin up under event, riv ner efteråt"-mönstret för att minimera kostnad.

## Vad det här ger dig

- Ontime som körs i Docker på en billig VPS (Hetzner CX23 ~€3.99/mån)
- Cloudflare Tunnel som exponerar Ontime på din egen domän, utan port-forwarding eller manuell SSL
- En setup som tar ~15 minuter att starta från noll och ~1 minut att riva ner
- Inga hemligheter i versionshanteringen — alla credentials i `.env` på servern

## Förutsättningar

1. **Hetzner Cloud-konto** — [hetzner.com/cloud](https://www.hetzner.com/cloud)
2. **Domännamn** — vilken registrar som helst
3. **Cloudflare-konto** med din domän tillagd — [cloudflare.com](https://www.cloudflare.com/)
4. **GitHub-konto** för att klona detta repo

## Engångs-setup (gör en gång, återanvänd för alla events)

### 1. Forka eller klona detta repo

```bash
# Om du forkat på GitHub:
git clone https://github.com/DITT-USERNAME/ontime-event-setup.git
```

I `setup-ontime.sh`, ändra `REPO_URL` till din egen GitHub-URL.

### 2. Skapa Cloudflare Tunnel

1. Gå till Cloudflare Dashboard → **Zero Trust** → **Networks** → **Tunnels**
2. Klicka **Create a tunnel** → välj **Cloudflared**
3. Namnge den (t.ex. `ontime-tunnel`)
4. På "Install connector"-sidan, välj **Docker** och **kopiera token-strängen** (lång base64-sträng efter `--token`). Spara den temporärt — du klistrar in den i `.env` på servern senare.
5. Gå vidare till **Public Hostname**:
   - Subdomain: `timer` (eller vad du vill)
   - Domain: din domän
   - Service Type: `HTTP`
   - URL: `ontime:4001`
6. Spara

Tunnelen finns nu konfigurerad i Cloudflares dashboard. Routing-reglerna lever där, inte i koden, vilket gör att du kan ändra dem utan att starta om servern.

## Per-event-setup (varje gång du behöver Ontime)

### 1. Skapa VPS hos Hetzner

- **Image:** Ubuntu 24.04
- **Type:** CX23 (eller motsvarande, ~2GB RAM räcker)
- **Location:** Tyskland eller Finland (billigast)
- **SSH-key:** lägg till din publika nyckel
- **Name:** t.ex. `ontime-2026-05`

### 2. Logga in och kör setup

```bash
ssh root@<server-ip>
curl -fsSL https://raw.githubusercontent.com/DITT-USERNAME/ontime-event-setup/main/setup-ontime.sh | bash
```

Skriptet installerar Docker, klonar repo:t till `/opt/ontime-event-setup` och stannar för att låta dig fylla i `.env`.

### 3. Fyll i `.env`

```bash
cd /opt/ontime-event-setup
nano .env
```

Klistra in din Cloudflare Tunnel-token. Spara (Ctrl+O, Enter, Ctrl+X).

### 4. Starta Ontime

```bash
docker compose up -d
```

Vänta ~30 sekunder. Gå sedan till `https://timer.dindomän.se` (eller den hostname du valt). Ontime ska svara.

### 5. Återställ ev. tidigare event-data (valfritt)

Om du har en `.json`-projektfil från ett tidigare event:

```bash
scp ditt-projekt.json root@<server-ip>:/opt/ontime-event-setup/ontime-data/projects/
```

Sen i Ontime: Project Manager → ladda projektet.

## Efter eventet

### 1. Säkerhetskopiera projektfilen

```bash
scp root@<server-ip>:/opt/ontime-event-setup/ontime-data/projects/ditt-projekt.json ~/event-arkiv/
```

Spara `.json`-filen någonstans säkert (lokal disk, krypterad backup). **Lägg den inte i detta repo** — den innehåller kund-data.

### 2. Riv ner servern

I Hetzner Cloud Console: **Delete server**. Färdigt. Inga ytterligare avgifter.

Inget att stänga av i Cloudflare — tunnel-konfigurationen finns kvar i dashbord:en, redo att användas av nästa server som har samma token.

## Kostnadsbild

Antagande: 4 events per år, 1 vecka aktiv server per event.

| Post | Kostnad |
|---|---|
| Hetzner CX23 × 4 veckor | ~€4 |
| Cloudflare Tunnel | €0 (gratis-tier) |
| Domän | typ €10/år (inte verktygets fel) |
| **Totalt verktygskostnad** | **~€4–5/år** |

## Säkerhet

Detta repo är säkert att ha publikt **så länge du:**

1. Aldrig committar `.env` (gitignored som default)
2. Aldrig committar credentials.json eller andra Cloudflare-filer (gitignored)
3. Aldrig committar Ontime-projekt-filer med kund-data (gitignored)
4. Aktiverar GitHub **Push Protection** på repo:t (Settings → Code security → Push protection)

Allt över står i `.gitignore`.

## Felsökning

**Tunnel ansluter inte:**

```bash
docker compose logs cloudflared
```

Vanliga orsaker: fel token i `.env`, eller att tunnel-konfigurationen i Cloudflare-dashbord:en pekar på fel hostname.

**Ontime svarar inte på domänen:**

Kontrollera att Public Hostname-konfigurationen i Cloudflare pekar på `ontime:4001` (Docker-service-namn, inte localhost).

**Vill se Ontime utan tunnel för felsökning:**

Lägg tillfälligt till portmappning i `docker-compose.yml`:

```yaml
ontime:
  ports:
    - "4001:4001"
```

Sen `http://<server-ip>:4001`. Glöm inte ta bort portmappningen efteråt.

## Licens

MIT — gör vad du vill med setup-skripten. Ontime själv har sin egen licens, se [Ontimes GitHub](https://github.com/cpvalente/ontime).
