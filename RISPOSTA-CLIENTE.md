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
