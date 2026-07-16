# Quota Bubble

[English](../README.md) | [中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Italiano](README.it.md) | [Nederlands](README.nl.md)

Una finestra flottante per macOS e Windows che mostra l’uso Codex su 5 ore, l’uso settimanale e i ripristini disponibili.

![Quota Bubble preview](../assets/preview-plus.png)

## Funzionalità

- Mostra l’uso Codex su 5 ore, l’uso settimanale e i ripristini disponibili.
- Su macOS mostra la scadenza di ogni ripristino, con un punto rosso entro tre giorni e verde negli altri casi.
- Su macOS mostra localmente l’account corrente e la scadenza dell’abbonamento senza salvare credenziali nello snapshot della quota.
- Mantiene stabili le quote live e impedisce la visualizzazione dei dati dell’account precedente dopo un cambio account.
- Funziona in modo indipendente e legge i dati locali della quota Codex.
- Ricorda posizione, tema e stato fissato.
- Un'unica app SwiftUI gestisce HUD, icona Dock, menu e ciclo di vita.
- Aggiunge azioni di menu per aggiornare, disinstallare e cambiare lingua.
- Mostra un piccolo punto rosso accanto alla versione quando è disponibile una release GitHub più recente.
- Supporta tema chiaro e scuro.
- Segue automaticamente la lingua di sistema.

## Installazione

### Metodo 1: installer app

Se non vuoi usare il Terminale, apri la pagina dell’ultima release e scarica da lì l’installer:

[Apri la pagina dell’ultima release](https://github.com/itzhaolei/codex-usage-widget/releases/latest)

Decomprimi il file e fai doppio clic su `Install Quota Bubble.app`. Quota Bubble legge i dati quota locali di Codex dall'account utente corrente e si apre direttamente, senza schermate di configurazione.
L’app macOS recupera le quote in modo nativo con Swift. Non richiede Node.js, npm, un’installazione separata di Codex CLI, Xcode o strumenti da riga di comando; servono solo macOS 13 o successivo, Codex connesso e `~/.codex/auth.json`, e accesso di rete a Codex.

Windows è allineato a macOS nella v3.0.4. Scarica `QuotaBubble-*-Windows-Setup.exe` dall’[ultima release](https://github.com/itzhaolei/codex-usage-widget/releases/latest) e apri con doppio clic l’installer grafico. Non servono PowerShell, Node.js, terminale o un runtime .NET separato.

Il README punta sempre alla pagina dell’ultima release. Per installare una versione precedente, apri [tutte le release](https://github.com/itzhaolei/codex-usage-widget/releases) e scarica l’installer dalla pagina della versione desiderata.

### Metodo 2: installazione in una riga

```bash
CODEX_USAGE_WIDGET_URL=https://github.com/itzhaolei/codex-usage-widget/archive/refs/heads/main.tar.gz bash -c "$(curl -fsSL https://raw.githubusercontent.com/itzhaolei/codex-usage-widget/main/scripts/bootstrap-install.sh)"
```

### Metodo 3: installazione locale

```bash
bash scripts/install.sh
```

## Disinstallazione

```bash
bash scripts/uninstall.sh
```

## Privacy

Questo plugin viene eseguito localmente. L’app macOS legge solo in memoria il token Codex corrente da `~/.codex/auth.json` per richiedere al backend quota, saldo, piano e ripristini di quell’account. Il token non viene mai scritto nello snapshot e il repository non include credenziali personali né dati dell’account.
