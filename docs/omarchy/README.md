# SetupVibe para Omarchy 4

> Camada de desenvolvimento da Promovaweb sobre Omarchy 4 — v0.41.10

`omarchy.sh` configura o SetupVibe em uma instalação Omarchy 4 existente. A
edição reconhece que o Omarchy já entrega o ambiente principal e trabalha por
adição: não remove pacotes, não troca o shell, não apaga aliases e não
sobrescreve os arquivos de configuração do Omarchy.

## Requisitos

- Omarchy 4, branch Quattro, instalado sobre Arch Linux.
- Arquitetura `x86_64`.
- Usuário com acesso a `sudo` para o `pacman` e serviços systemd.
- Terminal interativo, exceto quando `--yes` for usado.

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
- Skills CLI, Kimi Code, Agentlytics, Antigravity CLI e Spec-Kit, sem repetir
  os CLIs já instalados pelo Omarchy.
- `ssh_copy_id`, `ecosystem.config.js` e o compose do Portainer em
  `~/.setupvibe/`.
- [Terminal Browser independente](../en/TERMINAL_BROWSER.md), com bibliotecas
  via `omarchy pkg add`, sem plugin do Herdr.
- [Harlequin](../en/HARLEQUIN.md), com os adaptadores
  PostgreSQL e MySQL pelo uv e Python 3.14 em ambiente isolado.
- [Pet e fzf](../en/PET.md), por `omarchy pkg add pet-bin fzf`,
  preservando snippets e configurações existentes.
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

## Validação após a instalação

```bash
bash -n omarchy.sh
source ~/.bashrc
command -v starship
command -v composer
command -v pm2
command -v ssh_copy_id
docker compose -f ~/.setupvibe/portainer-compose.yml config
```

Abra um novo terminal depois da execução para carregar o bloco adicionado ao
`.bashrc`.
