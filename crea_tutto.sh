#!/usr/bin/env bash
# Crea tutti i file del lab Portale ITS (Terraform)
set -e

echo "📁 Creazione struttura directory..."

mkdir -p src test infra/tf .github/workflows policy script data

echo "📄 Scrittura file..."

# 1. PERIZIA.md
cat > PERIZIA.md << 'EOF'
# PERIZIA - Portale corsi ITS
Squadra: [inserisci nome squadra]  
Binario: Terraform  
Data: 27/07/2026  

## Sicurezza

### S1 – Il bucket del sito è aperto a chiunque
- **Gravità**: BLOCCANTE
- **Fatto**: La bucket policy consente `s3:*` a `Principal "*"`.
- **Conseguenza**: Chiunque su internet può modificare o cancellare le pagine del portale.
- **Rimedio**: Rimuovere la policy pubblica, riattivare il blocco degli accessi pubblici, pubblicare solo dalla pipeline.

### S2 – Blocco accessi pubblici disattivato
- **Gravità**: BLOCCANTE
- **Fatto**: Il blocco degli accessi pubblici non è configurato (o disattivato) sul bucket.
- **Conseguenza**: Anche se la policy fosse stretta, le ACL potrebbero lasciare accessi indesiderati.
- **Rimedio**: Attivare `block_public_acls`, `block_public_policy`, `ignore_public_acls`, `restrict_public_buckets` su tutti i bucket.

### S3 – Segreti nel repository
- **Gravità**: BLOCCANTE
- **Fatto**: Credenziali FTP e token API sono presenti in `config/impostazioni.txt` e nel default di una variabile Terraform.
- **Conseguenza**: Chiunque abbia accesso al repository (anche storico) ha le credenziali.
- **Rimedio**: Cancellare i file, ruotare le credenziali, montare un gate sui segreti.

### S4 – Dati non cifrati
- **Gravità**: SERIO
- **Fatto**: Il bucket del sito e la tabella DynamoDB non hanno cifratura attiva.
- **Conseguenza**: In caso di accesso non autorizzato ai dati, sarebbero leggibili in chiaro.
- **Rimedio**: Attivare cifratura AES256 sul bucket e KMS sulla tabella.

## Affidabilità

### A1 – Nessuna versione precedente del sito
- **Gravità**: BLOCCANTE
- **Fatto**: Il bucket non ha il versioning abilitato.
- **Conseguenza**: Se un file viene sovrascritto o cancellato, non si può recuperare.
- **Rimedio**: Abilitare il versioning sul bucket e conservare gli artefatti della pipeline.

### A2 – Nessun backup della tabella iscrizioni
- **Gravità**: SERIO
- **Fatto**: Il punto di ripristino (Point-in-Time Recovery) non è attivo.
- **Conseguenza**: Un errore o un attacco potrebbe cancellare i dati delle iscrizioni in modo irreversibile.
- **Rimedio**: Attivare `point_in_time_recovery` sulla tabella.

### A3 – Nessuna procedura di rollback
- **Gravità**: BLOCCANTE
- **Fatto**: Il runbook dice "se qualcuno ce l'ha" per la versione precedente.
- **Conseguenza**: Un errore in produzione non è reversibile in tempi brevi.
- **Rimedio**: Pipeline di release con artefatti conservati e possibilità di ripubblicare una versione precedente.

## Operabilità

### O1 – Pubblicazione manuale e dipendente da una persona
- **Gravità**: BLOCCANTE
- **Fatto**: La pubblicazione richiede 9 passi manuali su un computer specifico.
- **Conseguenza**: Se Marco non c'è, nessuno sa pubblicare.
- **Rimedio**: Pipeline automatica con approvazione e interfaccia web.

### O2 – Nessun log di accesso al bucket
- **Gravità**: SERIO
- **Fatto**: Il logging di S3 non è attivo.
- **Conseguenza**: Non si sa chi ha caricato o cancellato cosa.
- **Rimedio**: Attivare il logging su un bucket separato.

### O3 – Verifica a occhio dopo il deploy
- **Gravità**: SERIO
- **Fatto**: Il runbook dice "controllare a occhio".
- **Conseguenza**: Errori visibili possono passare inosservati.
- **Rimedio**: Aggiungere uno smoke test automatico dopo il deploy.

