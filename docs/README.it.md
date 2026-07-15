# Quota Bubble

[English](../README.md) | [中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Italiano](README.it.md) | [Nederlands](README.nl.md)

Una finestra flottante per macOS e Windows che mostra l’uso Codex su 5 ore, l’uso settimanale e i ripristini disponibili.

![Quota Bubble preview](../assets/preview-plus.png)

## Funzionalità

- Mostra l’uso Codex su 5 ore, l’uso settimanale e i ripristini disponibili.
- Su macOS mostra la scadenza di ogni ripristino, con un punto rosso entro tre giorni e verde negli altri casi.
- Su macOS mostra localmente l’account corrente e la scadenza dell’abbonamento senza salvare credenziali nello snapshot della quota.
- Mantiene stabili i valori passando tra utilizzo live e registro locale della sessione.
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

Windows è allineato a macOS nella v3.0.3. Scarica `QuotaBubble-*-Windows-Setup.exe` dall’[ultima release](https://github.com/itzhaolei/codex-usage-widget/releases/latest) e apri con doppio clic l’installer grafico. Non servono PowerShell, Node.js, terminale o un runtime .NET separato.

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

Questo plugin viene eseguito localmente. Legge i metadati locali delle sessioni Codex e il token Codex corrente in `~/.codex/auth.json` solo per richiedere al backend Codex i ripristini disponibili dell’utente. Questo repository non include credenziali personali né dati dell’account.
