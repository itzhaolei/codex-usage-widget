# Quota Bubble

[English](../README.md) | [中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Italiano](README.it.md) | [Nederlands](README.nl.md)

Uma janela flutuante feita com uma base Flutter/Dart compartilhada para macOS e Windows que mostra cota de 5 horas do Codex, cota semanal, redefinição, saldo, plano, conta e redefinições disponíveis.

![Quota Bubble 4.0 preview](../assets/preview-v4.png?raw=1&v=20260926-4)

## Recursos

- Mostra a cota de 5 horas quando existe, além da cota semanal do Codex, redefinição, saldo, plano e redefinições disponíveis.
- Mostra um selo Free, Plus, Pro 5x/20x, Business, Business 5x/20x, Enterprise ou Edu conforme o plano informado pela conta.
- Mostra após a contagem regressiva a data exata da redefinição semanal e o dia da semana no horário local, com precisão de segundos.
- Mostra na barra de menus do macOS e na dica da bandeja do Windows a porcentagem de 5 horas quando existe; caso contrário, mostra a porcentagem semanal.
- Fechar oculta a janela e pausa sua renderização; a porcentagem continua sendo atualizada na barra de menus do macOS ou na dica da bandeja do Windows. Use o menu da barra ou da bandeja para sair.
- No macOS e no Windows, mostra a validade de cada redefinição, com ponto vermelho quando expira em até três dias e verde nos demais casos.
- No macOS e no Windows, mostra localmente a conta atual e o vencimento da assinatura sem salvar credenciais no snapshot de cota.
- Mostra o armazenamento do sistema e a memória física disponíveis; no Windows, exibe o espaço livre da unidade C.
- Mantém os valores de cota ao vivo estáveis e impede a exibição de dados da conta anterior após a troca de conta.
- Funciona de forma independente do Codex Desktop, lê o login local e solicita os dados atuais de cota ao backend do Codex.
- Lembra posição, tema e estado fixado.
- Uma base Flutter compartilhada gerencia o HUD, o ícone do Dock ou da bandeja, os menus e o ciclo de vida no macOS e no Windows.
- Limita o app a uma instância e uma janela de cota, que pode ser restaurada pela barra de menus ou bandeja do sistema depois de ocultada.
- Mantém a entrada na barra de tarefas do Windows e usa o nível de janela da barra de status quando fixado no macOS.
- Usa o mesmo conjunto de ícones vetoriais no estilo macOS nas duas plataformas.
- Adiciona ações na barra de menus ou na bandeja do sistema para atualizar, abrir o site oficial e compartilhar, desinstalar e trocar o idioma.
- Mostra um pequeno ponto vermelho ao lado da versão quando há uma versão mais recente no GitHub.
- Suporta tema claro e escuro.
- Segue automaticamente o idioma do sistema.

## Instalação

Abra o [site oficial do Quota Bubble](https://htmlpreview.github.io/?https://github.com/itzhaolei/codex-usage-widget/blob/main/public/index.html?v=20260926-4) e clique no botão principal. O site detecta macOS ou Windows e baixa diretamente o instalador gráfico mais recente sem abrir a página Releases.

### macOS

macOS 13 ou posterior. Descompacte `macOS-Installer.zip` e abra `Install Quota Bubble.app`. Não exige Node.js, npm, Codex CLI separado, Xcode ou comandos. O Codex deve estar conectado e ter criado `~/.codex/auth.json`.

### Windows

Windows 10 ou posterior. Abra `Windows-Setup.exe` e siga o assistente gráfico. Após a instalação, um atalho do Quota Bubble é criado automaticamente na área de trabalho. Não exige PowerShell, Node.js, terminal ou runtime .NET separado.

## Desinstalar

No macOS, abra o menu Quota Bubble na barra de menus e escolha **Desinstalar**. No Windows use **Configurações > Aplicativos > Aplicativos instalados**.

## Privacidade

Este plugin roda localmente. O app para desktop lê o token atual do Codex em `~/.codex/auth.json` apenas na memória para solicitar ao backend a cota, o saldo, o plano e as redefinições dessa conta. O token nunca é gravado no snapshot e o repositório não contém credenciais pessoais nem dados da conta.
