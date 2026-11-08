# SetupVibe para Omarchy 4

> Camada de desenvolvimento do SetupVibe sobre Omarchy 4 — v0.41.11

`omarchy.sh` configura o SetupVibe em uma instalação Omarchy 4 existente. A
edição reconhece que o Omarchy já entrega o ambiente principal e trabalha por
adição: não remove pacotes, não troca o shell, não apaga aliases e não
sobrescreve os arquivos de configuração do Omarchy.

## Requisitos

- Omarchy 4, branch Quattro, instalado sobre Arch Linux.
- Arquitetura `x86_64`.
- Usuário com acesso a `sudo` para o `pacman` e serviços systemd.
- Terminal interativo, exceto quando `--yes` for usado.
- Node.js 24+ no ambiente do usuário para agent-browser; versões existentes
  continuam gerenciadas pelo Omarchy/mise.

No TryOmarchy para Windows, execute os comandos no terminal Linux dentro da VM.

O script confere `/usr/share/omarchy`, o comando `omarchy`, o pacote instalado
e a versão major 4 antes de alterar qualquer coisa.

## Instalação

```bash
# Execução local
bash omarchy.sh

# Execução local sem confirmação
bash omarchy.sh --yes

# Execução remota pela branch principal
curl -fsSL https://raw.githubusercontent.com/C0R0NELL/setupvibe/main/omarchy.sh | bash

# Execução remota sem confirmação
curl -fsSL https://raw.githubusercontent.com/C0R0NELL/setupvibe/main/omarchy.sh | bash -s -- --yes

# Ver ajuda sem executar a instalação
bash omarchy.sh --help
```

## O que o Omarchy já fornece

A edição não repete os componentes documentados pelo [manual oficial do
Omarchy](https://omarchy.org/manual/). Entre eles estão:

- Bash, Starship, aliases e shell functions do Omarchy.
- Foot, Tmux e a configuração de Tmux do sistema.
- `mise`, Node configurado por mise e o fluxo para outros runtimes.
- Docker, Buildx, Compose, LazyDocker e o grupo `docker`.
- `bat`, `eza`, `fzf`, `fd`, `ripgrep`, `zoxide`, `lazygit`, `tldr`,
  `fastfetch`, `jq` e Neovim.
- Ruby, Herdr, fontes JetBrains Mono Nerd Font e os CLIs de IA instalados
  pelos hooks de usuário do Omarchy, como Codex, Claude, Gemini, Copilot e
  OpenCode.

As referências técnicas são a [lista de pacotes da branch
`quattro`](https://github.com/basecamp/omarchy/blob/quattro/install/omarchy-base.packages)
e os [scripts oficiais de finalização do usuário](https://github.com/basecamp/omarchy/blob/quattro/install/user/all.sh).

## O que o SetupVibe adiciona

O script usa `omarchy pkg add`, que instala somente pacotes ausentes e não
executa `pacman -R`. Os itens adicionados são:

- PHP, Composer, extensões PHP disponíveis no repositório, Laravel Installer e
  Rails sobre o Ruby que já existe.
- Go, Rust, Python, `uv` e `qrcode` com o comando `qr`, somente
  quando o comando ainda não está disponível.
- Node e Bun por mise somente quando ainda faltam; `pnpm` e PM2 pelo npm.
- Ansible, utilitários de rede ausentes e Tailscale quando os pacotes estão
  disponíveis.
- GitHub CLI, Lazygit e Lazydocker quando ausentes, com ícones e aparência
  configurados pelo helper compartilhado. Outros ajustes e o primeiro backup
  são preservados.
- Skills CLI, Kimi Code, Agentlytics, Antigravity CLI e Spec-Kit, sem repetir
  os CLIs já instalados pelo Omarchy. Agentlytics recebe a aprovação limitada
  de `better-sqlite3` e validação do binding em memória.
- [Skill de ambiente](../en/ENVIRONMENT_SKILL.md) atual, distribuída aos dez
  harnesses suportados como no Desktop e Server.
- `ssh_copy_id`, `ecosystem.config.js` e o compose do Portainer em
  `~/.setupvibe/`.
- [agent-browser](../en/AGENT_BROWSER.md), Chrome for Testing e skill oficial
  global para Codex e Claude. Bibliotecas Arch, fontes, Xvfb/Xauth e Vulkan
  usam `omarchy pkg add`; o navegador é validado com `doctor --offline`.
- [Terminal Browser independente](../en/TERMINAL_BROWSER.md), com bibliotecas
  via `omarchy pkg add`, sem plugin do Herdr.
- [Harlequin](../en/HARLEQUIN.md), com os adaptadores
  PostgreSQL e MySQL pelo uv e Python 3.14 em ambiente isolado.
- [Pet e fzf](../en/PET.md): binário oficial do Pet com SHA-256 pelo helper
  compartilhado e `fzf` por `omarchy pkg add`, preservando snippets e configurações.
- [Redis TUI](../en/REDIS_TUI.md), pelo instalador
  oficial no diretório do usuário, preservando conexões salvas.
- [Yazi e ya](../en/YAZI.md) como última instalação, reaproveitando os comandos
  existentes ou usando `omarchy pkg add yazi`, sem modificar configurações.

Os arquivos de configuração adicionados ficam em `~/.config/setupvibe/`:

- `starship.toml`: [configuração Gruvbox Rainbow compartilhada](../../conf/starship.toml) com `user@hostname` por SSH, independente do arquivo do Omarchy. Configurações existentes são preservadas.
- `aliases.bash`: aliases e funções adicionais, carregados depois dos aliases
  do Omarchy e protegidos contra colisões.

O `~/.bashrc` recebe somente um bloco marcado que aponta para esses arquivos.
O `~/.config/starship.toml` do Omarchy e as configurações do Tmux não são
substituídos. O serviço SSH é apenas habilitado quando já existe, sem alteração
do `sshd_config`. O Portainer só é iniciado se o Docker estiver disponível.

Downloads, ferramentas e skills pertencem ao usuário-alvo, inclusive quando
o script é iniciado por `sudo`. O `uv` usa o gerenciador do Omarchy quando
ausente. Os plugins opcionais do Herdr seguem a
[lista de instalação manual](../../README.md#herdr-plugins).

## Validação após a instalação

```bash
bash -n omarchy.sh
source ~/.bashrc
command -v starship
command -v composer
command -v pm2
command -v ssh_copy_id
gh --version
agent-browser doctor --offline
skills list --global
harlequin --version
redis-tui --version
yazi --version
ya --version
docker compose -f ~/.setupvibe/portainer-compose.yml config
```

Abra um novo terminal depois da execução para carregar o bloco adicionado ao
`.bashrc`.

Para validar alterações no instalador sem instalar ferramentas nem alterar
serviços, execute `python3 tests/test_omarchy_integrations.py` no checkout.
Os testes usam configurações temporárias e simulam os gerenciadores e o navegador;
a execução completa em Omarchy/TryOmarchy continua sendo um teste de integração.
