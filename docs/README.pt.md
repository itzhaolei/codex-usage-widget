# Quota Bubble

[English](../README.md) | [中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Italiano](README.it.md) | [Nederlands](README.nl.md)

Uma janela flutuante para macOS que mostra o uso de 5 horas, o uso semanal e as redefinições disponíveis do Codex.

![Quota Bubble preview](../assets/preview.png)

## Recursos

- Mostra o uso de 5 horas, o uso semanal e as redefinições disponíveis do Codex.
- Roda de forma independente e lê dados locais de cota do Codex.
- Lembra posição, tema e estado fixado.
- Mantém apenas um HUD e um lançador no Dock.
- Adiciona ações de menu para atualizar, desinstalar e trocar idioma.
- Mostra um pequeno ponto vermelho ao lado da versão quando há uma versão mais recente no GitHub.
- Suporta tema claro e escuro.
- Segue automaticamente o idioma do sistema.

## Instalação

### Método 1: instalador do app

Se você não quiser usar o Terminal, abra a página da versão mais recente e baixe o instalador ali:

[Abrir a página da versão mais recente](https://github.com/itzhaolei/codex-usage-widget/releases/latest)

Descompacte e dê dois cliques em `Install Quota Bubble.app`. O Codex Desktop deve estar instalado e com login feito.

O README sempre aponta para a página da versão mais recente. Para instalar uma versão antiga, abra [todas as versões](https://github.com/itzhaolei/codex-usage-widget/releases) e baixe o instalador na página da versão desejada.

### Método 2: instalação em uma linha

```bash
CODEX_USAGE_WIDGET_URL=https://github.com/itzhaolei/codex-usage-widget/archive/refs/heads/main.tar.gz bash -c "$(curl -fsSL https://raw.githubusercontent.com/itzhaolei/codex-usage-widget/main/scripts/bootstrap-install.sh)"
```

### Método 3: instalação local

```bash
bash scripts/install.sh
```

## Desinstalar

```bash
bash scripts/uninstall.sh
```

## Privacidade

Este plugin roda localmente. Ele lê metadados locais de sessão do Codex e o token atual do Codex em `~/.codex/auth.json` apenas para solicitar ao backend do Codex as redefinições disponíveis do usuário. Este repositório não contém credenciais pessoais nem dados de conta.
