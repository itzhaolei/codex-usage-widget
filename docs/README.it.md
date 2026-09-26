# Quota Bubble

[English](../README.md) | [中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Italiano](README.it.md) | [Nederlands](README.nl.md)

Una finestra mobile basata su un’unica codebase Flutter/Dart per macOS e Windows che mostra quota Codex di 5 ore, quota settimanale, reset, saldo, piano, account e ripristini disponibili.

![Quota Bubble 4.0 preview](../assets/preview-v4.png?raw=1&v=20260926-4)

## Funzionalità

- Mostra la quota di 5 ore quando presente, oltre a quota settimanale Codex, reset, saldo, piano e ripristini disponibili.
- Mostra un badge Free, Plus, Pro 5x/20x, Business, Business 5x/20x, Enterprise o Edu in base al piano comunicato dall’account.
- Mostra dopo il conto alla rovescia la data esatta del reset settimanale e il giorno della settimana in ora locale, con precisione al secondo.
- Mostra nella barra dei menu macOS e nel suggerimento dell’area di notifica Windows la percentuale della quota di 5 ore quando presente; altrimenti mostra quella settimanale.
- Chiudendo si nasconde la finestra e ne viene sospeso il rendering; la percentuale continua ad aggiornarsi nella barra dei menu di macOS o nel suggerimento di Windows. Per uscire usa il menu della barra o dell’area di notifica.
- Su macOS e Windows mostra la scadenza di ogni ripristino, con un punto rosso entro tre giorni e verde negli altri casi.
- Su macOS e Windows mostra localmente l’account corrente e la scadenza dell’abbonamento senza salvare credenziali nello snapshot della quota.
- Mostra lo spazio di sistema e la memoria fisica disponibili; su Windows indica lo spazio libero dell’unità C.
- Mantiene stabili le quote live e impedisce la visualizzazione dei dati dell’account precedente dopo un cambio account.
- Funziona indipendentemente da Codex Desktop, legge l’accesso locale e richiede i dati aggiornati della quota al backend Codex.
- Ricorda posizione, tema e stato fissato.
- Una base Flutter condivisa gestisce HUD, icona Dock o area di notifica, menu e ciclo di vita su macOS e Windows.
- Limita l’app a una sola istanza e una sola finestra quota, ripristinabile dalla barra dei menu o dall’area di notifica dopo essere stata nascosta.
- Mantiene la voce nella barra delle applicazioni di Windows e usa il livello finestra della barra di stato quando è fissata su macOS.
- Usa lo stesso set di icone vettoriali in stile macOS su entrambe le piattaforme.
- Aggiunge azioni nella barra dei menu o nell’area di notifica per aggiornare, aprire il sito ufficiale e condividere, disinstallare e cambiare lingua.
- Mostra un piccolo punto rosso accanto alla versione quando è disponibile una release GitHub più recente.
- Supporta tema chiaro e scuro.
- Segue automaticamente la lingua di sistema.

## Installazione

Apri il [sito ufficiale Quota Bubble](https://htmlpreview.github.io/?https://github.com/itzhaolei/codex-usage-widget/blob/main/public/index.html?v=20260926-4) e premi il pulsante principale. Il sito rileva macOS o Windows e scarica direttamente l’ultimo installer grafico senza aprire la pagina Releases.

### macOS

macOS 13 o successivo. Estrai `macOS-Installer.zip` e apri `Install Quota Bubble.app`. Non servono Node.js, npm, Codex CLI separato, Xcode o comandi. Codex deve essere connesso e aver creato `~/.codex/auth.json`.

### Windows

Windows 10 o successivo. Apri `Windows-Setup.exe` e segui la procedura grafica. Dopo l’installazione viene creato automaticamente un collegamento Quota Bubble sul desktop. Non servono PowerShell, Node.js, terminale o un runtime .NET separato.

## Disinstallazione

Su macOS apri il menu Quota Bubble nella barra dei menu e scegli **Disinstalla**. Su Windows usa **Impostazioni > App > App installate**.

## Privacy

Questo plugin viene eseguito localmente. L’app desktop legge solo in memoria il token Codex corrente da `~/.codex/auth.json` per richiedere al backend quota, saldo, piano e ripristini di quell’account. Il token non viene mai scritto nello snapshot e il repository non include credenziali personali né dati dell’account.
