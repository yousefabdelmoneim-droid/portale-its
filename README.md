## 📖 Descrizione

Questo repository contiene il **Portale Corsi ITS ICT Piemonte** – un sistema per la pubblicazione dell'offerta formativa del biennio 2025/2027.

Il progetto è il risultato del lab **"L'eredità: perizia e pipeline sul portale ITS"** che simula un incarico reale di:
- Presa in carico di un sistema esistente
- Perizia e identificazione dei difetti
- Miglioramento dell'infrastruttura con Terraform
- Automazione della pubblicazione con pipeline CI/CD su GitHub Actions
- Gestione di richieste di modifica e rollback

---

## 🌐 Sito pubblicato

Il portale è online all'indirizzo:

👉 **[https://yousefabdelmoneim-droid.github.io/portale-its/](https://yousefabdelmoneim-droid.github.io/portale-its/)**

---

## 📁 Struttura del repository

```
portale-its/
├── .github/
│   └── workflows/
│       ├── ci.yml                # CI: 5 gate automatici
│       └── release.yml           # Pipeline di pubblicazione
├── infra/
│   └── tf/
│       ├── versions.tf           # Versioni Terraform
│       ├── variables.tf          # Variabili (env, owner, endpoint)
│       ├── provider.tf           # Provider AWS (supporto finto-AWS)
│       ├── main.tf               # Risorse: bucket, KMS, DynamoDB
│       └── outputs.tf            # Output per la pipeline
├── policy/
│   ├── __init__.py               # Obbligatorio per checkov
│   └── its_tag_owner.py          # Regola custom CKV_ITS_1
├── script/
│   └── sniffa-segreti.sh         # Gate per rilevare segreti
├── src/
│   └── build.mjs                 # Generatore statico del sito
├── test/
│   └── portale.test.mjs          # 6 test automatici
├── data/
│   └── corsi.json                # Dati dei corsi (8 corsi, 395 ore)
├── PERIZIA.md                    # Perizia del sistema
├── RISPOSTA-CLIENTE.md           # Risposte alle 3 richieste
├── package.json                  # Dipendenze e script
├── package-lock.json             # Dipendenze bloccate
├── .gitignore
└── README.md
```

---

## 🚀 Installazione e utilizzo

### 1. Clonare il repository

```bash
git clone https://github.com/yousefabdelmoneim-droid/portale-its.git
cd portale-its
```

### 2. Installare le dipendenze

```bash
npm install --package-lock-only
```

### 3. Eseguire i test

```bash
npm test
```

**Output atteso:**
```
✔ il catalogo non è vuoto
✔ ogni corso ha codice, titolo e ore positive
✔ il totale ore è la somma esatta delle ore dei corsi
✔ la pagina generata contiene una riga per ogni corso
✔ la pagina generata mostra il totale ore corretto
✔ nessun segreto finisce nella pagina pubblicata
ℹ tests 6
ℹ pass 6
ℹ fail 0
```

### 4. Generare il sito

```bash
npm run build
```

Il sito viene generato nella cartella `dist/`.

### 5. Aprire il sito localmente

```bash
open dist/index.html
```

---

## 🔧 Infrastruttura (Terraform)

### Risorse create

| Risorsa | Descrizione |
|---------|-------------|
| `aws_s3_bucket.log` | Bucket per i log di accesso |
| `aws_s3_bucket.sito` | Bucket per il sito web statico |
| `aws_kms_key.iscrizioni` | Chiave KMS per cifrare la tabella |
| `aws_dynamodb_table.iscrizioni` | Tabella per le iscrizioni |

### Caratteristiche di sicurezza

- ✅ Versioning abilitato su tutti i bucket
- ✅ Cifratura AES256 sui bucket
- ✅ Cifratura KMS sulla tabella DynamoDB
- ✅ Public Access Block su tutti i bucket
- ✅ Point-in-Time Recovery sulla tabella
- ✅ Tag `Owner`, `Env`, `Progetto` su tutte le risorse
- ✅ Logging di accesso attivo

---

## 🔄 Pipeline CI/CD

### CI (`ci.yml`) – 5 gate automatici

| Gate | Descrizione |
|------|-------------|
| **Struttura** | Verifica che i file di infrastruttura esistano |
| **Applicazione** | `npm ci`, `npm test`, `npm run build` + sniffa segreti su `dist/` |
| **Segreti** | Sniffer + checkov secrets |
| **IaC – Terraform** | `fmt -check`, `init`, `validate`, checkov con regole del capitolato |
| **Policy as Code** | Regola custom `CKV_ITS_1` (tag Owner obbligatorio) |

### Release (`release.yml`) – 4 stadi

| Stadio | Descrizione |
|--------|-------------|
| **1. Build** | Costruisce l'artefatto `dist/` e lo carica |
| **2. Collaudo su test** | Deploy su finto-AWS (moto), verifica risorse, carica il sito |
| **3. Approvazione** | Richiede approvazione umana su environment `produzione` |
| **4. Produzione** | Pubblica su GitHub Pages (Piano B: branch `gh-pages`) |

---

## 🐛 Rollback

### Strada 1 – Ripubblicare artefatto (veloce)

1. Vai su **Actions** → **Release** → **Run workflow**
2. Inserisci lo SHA della versione buona
3. Approva → sito ripristinato

### Strada 2 – Revert del commit (definitiva)

1. Vai su **Commits** → trova il commit colpevole
2. Clicca sui tre puntini → **Revert**
3. PR, merge → problema risolto definitivamente

---

## 📊 Numeri DORA

| Metrica | Valore |
|---------|--------|
| **Frequenza di rilascio** | 2 rilasci |
| **Lead time** | ~15-20 minuti |
| **% release fallite** | 50% |
| **MTTR** | Tempo di ripristino dell'incidente ⏱️ |

---

## 🧑‍🏫 Perizia e documentazione

- **`PERIZIA.md`** – 15 constatazioni divise per:
  - 🔒 Sicurezza (S1–S4)
  - 🛡️ Affidabilità (A1–A3)
  - ⚙️ Operabilità (O1–O3)
  - 🚀 Evolvibilità (E1–E3)
  - 💰 Costi (C1)

- **`RISPOSTA-CLIENTE.md`** – Risposte a:
  - **CR-1**: Aggiunta due nuovi corsi → **ACCETTATA**
  - **CR-2**: Caricamento file dal fornitore → **ACCETTATA CON CONDIZIONE**
  - **CR-3**: Rimettere permessi pubblici → **RIFIUTATA** (con rischio, costo, alternativa)

---

## 📦 Dipendenze

- **Node.js** – Runtime per il generatore statico
- **Terraform** – Infrastructure as Code
- **Checkov** – Policy as Code
- **moto** – Finto-AWS per il collaudo

---

## 🔗 Link utili

| Risorsa | Link |
|---------|------|
| **Repository** | [https://github.com/yousefabdelmoneim-droid/portale-its](https://github.com/yousefabdelmoneim-droid/portale-its) |
| **Sito pubblicato** | [https://yousefabdelmoneim-droid.github.io/portale-its/](https://yousefabdelmoneim-droid.github.io/portale-its/) |

---

## 👨‍💻 Autore

**Yousef Abdelmoneim** – [GitHub](https://github.com/yousefabdelmoneim-droid)

---

## 📄 Licenza

Questo progetto è stato realizzato a scopo didattico per il corso **ITS ICT Piemonte – AWS Cloud Architect**.

---

## 🙏 Ringraziamenti

- **Paolo Costanzo** – Docente del corso
- **ITS ICT Piemonte** – Ente formativo

---

**Lab completato!** 🎉

> *"Non avete riscritto niente. Avete cambiato chi decide, cosa è permesso, e cosa succede quando qualcuno sbaglia. Questo è migliorare un'architettura."*
```

---

## 📦 Come aggiungere il README al repository

```bash
# 1. Crea il file README.md
nano README.md
# (copia e incolla il contenuto sopra, salva con CTRL+O, INVIO, CTRL+X)

# 2. Aggiungi, committa e pusha
git add README.md
git commit -m "Aggiunto README completo per la consegna"
git push origin main
```

---

## 🔗 Link da condividere con i colleghi

### Repository:
```
https://github.com/yousefabdelmoneim-droid/portale-its.git
```

### Sito online:
```
https://yousefabdelmoneim-droid.github.io/portale-its/
```

---