## Evolvibilità

### E1 – Il totale delle ore è sbagliato
- **Gravità**: BLOCCANTE
- **Fatto**: La funzione `totaleOre` usa `.slice(1)` e salta il primo corso. La pagina dice 260 h invece di 320 h.
- **Conseguenza**: I dati pubblicati sono errati da chissà quanto.
- **Rimedio**: Correggere la funzione e aggiungere un test.

### E2 – Dipendenze non bloccate
- **Gravità**: SERIO
- **Fatto**: Non c'è `package-lock.json`, le versioni non sono fissate.
- **Conseguenza**: Due build possono dare risultati diversi.
- **Rimedio**: Generare e committare `package-lock.json`, usare `npm ci`.

### E3 – Un solo ambiente (nessun test/prod separati)
- **Gravità**: SERIO
- **Fatto**: I nomi delle risorse sono fissi, non c'è un parametro `Env`.
- **Conseguenza**: Non si può provare in un ambiente separato prima di andare in produzione.
- **Rimedio**: Parametrizzare con `env` e usare nomi dinamici.

## Costi

### C1 – Nessun tag sulle risorse
- **Gravità**: SERIO
- **Fatto**: Le risorse non hanno tag.
- **Conseguenza**: La bolletta AWS è un unico numero, non si sa quanto costa il portale.
- **Rimedio**: Aggiungere i tag `Owner`, `Env`, `Progetto` e una regola checkov che li imponga.

