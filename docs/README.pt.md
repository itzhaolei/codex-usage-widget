# Quota Bubble

[English](../README.md) | [中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Italiano](README.it.md) | [Nederlands](README.nl.md)

Uma janela flutuante para macOS e Windows que mostra o uso de 5 horas, o uso semanal e as redefinições disponíveis do Codex.

![Quota Bubble preview](../assets/preview-plus.png)

## Recursos

- Mostra o uso de 5 horas, o uso semanal e as redefinições disponíveis do Codex.
- No macOS, mostra a validade de cada redefinição, com ponto vermelho quando expira em até três dias e verde nos demais casos.
- No macOS, mostra localmente a conta atual e o vencimento da assinatura sem salvar credenciais no snapshot de cota.
- Mantém os valores estáveis ao alternar entre o uso ao vivo e o log de sessão local.
- Roda de forma independente e lê dados locais de cota do Codex.
- Lembra posição, tema e estado fixado.
- Um único app SwiftUI gerencia o HUD, o ícone do Dock, os menus e o ciclo de vida.
- Adiciona ações de menu para atualizar, desinstalar e trocar idioma.
- Mostra um pequeno ponto vermelho ao lado da versão quando há uma versão mais recente no GitHub.
- Suporta tema claro e escuro.
- Segue automaticamente o idioma do sistema.

## Instalação

### Método 1: instalador do app

Se você não quiser usar o Terminal, abra a página da versão mais recente e baixe o instalador ali:

[Abrir a página da versão mais recente](https://github.com/itzhaolei/codex-usage-widget/releases/latest)

Descompacte e dê dois cliques em `Install Quota Bubble.app`. O Quota Bubble lê os dados locais de cota do Codex da conta do usuário atual e abre diretamente, sem tela de configuração.
O app para macOS obtém a cota nativamente em Swift. Não exige Node.js, npm, uma instalação separada do Codex CLI, Xcode ou ferramentas de linha de comando; basta macOS 13 ou posterior, Codex conectado com `~/.codex/auth.json` e acesso de rede ao Codex.

O Windows está alinhado com o macOS na v3.0.3. Baixe `QuotaBubble-*-Windows-Setup.exe` na [versão mais recente](https://github.com/itzhaolei/codex-usage-widget/releases/latest) e abra o instalador gráfico com um duplo clique. Não é necessário PowerShell, Node.js, terminal ou runtime .NET separado.

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

Este plugin roda localmente. O app para macOS lê o token atual do Codex em `~/.codex/auth.json` apenas na memória para solicitar ao backend a cota, o saldo, o plano e as redefinições dessa conta. O token nunca é gravado no snapshot e o repositório não contém credenciais pessoais nem dados da conta.
