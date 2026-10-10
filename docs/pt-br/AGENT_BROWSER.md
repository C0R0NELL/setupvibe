# Agent Browser

> Automação de navegador e integração com agentes no Desktop — v0.41.11, adição local do fork

O instalador Desktop Unix adiciona `agent-browser` no passo 14 e passa a limpeza
para o passo 15. O Desktop Windows tem uma etapa própria de automação de
navegador. A CLI, o navegador e a skill oficial ficam preparados para Codex e
Claude Code em todos os projetos. Server e Omarchy não recebem essa etapa.

## Requisitos e instalação por sistema

| Plataforma | Navegador | Requisitos e dependências |
| --- | --- | --- |
| macOS 13+, Intel ou Apple Silicon | Chrome for Testing por `agent-browser install` | Node.js 24 da etapa Homebrew existente; sem bibliotecas Linux ou compilação Rust |
| Windows 11 22H2+, x64 | Chrome for Testing por `agent-browser.cmd install` | Node.js 24 pelo MSI oficial; `agent-browser.cmd` e `skills.cmd` funcionam com políticas PowerShell restritas |
| Ubuntu 24.04+, Debian 12+, Zorin OS 18+, WSL; x86_64 | Chrome for Testing por `agent-browser install` | Node.js 24, bibliotecas APT, fontes, Xvfb/Xauth e Vulkan |
| Os mesmos sistemas Linux; ARM64 | Chromium pelo instalador de navegadores do Playwright | As mesmas dependências APT; sem daemon Snap, Playwright global ou projeto de testes |

O Chrome atual exige macOS 13+. Os outros passos do Desktop Unix continuam
aceitando macOS 12, mas a etapa de navegador informa um erro claro nesse sistema.
Windows em ARM continua fora do suporte do instalador Windows.

O pacote npm oficial exige Node.js 24+. A CLI nativa Rust e o daemon do navegador
não exigem compilar Rust, instalar pnpm ou executar Playwright. O Playwright só
baixa Chromium no Linux ARM64, porque o `agent-browser install` oficial rejeita
essa plataforma. Os downloads ficam em `~/.cache/ms-playwright`. O SetupVibe liga
o diretório informado pelo Playwright a
`~/.agent-browser/browsers/chrome-setupvibe-arm64`, permitindo a descoberta mesmo
quando o layout do cache muda. O pacote temporário do instalador é removido em
caso de sucesso ou falha; a configuração do navegador do usuário é preservada.

A gravação com `agent-browser record` exige FFmpeg no `PATH`. As etapas base do
Desktop já o instalam no Linux e macOS; as utilidades do Windows também o
instalam e validam.

## Dependências Linux e permissões

O instalador usa a lista de bibliotecas oficial de `cli/src/install.rs`,
documentada integralmente no [guia em inglês](../en/AGENT_BROWSER.md). Ela inclui
GTK, X11/XCB, áudio, fontes, Cairo/Pango, NSS/NSPR, D-Bus, CUPS, DRM/GBM e
`libnss3-tools` para certificados.

Depois de atualizar o APT, resolve os nomes `t64` disponíveis, como
`libasound2t64` e `libgtk-3-0t64` no Ubuntu 24.04. Usa `--no-remove` para
interromper caso a instalação exija remover pacotes existentes. Também instala
`fonts-noto-color-emoji`, `fonts-noto-cjk`, `fonts-freefont-ttf`, `xvfb`, `xauth`,
`libvulkan1` e `mesa-vulkan-drivers` para renderização, modo com janela e WebGPU.

Somente bibliotecas de sistema usam `sys_do`. npm, downloads de navegador,
skills e validações executam como `REAL_USER`, inclusive com `sudo bash`.
Pacotes npm globais no Linux ficam em `~/.npm-global`; navegador e skills
pertencem ao usuário-alvo. Reexecuções reaproveitam downloads compatíveis.

## Como os agentes usam

A skill oficial é instalada globalmente pelo Skills CLI existente:

```bash
skills add vercel-labs/agent-browser --skill agent-browser --global --agent codex claude-code --yes
```

Ela orienta o agente a carregar instruções compatíveis com a CLI instalada:

```bash
agent-browser skills get core
agent-browser skills get core --full
agent-browser skills list
```

Não copie o guia de uso de `node_modules`. A skill global fica disponível em
todos os projetos; instruções de cada projeto podem complementar o fluxo.

## Validação e primeiro uso

O instalador verifica a CLI, as instruções incluídas e
`agent-browser doctor --offline`. O diagnóstico abre uma sessão temporária
em `about:blank` e a fecha. Bibliotecas ausentes ou falha na abertura fazem a
etapa falhar. Não inicia dashboard, porta pública ou serviço permanente.

Depois de instalar, abra um terminal novo e execute:

```bash
agent-browser --version
agent-browser doctor --offline
agent-browser open https://example.com
agent-browser snapshot -i
agent-browser screenshot
agent-browser close
```

Use `--headed` para visualizar o navegador. Sem tela no Linux, o Xvfb inicia
automaticamente para esse modo. Gere outro snapshot depois de navegar ou alterar
a página antes de reutilizar referências de elementos. Restrições reais do
sandbox devem ser diagnosticadas; o SetupVibe não desativa o sandbox por padrão.

No Windows, `-Uninstall` remove a CLI npm antes de remover Node.js, preservando
cache de navegadores, sessões, credenciais e skills instaladas.

## Executando este fork

Os comandos do [README do projeto](../../README.md#quick-start) baixam os scripts
diretamente de `C0R0NELL/setupvibe`, branch `main`. Para testar alterações locais,
execute `bash desktop.sh` neste checkout no Unix ou
`powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\desktop.ps1` neste
checkout no Windows. Os comandos remotos incluem as alterações após o push.

## Referências oficiais

- [Instalação do agent-browser](https://agent-browser.dev/installation)
- [Instalador nativo e dependências Linux](https://github.com/vercel-labs/agent-browser/blob/main/cli/src/install.rs)
- [Downloads de navegador do Playwright](https://playwright.dev/docs/browsers)
- [Opções do Skills CLI](https://github.com/vercel-labs/skills#options)
- [Requisitos atuais do Chrome](https://support.google.com/chrome/a/answer/7100626)
