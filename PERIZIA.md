# PERIZIA - Portale corsi ITS
Squadra: yousef abdelmoneim, robero cantore , cristian torres 
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