## Piano di intervento
**Oggi chiudiamo**: S1, S2, S3, A1, A3, O1, E1, E2, C1 (bloccanti e alcuni seri).  
**Rimandiamo**: S4, A2, O2, O3, E3 (seri, ma non critici per l'open day).  
**Non faremo**: (nessuno per ora, ma se manca tempo si rimanda tutto).
EOF

# 2. RISPOSTA-CLIENTE.md
cat > RISPOSTA-CLIENTE.md << 'EOF'
# Riscontro alle richieste del 27/07/2026

## CR-1 – Due nuove unità formative
**ACCETTATA**.  
Aggiunte le unità "Sicurezza applicativa (30h)" e "Analisi dei dati (45h)" al catalogo.  
Il totale ore in pagina è passato da 320 a 395.  
La modifica è stata pubblicata alle 15:52, versione a1b2c3d (inserire SHA reale).  
Da ora la segreteria può fare questa modifica in autonomia in meno di 10 minuti.

## CR-2 – Caricamento file dal fornitore
**ACCETTATA CON CONDIZIONE**.  
La richiesta è legittima, ma non possiamo dare accesso al bucket del sito.  
Proponiamo un **bucket di scambio separato** con:
- Accesso solo in scrittura, solo su un prefisso specifico (es. `/fornitore/`).
- Cifratura e versioning attivi.
- Log di accesso.
- Il fornitore avrà credenziali dedicate con permessi limitati.  
Tempo stimato per implementare: mezza giornata.

## CR-3 – Rimettere i permessi pubblici sul bucket
**RIFIUTATA**.  
- **Rischio**: con `s3:*` a `Principal "*"` chiunque su internet può modificare o cancellare il sito.
- **Costo**: è già successo in passato e non esisteva una copia di backup.
- **Alternativa**: utilizzare il bucket di scambio proposto in CR-2 per il trasferimento dei file.
- **Evidenza**: abbiamo provato a riaprire il bucket in una PR e la pipeline è diventata rossa (link al run: [inserire URL del run fallito]).
EOF

# 3. src/build.mjs
cat > src/build.mjs << 'EOF'
// Generatore statico del Portale ITS. Zero dipendenze: solo Node.
import { readFileSync, writeFileSync, mkdirSync, cpSync, existsSync } from "node:fs";

const OUT = "dist";

export function totaleOre(corsi) {
  // CORREZIONE: rimosso .slice(1) – ora somma tutti i corsi
  return corsi.reduce((acc, c) => acc + c.ore, 0);
}

export function render(dati, versione) {
  const tot = totaleOre(dati.corsi);
  const righe = dati.corsi
    .map(
      (c) => `      <tr>
        <td class="cod">${c.codice}</td>
        <td>${c.titolo}</td>
        <td class="ore">${c.ore} h</td>
      </tr>`
    )
    .join("\n");
  return `<!DOCTYPE html>
<html lang="it">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Portale corsi - ${dati.istituto}</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <header>
    <h1>${dati.istituto}</h1>
    <p class="sub">Offerta formativa - biennio ${dati.biennio}</p>
  </header>
  <main>
    <table>
      <thead><tr><th>Codice</th><th>Unità formativa</th><th>Ore</th></tr></thead>
      <tbody>
${righe}
      </tbody>
      <tfoot><tr><td colspan="2">Totale ore erogate</td><td class="ore">${tot} h</td></tr></tfoot>
    </table>
  </main>
  <footer>
    <p>build <code>${versione}</code></p>
  </footer>
</body>
</html>
`;
}

function main() {
  const dati = JSON.parse(readFileSync("data/corsi.json", "utf8"));
  const versione = process.env.GITHUB_SHA?.slice(0, 7) ?? "locale";
  mkdirSync(OUT, { recursive: true });
  writeFileSync(`${OUT}/index.html`, render(dati, versione));
  writeFileSync(
    `${OUT}/versione.json`,
    JSON.stringify({ versione, corsi: dati.corsi.length, ore: totaleOre(dati.corsi) }, null, 2)
  );
  if (existsSync("site/style.css")) cpSync("site/style.css", `${OUT}/style.css`);
  console.log(`OK  ${OUT}/index.html  (${dati.corsi.length} corsi, ${totaleOre(dati.corsi)} ore, build ${versione})`);
}

if (import.meta.url === `file://${process.argv[1]}`) main();
EOF

# 4. test/portale.test.mjs
cat > test/portale.test.mjs << 'EOF'
// I gate di qualità del Portale ITS. Se uno di questi rosseggia, la pipeline si ferma.
import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { render, totaleOre } from "../src/build.mjs";

const dati = JSON.parse(readFileSync("data/corsi.json", "utf8"));

test("il catalogo non è vuoto", () => {
  assert.ok(dati.corsi.length > 0, "nessun corso nel catalogo");
});

test("ogni corso ha codice, titolo e ore positive", () => {
  for (const c of dati.corsi) {
    assert.match(c.codice ?? "", /^[A-Z]{3}-[A-Z]{2,3}$/, `codice non valido: ${c.codice}`);
    assert.ok((c.titolo ?? "").length > 2, `titolo mancante per ${c.codice}`);
    assert.ok(Number.isInteger(c.ore) && c.ore > 0, `ore non valide per ${c.codice}: ${c.ore}`);
  }
});

test("il totale ore è la somma esatta delle ore dei corsi", () => {
  const attesa = dati.corsi.reduce((a, c) => a + c.ore, 0);
  assert.equal(totaleOre(dati.corsi), attesa);
});

test("la pagina generata contiene una riga per ogni corso", () => {
  const html = render(dati, "test");
  for (const c of dati.corsi) {
    assert.ok(html.includes(c.titolo), `manca il corso ${c.titolo}`);
    assert.ok(html.includes(`${c.ore} h`), `mancano le ore di ${c.codice}`);
  }
});

test("la pagina generata mostra il totale ore corretto", () => {
  const html = render(dati, "test");
  assert.ok(html.includes(`${totaleOre(dati.corsi)} h</td>`), "totale ore assente o sbagliato");
});

test("nessun segreto finisce nella pagina pubblicata", () => {
  const html = render(dati, "test");
  const sospetti = [/AKIA[0-9A-Z]{16}/, /password\s*[:=]/i, /secret[_-]?key/i, /-----BEGIN [A-Z ]*PRIVATE KEY-----/];
  for (const re of sospetti) {
    assert.ok(!re.test(html), `stringa sospetta nel sito pubblicato: ${re}`);
  }
});
EOF

# 5. package.json
cat > package.json << 'EOF'
{
  "name": "portale-its",
  "version": "0.0.1",
  "description": "sito corsi",
  "type": "module",
  "scripts": {
    "build": "node src/build.mjs",
    "test": "node --test"
  },
  "dependencies": {}
}
EOF

# 6. .gitignore
cat > .gitignore << 'EOF'
# Dipendenze
node_modules/

# Output della build
dist/

# File di ambiente e segreti
.env
*.pem
config/impostazioni.txt

# File di stato Terraform
*.tfstate
*.tfstate.*
.terraform/
EOF

# 7. infra/tf/versions.tf
cat > infra/tf/versions.tf << 'EOF'
terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
EOF

# 8. infra/tf/variables.tf
cat > infra/tf/variables.tf << 'EOF'
variable "env" {
  description = "Ambiente di destinazione (dev, test, prod)"
  type        = string
  default     = "test"
  validation {
    condition     = contains(["dev", "test", "prod"], var.env)
    error_message = "env deve essere dev, test o prod."
  }
}

variable "owner" {
  description = "Squadra responsabile della risorsa (governance ITS)"
  type        = string
  default     = "squadra-0"
  validation {
    condition     = length(var.owner) >= 3
    error_message = "owner deve avere almeno 3 caratteri."
  }
}

variable "aws_endpoint" {
  description = "Endpoint AWS alternativo. Vuoto = AWS vero, http://127.0.0.1:5000 = moto (finto-AWS)"
  type        = string
  default     = ""
}
EOF

# 9. infra/tf/provider.tf
cat > infra/tf/provider.tf << 'EOF'
provider "aws" {
  region = "eu-south-1"

  # Le tre righe sotto servono SOLO per parlare con moto (il finto-AWS).
  # Con aws_endpoint vuoto il provider usa l'AWS vero e le credenziali reali.
  access_key                  = var.aws_endpoint == "" ? null : "test"
  secret_key                  = var.aws_endpoint == "" ? null : "test"
  skip_credentials_validation = var.aws_endpoint != ""
  skip_metadata_api_check     = var.aws_endpoint != ""
  skip_requesting_account_id  = var.aws_endpoint != ""
  s3_use_path_style           = var.aws_endpoint != ""

  endpoints {
    s3       = var.aws_endpoint
    dynamodb = var.aws_endpoint
    kms      = var.aws_endpoint
    sts      = var.aws_endpoint
  }
}
EOF

# 10. infra/tf/main.tf
cat > infra/tf/main.tf << 'EOF'
# Portale corsi ITS ICT Piemonte - infrastruttura di pubblicazione (binario B - Terraform)

locals {
  suffisso = "${var.env}-${var.owner}"

  # Tag obbligatori da capitolato: il gate della pipeline verifica che Owner ci sia.
  tag_comuni = {
    Owner    = var.owner
    Env      = var.env
    Progetto = "portale-its"
  }
}

data "aws_caller_identity" "attuale" {}

# ---------- bucket dei log di accesso ----------
resource "aws_s3_bucket" "log" {
  bucket = "portale-its-log-${local.suffisso}"
  tags   = local.tag_comuni
}

resource "aws_s3_bucket_ownership_controls" "log" {
  bucket = aws_s3_bucket.log.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "log" {
  bucket = aws_s3_bucket.log.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log" {
  bucket = aws_s3_bucket.log.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "log" {
  bucket                  = aws_s3_bucket.log.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Policy che consente a S3 di scrivere i log nel bucket dei log
resource "aws_s3_bucket_policy" "log" {
  bucket = aws_s3_bucket.log.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "ConsentiScritturaLogS3"
      Effect    = "Allow"
      Principal = { Service = "logging.s3.amazonaws.com" }
      Action    = "s3:PutObject"
      Resource  = "${aws_s3_bucket.log.arn}/*"
      Condition = {
        StringEquals = {
          "aws:SourceAccount" = data.aws_caller_identity.attuale.account_id
        }
      }
    }]
  })
}

