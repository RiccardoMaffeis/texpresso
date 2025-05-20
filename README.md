# TEDxpresso

## Descrizione
TedX News App è un'applicazione mobile che consente agli utenti di scoprire nuovi interessi attraverso la visione di video TedX, rimanere aggiornati sulle ultime notizie e connettersi con persone che condividono gli stessi interessi.

L'app propone casualmente notizie che potrebbero non rispecchiare gli interessi dell'utente per favorire la scoperta di nuovi argomenti e permette agli utenti di commentare le notizie e visualizzare i profili altrui.

## Obiettivi
- **Scoprire nuovi interessi** attraverso video TedX.
- **Rimanere aggiornati** sulle ultime notizie da Google News, Instagram, Facebook e X.
- **Seguire i propri interessi** con un'interfaccia facile e intuitiva.
- **Connettersi con altre persone** che condividono gli stessi interessi.

## Architettura Tecnica
L'applicazione utilizza diversi servizi e tecnologie:
- **RSS**: per ottenere dati da Google News.
- **Amazon Cognito**: per la gestione dell'autenticazione.
- **SNS (Simple Notification Service)**: per le notifiche push.
- **AWS Glue**: per la gestione e trasformazione dei dati.
- **Amazon S3**: per l'archiviazione dei dati.
- **API Instagram**: per ottenere dati da Instagram.
- **X API V2**: per ottenere dati da X (Twitter).
- **API Facebook**: per ottenere dati da Facebook.
- **MongoDB**: come database principale.
- **GitHub**: per l'archiviazione del codice e della documentazione.

## Criticità e Sfide
- **Connessione a Internet necessaria**: l'app richiede una connessione attiva per funzionare.
- **Gestione delle proposte di nuovi interessi**: garantire la pertinenza e la varietà dei suggerimenti.
- **Gestione della privacy dei profili**: protezione dei dati personali degli utenti.
- **Gestione dei commenti**: moderazione e prevenzione di contenuti inappropriati.
- **Gestione delle fake news**: identificazione e filtraggio delle notizie false.

## Contributori
- Riccardo Maffeis (1085706)
- Matteo Zanotti (1085443)

