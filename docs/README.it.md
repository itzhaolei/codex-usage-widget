# Codex Usage Widget

[English](../README.md) | [中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Italiano](README.it.md) | [Nederlands](README.nl.md)

Una finestra flottante per macOS che mostra l’uso Codex su 5 ore, l’uso settimanale e i ripristini disponibili.

![Codex Usage Widget preview](../assets/preview.png)

## Funzionalità

- Mostra l’uso Codex su 5 ore, l’uso settimanale e i ripristini disponibili.
- Segue il ciclo di vita di Codex Desktop.
- Ricorda posizione, tema e stato fissato.
- Mantiene un solo HUD e un solo launcher Dock.
- Aggiunge azioni di menu per aggiornare, disinstallare e cambiare lingua.
- Mostra un piccolo punto rosso accanto alla versione quando è disponibile una release GitHub più recente.
- Supporta tema chiaro e scuro.
- Segue automaticamente la lingua di sistema.

## Installazione

### Metodo 1: installer app

Se non vuoi usare il Terminale, apri la pagina dell’ultima release e scarica da lì l’installer:

[Apri la pagina dell’ultima release](https://github.com/itzhaolei/codex-usage-widget/releases/latest)

Decomprimi il file e fai doppio clic su `Install Codex Usage Widget.app`. Codex Desktop deve essere già installato e con accesso effettuato.

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