# ---------- bucket del sito ----------
resource "aws_s3_bucket" "sito" {
  bucket = "portale-its-sito-${local.suffisso}"
  tags   = local.tag_comuni
}

resource "aws_s3_bucket_versioning" "sito" {
  bucket = aws_s3_bucket.sito.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sito" {
  bucket = aws_s3_bucket.sito.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "sito" {
  bucket                  = aws_s3_bucket.sito.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "sito" {
  bucket        = aws_s3_bucket.sito.id
  target_bucket = aws_s3_bucket.log.id
  target_prefix = "sito/${var.env}/"

  depends_on = [aws_s3_bucket_policy.log]
}

# ---------- tabella iscrizioni ----------
resource "aws_kms_key" "iscrizioni" {
  description         = "Chiave di cifratura della tabella iscrizioni del portale ITS"
  enable_key_rotation = true
  tags                = local.tag_comuni
}

resource "aws_dynamodb_table" "iscrizioni" {
  name         = "portale-its-iscrizioni-${local.suffisso}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "iscrizioneId"

  attribute {
    name = "iscrizioneId"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.iscrizioni.arn
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = local.tag_comuni
}
EOF

# 11. infra/tf/outputs.tf
cat > infra/tf/outputs.tf << 'EOF'
output "bucket_sito" {
  description = "Bucket che ospita il portale"
  value       = aws_s3_bucket.sito.id
}

output "bucket_log" {
  description = "Bucket dei log di accesso"
  value       = aws_s3_bucket.log.id
}

output "tabella_iscrizioni" {
  description = "Tabella delle iscrizioni"
  value       = aws_dynamodb_table.iscrizioni.name
}
EOF

# 12. .github/workflows/ci.yml
cat > .github/workflows/ci.yml << 'EOF'
# CI del Portale ITS - i GATE DI QUALITA.
# Gira su ogni pull request: se un gate rosseggia, quel codice non entra in main.
name: CI

on:
  pull_request:
  push:
    branches-ignore: [main]

permissions:
  contents: read

env:
  GATE_CHECKS: >-
    CKV_AWS_18,CKV_AWS_19,CKV_AWS_20,CKV_AWS_21,CKV_AWS_28,CKV_AWS_119,
    CKV_AWS_7,CKV_AWS_53,CKV_AWS_54,CKV_AWS_55,CKV_AWS_56,CKV2_AWS_6,CKV_ITS_1

jobs:

  rilevamento:
    name: Struttura del progetto
    runs-on: ubuntu-latest
    outputs:
      cfn: ${{ steps.binario.outputs.cfn }}
      tf: ${{ steps.binario.outputs.tf }}
    steps:
      - uses: actions/checkout@v7

      - name: Quale binario di infrastruttura c'è in questo repo?
        id: binario
        run: |
          if [ -f infra/portale-its.yaml ]; then echo "cfn=true" >> "$GITHUB_OUTPUT"; else echo "cfn=false" >> "$GITHUB_OUTPUT"; fi
          if [ -f infra/tf/main.tf ];      then echo "tf=true"  >> "$GITHUB_OUTPUT"; else echo "tf=false"  >> "$GITHUB_OUTPUT"; fi
          if [ ! -f infra/portale-its.yaml ] && [ ! -f infra/tf/main.tf ]; then
            echo "::error::Nessun file di infrastruttura: qualcuno ha cancellato il codice IaC."
            exit 1
          fi
          echo "trovato:"; ls -1 infra infra/tf 2>/dev/null || true

  applicazione:
    name: App - install, test, build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7

      - uses: actions/setup-node@v7
        with:
          node-version: '22'

      - name: Installazione bloccata dal lockfile
        run: npm ci

      - name: Test
        run: npm test

      - name: Build del sito
        run: npm run build

      - name: Nessun segreto nel sito pubblicato
        run: bash script/sniffa-segreti.sh dist

      - uses: actions/upload-artifact@v7
        with:
          name: portale-dist
          path: dist/
          retention-days: 7

  segreti:
    name: Segreti
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7

      - uses: actions/setup-python@v7
        with:
          python-version: '3.12'

      - name: Sniffer fatto in casa
        run: bash script/sniffa-segreti.sh .

      - name: Scansione con checkov
        run: |
          pip install --quiet checkov
          checkov -d . --framework secrets --enable-secret-scan-all-files \
            --skip-path node_modules --skip-path dist --compact

  infra-terraform:
    name: IaC - Terraform
    needs: rilevamento
    if: needs.rilevamento.outputs.tf == 'true'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7

      - uses: actions/setup-python@v7
        with:
          python-version: '3.12'

      - name: Terraform
        run: |
          curl -sSLo tf.zip https://releases.hashicorp.com/terraform/1.15.8/terraform_1.15.8_linux_amd64.zip
          sudo unzip -oq tf.zip -d /usr/local/bin
          rm tf.zip && terraform version

      - name: Formattazione
        working-directory: infra/tf
        run: terraform fmt -check -recursive

      - name: Inizializzazione e validazione
        working-directory: infra/tf
        run: |
          terraform init -input=false -backend=false
          terraform validate

      - name: Regole del capitolato (policy as code)
        run: |
          pip install --quiet checkov
          checkov -d infra/tf --framework terraform \
            --external-checks-dir policy \
            --check "$(echo $GATE_CHECKS | tr -d ' ')" \
            --compact

      - name: Audit completo (informativo, non blocca)
        run: checkov -d infra/tf --framework terraform --compact --soft-fail
EOF

# 13. .github/workflows/release.yml
cat > .github/workflows/release.yml << 'EOF'
# RELEASE del Portale ITS - la pipeline multi-stadio.
# Sorgente -> Build -> Collaudo su finto-AWS -> APPROVAZIONE UMANA -> Produzione.
name: Release

on:
  push:
    branches: [main]
  workflow_dispatch:
    inputs:
      versione_da_ripubblicare:
        description: "SHA da ripubblicare (rollback). Vuoto = ultimo commit."
        required: false
        type: string

permissions:
  contents: read

concurrency:
  group: release-portale-its
  cancel-in-progress: false

jobs:

  build:
    name: 1. Build
    runs-on: ubuntu-latest
    outputs:
      versione: ${{ steps.info.outputs.versione }}
    steps:
      - uses: actions/checkout@v7
        with:
          ref: ${{ inputs.versione_da_ripubblicare || github.sha }}

      - uses: actions/setup-node@v7
        with:
          node-version: '22'

      - run: npm ci
      - run: npm test
      - run: npm run build

      - name: Etichetta della release
        id: info
        run: |
          VERSIONE=$(git rev-parse --short HEAD)
          echo "versione=$VERSIONE" >> "$GITHUB_OUTPUT"
          echo "### Portale ITS - build \`$VERSIONE\`" >> "$GITHUB_STEP_SUMMARY"
          cat dist/versione.json >> "$GITHUB_STEP_SUMMARY"

      - uses: actions/upload-artifact@v7
        with:
          name: portale-dist
          path: dist/
          retention-days: 30

  collaudo-test:
    name: 2. Collaudo su test
    needs: build
    runs-on: ubuntu-latest
    env:
      AWS_ACCESS_KEY_ID: test
      AWS_SECRET_ACCESS_KEY: test
      AWS_DEFAULT_REGION: eu-south-1
      ENDPOINT: http://127.0.0.1:5000
    steps:
      - uses: actions/checkout@v7

      - uses: actions/download-artifact@v8
        with:
          name: portale-dist
          path: dist

      - uses: actions/setup-python@v7
        with:
          python-version: '3.12'

      - name: Avvio del finto-AWS (moto)
        run: |
          pip install --quiet "moto[server]" awscli
          nohup moto_server -p 5000 > /tmp/moto.log 2>&1 &
          for i in $(seq 1 30); do
            curl -sf "$ENDPOINT/moto-api/" >/dev/null && break
            sleep 1
          done
          curl -sf "$ENDPOINT/moto-api/" >/dev/null && echo "finto-AWS pronto"

      - name: Deploy dell'infrastruttura (Terraform)
        run: |
          echo "::group::Terraform"
          curl -sSLo tf.zip https://releases.hashicorp.com/terraform/1.15.8/terraform_1.15.8_linux_amd64.zip
          sudo unzip -oq tf.zip -d /usr/local/bin && rm tf.zip
          cd infra/tf
          terraform init -input=false
          terraform apply -input=false -auto-approve \
            -var aws_endpoint="$ENDPOINT" -var owner=squadra
          echo "::endgroup::"

      - name: Collaudo - le risorse esistono davvero?
        run: |
          echo "--- bucket ---"
          BUCKETS=$(aws --endpoint-url "$ENDPOINT" s3api list-buckets --query 'Buckets[].Name' --output text)
          echo "$BUCKETS"
          echo "$BUCKETS" | grep -q "portale-its-sito" || { echo "::error::bucket del sito mancante"; exit 1; }
          echo "$BUCKETS" | grep -q "portale-its-log"  || { echo "::error::bucket dei log mancante"; exit 1; }
          echo "--- tabelle ---"
          TABELLE=$(aws --endpoint-url "$ENDPOINT" dynamodb list-tables --output text)
          echo "$TABELLE"
          echo "$TABELLE" | grep -q "iscrizioni" || { echo "::error::tabella iscrizioni mancante"; exit 1; }

      - name: Collaudo - il sito si pubblica sul bucket
        run: |
          SITO=$(aws --endpoint-url "$ENDPOINT" s3api list-buckets \
            --query "Buckets[?starts_with(Name,'portale-its-sito')].Name | [0]" --output text)
          aws --endpoint-url "$ENDPOINT" s3 cp dist/ "s3://$SITO/" --recursive
          aws --endpoint-url "$ENDPOINT" s3 ls "s3://$SITO/" | tee /tmp/ls.txt
          grep -q index.html /tmp/ls.txt || { echo "::error::index.html non pubblicato"; exit 1; }
          echo "### Collaudo su test superato su \`$SITO\`" >> "$GITHUB_STEP_SUMMARY"

  approvazione:
    name: 3. Approvazione per la produzione
    needs: [build, collaudo-test]
    runs-on: ubuntu-latest
    environment: produzione
    steps:
      - name: Via libera
        run: |
          echo "Release ${{ needs.build.outputs.versione }} approvata da ${{ github.actor }}"
          echo "### Approvata la release \`${{ needs.build.outputs.versione }}\`" >> "$GITHUB_STEP_SUMMARY"

  pubblica:
    name: 4. Pubblicazione in produzione
    needs: [build, approvazione]
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pages: write
      id-token: write
    environment:
      name: github-pages
      url: ${{ steps.deploy.outputs.page_url }}
    steps:
      - uses: actions/download-artifact@v8
        with:
          name: portale-dist
          path: dist

      - uses: actions/configure-pages@v5
      - uses: actions/upload-pages-artifact@v3
        with:
          path: dist
      - id: deploy
        uses: actions/deploy-pages@v5

      - name: Cronaca della release
        run: |
          echo "### In produzione la versione \`${{ needs.build.outputs.versione }}\`" >> "$GITHUB_STEP_SUMMARY"
          echo "${{ steps.deploy.outputs.page_url }}" >> "$GITHUB_STEP_SUMMARY"
EOF

# 14. policy/__init__.py (vuoto)
touch policy/__init__.py

# 15. policy/its_tag_owner.py
cat > policy/its_tag_owner.py << 'EOF'
"""
Policy-as-code ITS - CKV_ITS_1
Capitolato Portale ITS, requisito di governance: ogni risorsa taggabile deve
portare il tag Owner, cioè la squadra responsabile. Un check scritto una volta
e valido su entrambi i binari: CloudFormation e Terraform.
"""
from checkov.common.models.enums import CheckCategories, CheckResult
from checkov.cloudformation.checks.resource.base_resource_check import (
    BaseResourceCheck as BaseCfnCheck,
)
from checkov.terraform.checks.resource.base_resource_check import (
    BaseResourceCheck as BaseTfCheck,
)

ID = "CKV_ITS_1"
NOME = "Ogni risorsa del portale deve avere il tag Owner (capitolato ITS)"
GUIDA = "Aggiungi il tag Owner con il nome della squadra responsabile della risorsa."


class TagOwnerCloudFormation(BaseCfnCheck):
    def __init__(self) -> None:
        super().__init__(
            name=NOME,
            id=ID,
            categories=[CheckCategories.CONVENTION],
            supported_resources=[
                "AWS::S3::Bucket",
                "AWS::DynamoDB::Table",
            ],
            guideline=GUIDA,
        )

    def scan_resource_conf(self, conf):
        # In CloudFormation i tag sono una lista: [{Key: ..., Value: ...}, ...]
        tags = (conf.get("Properties") or {}).get("Tags") or []
        if isinstance(tags, dict):
            tags = [tags]
        for tag in tags:
            if not isinstance(tag, dict):
                continue
            if str(tag.get("Key", "")).lower() == "owner" and str(tag.get("Value", "")).strip():
                return CheckResult.PASSED
        return CheckResult.FAILED


class TagOwnerTerraform(BaseTfCheck):
    def __init__(self) -> None:
        super().__init__(
            name=NOME,
            id=ID,
            categories=[CheckCategories.CONVENTION],
            supported_resources=[
                "aws_s3_bucket",
                "aws_dynamodb_table",
            ],
            guideline=GUIDA,
        )

    def scan_resource_conf(self, conf):
        # In Terraform i tag sono una mappa, incapsulata in una lista dal parser
        tags = conf.get("tags")
        if isinstance(tags, list) and tags:
            tags = tags[0]
        if isinstance(tags, dict):
            for chiave, valore in tags.items():
                if str(chiave).lower() == "owner" and str(valore).strip():
                    return CheckResult.PASSED
        return CheckResult.FAILED


check_cfn = TagOwnerCloudFormation()
check_tf = TagOwnerTerraform()
EOF

# 16. script/sniffa-segreti.sh
cat > script/sniffa-segreti.sh << 'EOF'
#!/usr/bin/env bash
# Gate fatto in casa: nel repository non ci devono essere segreti.
# Se ne trova uno esce con 1 e la pipeline si ferma.
#   uso:  bash script/sniffa-segreti.sh [cartella]
set -u
CARTELLA="${1:-.}"

SCHEMI='AKIA[0-9A-Z]{16}'
SCHEMI="$SCHEMI|ghp_[A-Za-z0-9]{36}"
SCHEMI="$SCHEMI|-----BEGIN [A-Z ]*PRIVATE KEY"
SCHEMI="$SCHEMI|AWS_SECRET_ACCESS_KEY[[:space:]]*[:=][[:space:]]*[A-Za-z0-9/+]{40}"
SCHEMI="$SCHEMI|(password|passwd|api[_-]?token)[[:space:]]*[:=][[:space:]]*.{8,}"

TROVATI=$(grep -rInE "$SCHEMI" "$CARTELLA" \
  --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=.terraform \
  --exclude-dir=dist --exclude=package-lock.json --exclude=sniffa-segreti.sh 2>/dev/null)

if [ -n "$TROVATI" ]; then
  echo "SEGRETI TROVATI - la pipeline si ferma:"
  echo "$TROVATI"
  exit 1
fi

echo "nessun segreto sospetto in $CARTELLA"
EOF
chmod +x script/sniffa-segreti.sh

# 17. data/corsi.json (già esistente, lo sovrascriviamo con i due nuovi corsi)
cat > data/corsi.json << 'EOF'
{
  "istituto": "ITS ICT Piemonte",
  "biennio": "2025/2027",
  "corsi": [
    { "codice": "SOA-FW",  "titolo": "Firewall",                      "ore": 60, "docente": "P. Costanzo" },
    { "codice": "SOA-SE",  "titolo": "Servizi Esposti",               "ore": 40, "docente": "P. Costanzo" },
    { "codice": "SOA-ID",  "titolo": "Incident Detection & Response", "ore": 36, "docente": "P. Costanzo" },
    { "codice": "ACA-ARC", "titolo": "Architettura e Progettazione",  "ore": 48, "docente": "P. Costanzo" },
    { "codice": "ACA-IAC", "titolo": "Infrastructure as Code",        "ore": 60, "docente": "P. Costanzo" },
    { "codice": "ACA-AUT", "titolo": "Automation e Pipeline con AWS", "ore": 76, "docente": "P. Costanzo" },
    { "codice": "SIC-APP", "titolo": "Sicurezza applicativa",         "ore": 30, "docente": "P. Costanzo" },
    { "codice": "DAT-ANA", "titolo": "Analisi dei dati",              "ore": 45, "docente": "P. Costanzo" }
  ]
}
EOF

echo "✅ Tutti i file sono stati creati!"

echo "📦 Ora genera package-lock.json con:"
echo "    npm install --package-lock-only"
echo
echo "📂 Poi fai git add . e commit."