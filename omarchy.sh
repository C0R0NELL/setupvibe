#!/usr/bin/env bash

set -Eeuo pipefail

# SetupVibe para Omarchy 4 (Quattro)
#
# Esta edição adiciona a camada da Promovaweb a uma instalação existente do
# Omarchy. O sistema continua responsável pelos componentes que já fornece:
# shell Bash, Starship, mise, Tmux, Docker, ferramentas Unix, fontes, aliases,
# funções, Neovim, Herdr e CLIs de IA.

VERSION="0.41.11"
OMARCHY_MAJOR="4"
SETUPVIBE_RAW="https://raw.githubusercontent.com/C0R0NELL/setupvibe/main"

BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ASSUME_YES=false
REPAIR_ONLY=false

die() {
    echo -e "${RED}Erro: $*${NC}" >&2
    exit 1
}

warn() {
    echo -e "${YELLOW}Aviso: $*${NC}" >&2
}

usage() {
    cat <<'EOF'
Uso: bash omarchy.sh [opção]

Instala a camada SetupVibe sobre uma instalação Omarchy 4 existente.

Opções:
  --yes     Não pede confirmação no início.
  --repair  Repara somente PHP ZIP, Ruby/Rails e Docker/Portainer.
  --help    Exibe esta ajuda.
EOF
}

user_do() {
    if [[ "$(id -u)" -eq 0 && -n "${REAL_USER:-}" && "$REAL_USER" != root ]]; then
        sudo -u "$REAL_USER" -H env PATH="$PATH" "$@"
    else
        "$@"
    fi
}

sys_do() {
    if [[ "$(id -u)" -eq 0 ]]; then
        "$@"
    else
        sudo "$@"
    fi
}

path_prepend_once() {
    local directory=$1
    case ":$PATH:" in
        *":$directory:"*) ;;
        *) PATH="$directory:$PATH" ;;
    esac
}

detect_user() {
    if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != root ]]; then
        REAL_USER="$SUDO_USER"
    elif [[ "$(id -u)" -eq 0 ]]; then
        REAL_USER="$(logname 2>/dev/null || true)"
        [[ -z "$REAL_USER" || "$REAL_USER" == root ]] && REAL_USER="$(whoami)"
    else
        REAL_USER="$(whoami)"
    fi

    REAL_HOME="$(getent passwd "$REAL_USER" 2>/dev/null | cut -d: -f6 || true)"
    [[ -z "$REAL_HOME" ]] && REAL_HOME="${HOME:-}"
    [[ -z "$REAL_HOME" || "$REAL_HOME" == /root && "$REAL_USER" != root ]] &&
        die "Não foi possível descobrir o diretório pessoal de $REAL_USER."
    REAL_GROUP="$(id -gn "$REAL_USER" 2>/dev/null || printf '%s' "$REAL_USER")"
}

check_omarchy() {
    [[ "$(uname -s)" == Linux ]] || die "omarchy.sh só pode ser executado no Linux."
    [[ "$(uname -m)" == x86_64 ]] || die "Omarchy 4 nesta edição exige a arquitetura x86_64."
    command -v pacman >/dev/null 2>&1 || die "O pacman não foi encontrado."
    [[ -d /usr/share/omarchy ]] || die "Esta máquina não parece ter o Omarchy instalado."
    command -v omarchy >/dev/null 2>&1 || die "O comando omarchy não foi encontrado."

    local package_version
    package_version="$(pacman -Q omarchy 2>/dev/null | awk '{print $2}' || true)"
    [[ "$package_version" == ${OMARCHY_MAJOR}.* || "$package_version" == ${OMARCHY_MAJOR}-* ]] ||
        die "Omarchy 4 não foi detectado (versão encontrada: ${package_version:-desconhecida})."
}

confirm_installation() {
    $ASSUME_YES && return 0
    [[ -t 0 || -r /dev/tty ]] || die "Use --yes quando não houver um terminal interativo."

    echo -e "${BOLD}SetupVibe Omarchy ${OMARCHY_MAJOR} v${VERSION}${NC}"
    if $REPAIR_ONLY; then
        echo "O reparo verifica PHP ZIP, Ruby/Rails e Docker/Portainer."
    else
        echo "A instalação adicionará ferramentas e configurações do SetupVibe."
    fi
    echo "Ela não remove pacotes, arquivos do Omarchy, aliases existentes ou configurações existentes."
    echo ""
    printf 'Pressione ENTER para continuar ou digite q para cancelar: '
    local answer
    read -r answer </dev/tty || die "A entrada interativa ficou indisponível."
    [[ "$answer" != q && "$answer" != Q ]] || exit 0
}

omarchy_pkg_add() {
    local -a packages=("$@")
    ((${#packages[@]})) || return 0

    if command -v omarchy-pkg-add >/dev/null 2>&1; then
        user_do omarchy-pkg-add "${packages[@]}"
    else
        user_do omarchy pkg add "${packages[@]}"
    fi
}

omarchy_pkg_add_optional() {
    local package
    for package in "$@"; do
        if omarchy_pkg_add "$package"; then
            echo -e "${GREEN}✔ Pacote disponível: $package${NC}"
        else
            warn "O pacote opcional $package não foi instalado; o restante continuará."
        fi
    done
}

ensure_mise_tool() {
    local package=$1
    local command_name=${2:-$1}
    path_prepend_once "$REAL_HOME/.local/share/mise/shims"
    path_prepend_once "$REAL_HOME/.local/bin"
    export PATH

    if ! user_do bash -lc "command -v '$command_name' >/dev/null 2>&1"; then
        echo "Instalando $package via mise..."
        user_do mise use -g "$package"
    else
        echo "$command_name já está disponível; mantendo a instalação do Omarchy."
    fi
    hash -r 2>/dev/null || true
}

safe_download() (
    local url=$1
    local destination=$2
    local minimum_size=${3:-100}
    local temporary_file
    local destination_dir

    temporary_file="$(user_do mktemp)" || return 1
    trap 'user_do rm -f -- "$temporary_file"' EXIT
    if ! user_do curl --proto '=https' --proto-redir '=https' --tlsv1.2 --fail --silent --show-error \
        --location --retry 3 --retry-all-errors --connect-timeout 10 \
        --max-time 120 --output "$temporary_file" "$url"; then
        return 1
    fi

    if (( $(wc -c < "$temporary_file") < minimum_size )); then
        return 1
    fi

    if head -c 200 "$temporary_file" | grep -qiE '<!doctype|<html'; then
        return 1
    fi

    destination_dir="$(dirname "$destination")"
    user_do mkdir -p "$destination_dir" || return 1
    user_do install -m 0644 "$temporary_file" "$destination"
)

download_if_missing() {
    local url=$1
    local destination=$2
    local minimum_size=${3:-100}

    if [[ -f "$destination" ]]; then
        echo "$(basename "$destination") já existe; mantendo o arquivo local."
        return 0
    fi

    safe_download "$url" "$destination" "$minimum_size"
}

install_setupvibe_files() {
    echo "Adicionando arquivos auxiliares do SetupVibe..."
    user_do mkdir -p "$REAL_HOME/.setupvibe/bin"
    download_if_missing "$SETUPVIBE_RAW/bin/ssh_copy_id" \
        "$REAL_HOME/.setupvibe/bin/ssh_copy_id" 500
    user_do chmod 0755 "$REAL_HOME/.setupvibe/bin/ssh_copy_id"

    download_if_missing "$SETUPVIBE_RAW/conf/ecosystem.config.js" \
        "$REAL_HOME/.setupvibe/ecosystem.config.js" 100
    download_if_missing "$SETUPVIBE_RAW/conf/portainer-compose.yml" \
        "$REAL_HOME/.setupvibe/portainer-compose.yml" 100
    sys_do chown -R "$REAL_USER:$REAL_GROUP" "$REAL_HOME/.setupvibe"
}

install_additional_packages() {
    # O Omarchy 4 já entrega Docker, Tmux, Starship, Ruby, mise, Node via mise,
    # ferramentas Unix, Neovim, fontes, Herdr, gh e os CLIs de IA principais.
    # Esta lista contém somente a camada que o SetupVibe ainda acrescenta.
    echo "Adicionando runtimes e ferramentas ausentes do Omarchy..."
    omarchy_pkg_add php composer go rust python python-pip ansible github-cli lazygit lazydocker

    # Extensões PHP e utilitários de rede variam entre os repositórios Arch.
    # Cada item é independente para manter o restante da instalação disponível.
    omarchy_pkg_add_optional \
        php-gd php-pgsql php-sqlite \
        rsync bind mtr nmap tcpdump iftop nload iotop sysstat glances htop \
        tailscale
}

configure_php_zip() (
    local scan_dir
    local temporary_file
    local zip_ini=/etc/php/conf.d/99-setupvibe-zip.ini

    if user_do php -r 'exit(extension_loaded("zip") ? 0 : 1);'; then
        echo "Extensão ZIP do PHP já está ativa."
        return 0
    fi
    # Arch ships zip.so in php itself; php-zip is not a repository package.
    scan_dir=$(user_do php -r 'echo PHP_CONFIG_FILE_SCAN_DIR;')
    [[ "$scan_dir" == /etc/php/conf.d ]] ||
        die "ZIP está desativado em um PHP personalizado. Habilite-o no gerenciador desse PHP."
    user_do php -n -d extension=zip -r 'exit(extension_loaded("zip") ? 0 : 1);' ||
        die "O PHP instalado não conseguiu carregar zip.so."
    if sys_do test -e "$zip_ini"; then
        die "ZIP continua desativado; revise $zip_ini e PHP_INI_SCAN_DIR."
    fi
    user_do mkdir -p "$REAL_HOME/.setupvibe/tmp"
    temporary_file=$(user_do mktemp "$REAL_HOME/.setupvibe/tmp/php-zip.XXXXXX")
    trap 'user_do rm -f -- "$temporary_file"' EXIT
    printf '%s\n' '; Managed by SetupVibe' 'extension=zip' | user_do tee "$temporary_file" >/dev/null
    sys_do mkdir -p "$scan_dir"
    sys_do install -o root -g root -m 0644 "$temporary_file" "$zip_ini"
    user_do php -r 'exit(extension_loaded("zip") ? 0 : 1);' ||
        die "O PHP não carregou $zip_ini; confira a configuração exibida por php --ini."
    echo "Extensão ZIP do PHP ativada."
)

configure_rails() {
    local ruby_bindir
    path_prepend_once "$REAL_HOME/.local/bin"
    export PATH

    if ! command -v ruby >/dev/null 2>&1; then
        omarchy_pkg_add ruby rubygems ruby-stdlib
    fi
    user_do ruby --version
    ruby_bindir=$(user_do ruby -rrbconfig -e 'print RbConfig::CONFIG["bindir"]')
    if [[ "$ruby_bindir" == /usr/bin ]]; then
        omarchy_pkg_add rubygems ruby-stdlib
    elif ! user_do gem --version >/dev/null 2>&1; then
        if [[ -x "$ruby_bindir/gem" ]]; then
            path_prepend_once "$ruby_bindir"
            export PATH
            if [[ "$ruby_bindir" == "$REAL_HOME"/.local/share/mise/installs/ruby/*/bin ]]; then
                user_do mise reshim
            fi
        else
            die "Ruby ativo em $ruby_bindir está sem RubyGems. Repare esse Ruby no seu gerenciador."
        fi
    fi
    user_do gem --version
    if ! user_do rails --version >/dev/null 2>&1 || ! user_do bundle --version >/dev/null 2>&1; then
        user_do mkdir -p "$REAL_HOME/.local/bin"
        user_do gem install bundler rails --user-install --bindir "$REAL_HOME/.local/bin" --no-document
    fi
    user_do rails --version
    user_do bundle --version
}

configure_php_and_rails() {
    export COMPOSER_HOME="$REAL_HOME/.config/composer"
    path_prepend_once "$REAL_HOME/.local/bin"
    path_prepend_once "$COMPOSER_HOME/vendor/bin"
    export PATH

    configure_php_zip
    echo "Configurando Composer e Laravel..."
    if command -v composer >/dev/null 2>&1; then
        user_do env COMPOSER_HOME="$COMPOSER_HOME" composer global require laravel/installer
    else
        warn "Composer não ficou disponível; Laravel será ignorado nesta execução."
    fi

    echo "Configurando Rails sobre o Ruby já fornecido pelo Omarchy..."
    configure_rails
}

configure_python_go_rust() {
    path_prepend_once "$REAL_HOME/.local/bin"
    export PATH
    if ! user_do bash -lc "command -v uv >/dev/null 2>&1"; then
        omarchy_pkg_add uv
    fi
    hash -r 2>/dev/null || true

    if ! user_do bash -lc "command -v qr >/dev/null 2>&1"; then
        user_do uv tool install --upgrade qrcode
    fi

    # O pacote do sistema continua sendo a base dos runtimes. mise só entra
    # quando o comando ainda não existe, sem substituir o que o Omarchy criou.
    ensure_mise_tool go go
    ensure_mise_tool python python
    ensure_mise_tool rust rustc
}

configure_javascript() {
    ensure_mise_tool node node
    ensure_mise_tool bun bun

    if ! command -v npm >/dev/null 2>&1; then
        die "Node foi configurado, mas npm não está disponível."
    fi

    user_do npm install --global pnpm pm2
    user_do pnpm --version >/dev/null
    user_do pm2 --version >/dev/null
}

install_optional_ai_tools() {
    local -a packages=(
        "skills@latest"
        "@moonshot-ai/kimi-code"
        "agentlytics"
    )
    local -a commands=(skills kimi agentlytics)
    local -a allowed_scripts=(skills @moonshot-ai/kimi-code better-sqlite3)
    local index

    echo "Adicionando apenas os CLIs de IA que o Omarchy não fornece..."
    for index in "${!packages[@]}"; do
        if [[ "${commands[$index]}" != agentlytics ]] &&
            user_do bash -lc "command -v '${commands[$index]}' >/dev/null 2>&1"; then
            echo "${commands[$index]} já está disponível; mantendo o comando existente."
        else
            user_do npm install --global --allow-scripts="${allowed_scripts[$index]}" "${packages[$index]}"
        fi
    done
    local npm_root
    npm_root=$(user_do npm root --global)
    user_do env AGENTLYTICS_ROOT="$npm_root/agentlytics" node -e \
        'const Database = require(process.env.AGENTLYTICS_ROOT + "/node_modules/better-sqlite3"); const db = new Database(":memory:"); db.close();'

    if ! user_do bash -lc "command -v specify >/dev/null 2>&1"; then
        user_do uv tool install --upgrade specify-cli
    fi

    if ! user_do bash -lc "command -v agy >/dev/null 2>&1"; then
        install_antigravity
    fi
}

install_antigravity() {
    local platform="linux_amd64"
    local base_url="https://antigravity-cli-auto-updater-974169037036.us-central1.run.app"
    local temporary_dir manifest payload download_url expected_sha512 actual_sha512
    local archive=false

    temporary_dir="$(user_do mktemp -d "$REAL_HOME/.setupvibe/antigravity.XXXXXX")"
    manifest="$temporary_dir/manifest.json"
    payload="$temporary_dir/agy"

    safe_download "$base_url/manifests/${platform}.json" "$manifest" 100 || {
        warn "O manifesto do Antigravity não pôde ser baixado."
        user_do rm -rf -- "$temporary_dir"
        return 0
    }

    download_url="$(jq -er '.url | select(startswith("https://storage.googleapis.com/antigravity-public/"))' "$manifest")" || {
        warn "O manifesto do Antigravity não apresentou um download confiável."
        user_do rm -rf -- "$temporary_dir"
        return 0
    }
    expected_sha512="$(jq -er '.sha512' "$manifest")" || {
        warn "O manifesto do Antigravity não apresentou checksum."
        user_do rm -rf -- "$temporary_dir"
        return 0
    }

    case "$download_url" in
        *.tar.gz*)
            archive=true
            payload="$temporary_dir/agy.tar.gz"
            ;;
    esac

    safe_download "$download_url" "$payload" 1000000 || {
        warn "O binário do Antigravity não pôde ser baixado."
        user_do rm -rf -- "$temporary_dir"
        return 0
    }

    actual_sha512="$(sha512sum "$payload" | awk '{print $1}')"
    [[ "$actual_sha512" == "$expected_sha512" ]] || {
        warn "O checksum do Antigravity não confere."
        user_do rm -rf -- "$temporary_dir"
        return 0
    }

    if $archive; then
        user_do tar -xzf "$payload" -C "$temporary_dir" antigravity
        payload="$temporary_dir/antigravity"
    fi

    user_do install -m 0755 "$payload" "$REAL_HOME/.local/bin/agy"
    user_do rm -rf -- "$temporary_dir"
    user_do env PATH="$REAL_HOME/.local/bin:$PATH" agy install --skip-aliases --skip-path
}

write_starship_config() {
    local setupvibe_dir="$REAL_HOME/.config/setupvibe"
    local starship_config="$setupvibe_dir/starship.toml"
    local config_source=""

    user_do mkdir -p "$setupvibe_dir"
    if [[ ! -f "$starship_config" ]]; then
        if [[ -f "${BASH_SOURCE[0]}" ]]; then
            config_source="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/conf/starship.toml"
        fi
        if [[ -f "$config_source" ]]; then
            user_do install -m 0644 "$config_source" "$starship_config"
        else
            safe_download "$SETUPVIBE_RAW/conf/starship.toml" "$starship_config"
        fi
        user_do sed -i 's/╭/┌/g; s/╰/└/g' "$starship_config"
    else
        echo "Configuração Starship do SetupVibe já existe; mantendo personalizações."
    fi
}

write_aliases() {
    local setupvibe_dir="$REAL_HOME/.config/setupvibe"
    local aliases_file="$setupvibe_dir/aliases.bash"

    user_do mkdir -p "$setupvibe_dir"
    [[ -f "$aliases_file" ]] && return 0

    user_do tee "$aliases_file" >/dev/null <<'EOF'
# Aliases adicionais do SetupVibe para Omarchy. Os aliases do Omarchy ficam intactos.

alias_if_missing() {
    alias "$1" >/dev/null 2>&1 || alias "$1=$2"
}

alias_if_missing dc 'docker compose'
alias_if_missing dps 'docker ps'
alias_if_missing dpsa 'docker ps -a'
alias_if_missing dimg 'docker images'
alias_if_missing dlog 'docker logs -f'
alias_if_missing dex 'docker exec -it'
alias_if_missing dcup 'docker compose up -d'
alias_if_missing dcdown 'docker compose down'
alias_if_missing p 'pm2'
alias_if_missing pl 'pm2 list'
alias_if_missing psave 'pm2 save'
alias_if_missing pres 'pm2 resurrect'
alias_if_missing gcm 'git commit -m'
alias_if_missing gcam 'git commit -a -m'
alias_if_missing gl 'git log --oneline --graph --decorate'
alias_if_missing sv-pkg 'omarchy pkg add'
alias_if_missing sv-php 'php -v'
alias_if_missing sv-rails 'rails -v'
alias_if_missing sv-qr 'qr'
alias_if_missing sv-pm2 'pm2'
alias_if_missing sv-portainer 'docker compose -f "$HOME/.setupvibe/portainer-compose.yml"'
alias_if_missing ssh_copy_id '"$HOME/.setupvibe/bin/ssh_copy_id"'

sv-portainer-start() {
    docker compose -f "$HOME/.setupvibe/portainer-compose.yml" up -d
}

sv-portainer-stop() {
    docker compose -f "$HOME/.setupvibe/portainer-compose.yml" stop
}

sv-portainer-logs() {
    docker compose -f "$HOME/.setupvibe/portainer-compose.yml" logs -f
}

unset -f alias_if_missing
EOF
    user_do chmod 0644 "$aliases_file"
}

append_shell_integration() {
    local bashrc="$REAL_HOME/.bashrc"
    local marker_begin="# >>> SetupVibe Omarchy ${OMARCHY_MAJOR} >>>"

    user_do touch "$bashrc"
    if grep -Fq "$marker_begin" "$bashrc"; then
        return 0
    fi

    user_do tee -a "$bashrc" >/dev/null <<'EOF'

# >>> SetupVibe Omarchy 4 >>>
# Este bloco é aditivo. O .bashrc e a inicialização do Omarchy permanecem acima.
export SETUPVIBE_CONFIG_DIR="${SETUPVIBE_CONFIG_DIR:-$HOME/.config/setupvibe}"
export STARSHIP_CONFIG="$SETUPVIBE_CONFIG_DIR/starship.toml"
export COMPOSER_HOME="${COMPOSER_HOME:-$HOME/.config/composer}"
export PATH="$HOME/.local/bin:$COMPOSER_HOME/vendor/bin:$PATH"

if [[ -r "$SETUPVIBE_CONFIG_DIR/aliases.bash" ]]; then
  source "$SETUPVIBE_CONFIG_DIR/aliases.bash"
fi

if [[ $- == *i* ]] && [[ ${TERM:-} != dumb ]] && command -v starship >/dev/null 2>&1; then
  eval "$(starship init bash)"
fi
# <<< SetupVibe Omarchy 4 <<<
EOF

}

configure_portainer() {
    local endpoint
    local -a docker_command
    if ! command -v docker >/dev/null 2>&1; then
        omarchy_pkg_add docker docker-compose docker-buildx
    fi
    if [[ -n "${DOCKER_CONTEXT:-}" ]]; then
        endpoint=$(user_do docker context inspect "$DOCKER_CONTEXT" --format '{{.Endpoints.docker.Host}}')
    elif [[ -n "${DOCKER_HOST:-}" ]]; then
        endpoint=$DOCKER_HOST
    else
        endpoint=$(user_do docker context inspect --format '{{.Endpoints.docker.Host}}')
    fi
    [[ "$endpoint" == unix:///* ]] ||
        die "O contexto Docker aponta para $endpoint. Selecione um contexto local para configurar o Portainer."
    docker_command=(user_do env -u DOCKER_HOST -u DOCKER_CONTEXT docker --host "$endpoint")
    if ! "${docker_command[@]}" info >/dev/null 2>&1; then
        [[ "$endpoint" == unix:///var/run/docker.sock || "$endpoint" == unix:///run/docker.sock ]] ||
            die "Docker local indisponível em $endpoint. Inicie esse daemon antes de configurar o Portainer."
        sys_do systemctl enable --now docker
        sys_do env -u DOCKER_HOST -u DOCKER_CONTEXT docker --host "$endpoint" info >/dev/null ||
            die "Docker não iniciou. Consulte: journalctl -u docker -n 50 --no-pager"
        if [[ "$REAL_USER" != root ]] && ! "${docker_command[@]}" info >/dev/null 2>&1; then
            getent group docker >/dev/null || sys_do groupadd --system docker
            if [[ " $(id -nG "$REAL_USER") " != *" docker "* ]]; then
                sys_do usermod -aG docker "$REAL_USER"
            fi
            # Refresh supplementary groups only for these child commands.
            docker_command=(sudo -u "$REAL_USER" -H env -u DOCKER_HOST -u DOCKER_CONTEXT PATH="$PATH" docker --host "$endpoint")
            echo "Para usar Docker neste terminal depois, execute: newgrp docker"
        fi
        "${docker_command[@]}" info >/dev/null || die "O usuário $REAL_USER ainda não consegue acessar o Docker."
    fi
    if ! "${docker_command[@]}" compose version >/dev/null 2>&1; then
        omarchy_pkg_add docker-compose
    fi
    user_do mkdir -p "$REAL_HOME/.setupvibe/portainer_data"
    download_if_missing "$SETUPVIBE_RAW/conf/portainer-compose.yml" \
        "$REAL_HOME/.setupvibe/portainer-compose.yml" 100
    "${docker_command[@]}" compose -f "$REAL_HOME/.setupvibe/portainer-compose.yml" up -d
}

configure_tailscale() {
    if ! command -v tailscale >/dev/null 2>&1; then
        return 0
    fi

    if sys_do systemctl enable --now tailscaled; then
        tailscale version >/dev/null
    else
        warn "O serviço tailscaled não pôde ser habilitado agora."
    fi
}

configure_ssh() {
    if ! command -v sshd >/dev/null 2>&1; then
        return 0
    fi

    # O Omarchy já administra firewall e segurança. Apenas garantimos que o
    # serviço existente possa ser usado, sem reescrever sshd_config.
    sys_do systemctl enable --now sshd 2>/dev/null ||
        sys_do systemctl enable --now ssh 2>/dev/null || true
}

install_setupvibe_helper() {
    local helper_name=$1
    local helper_path="$REAL_HOME/.setupvibe/bin/$helper_name"
    local helper_source=""

    if [[ -f "${BASH_SOURCE[0]}" ]]; then
        helper_source="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/utils/$helper_name"
    fi
    if [[ -f "$helper_source" ]]; then
        user_do mkdir -p "$(dirname -- "$helper_path")"
        user_do install -m 0644 "$helper_source" "$helper_path"
    else
        safe_download "$SETUPVIBE_RAW/utils/$helper_name" "$helper_path"
    fi
}

configure_lazy_ui() {
    install_setupvibe_helper configure_lazy_ui.py
    user_do python3 "$REAL_HOME/.setupvibe/bin/configure_lazy_ui.py"
}

install_environment_skill() {
    local skill_source="$SETUPVIBE_RAW/skills/setupvibe-environment/SKILL.md"
    local repo_root=""
    local npm_root

    if [[ -f "${BASH_SOURCE[0]}" ]]; then
        repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
        if [[ -f "$repo_root/skills/setupvibe-environment/SKILL.md" ]]; then
            skill_source="$repo_root/skills/setupvibe-environment"
        fi
    fi
    npm_root=$(user_do npm root --global)
    install_setupvibe_helper install_environment_skill.mjs
    user_do node "$REAL_HOME/.setupvibe/bin/install_environment_skill.mjs" \
        --skills-package "$npm_root/skills" --source "$skill_source"
}

install_agent_browser() {
    local npm_prefix
    user_do node -e 'if (Number(process.versions.node.split(".")[0]) < 24) { console.error("agent-browser requires Node.js 24+. Update Node through Omarchy/mise."); process.exit(1); }'
    npm_prefix=$(user_do npm config get prefix)
    [[ "$npm_prefix" == /* ]] || die "O npm não retornou um prefixo absoluto."
    path_prepend_once "$npm_prefix/bin"
    export PATH

    # Use Arch libraries rather than the upstream installer's APT-only --with-deps.
    omarchy_pkg_add \
        alsa-lib at-spi2-core cairo dbus expat fontconfig freetype2 gtk3 \
        libcups libdrm libx11 libxcb libxcomposite libxcursor libxdamage \
        libxext libxfixes libxi libxrandr libxrender libxshmfence libxkbcommon \
        mesa nspr nss pango noto-fonts-cjk noto-fonts-emoji ttf-liberation \
        xorg-server-xvfb xorg-xauth vulkan-icd-loader vulkan-swrast ffmpeg
    user_do npm install --global --allow-scripts=agent-browser agent-browser@latest
    user_do agent-browser --version
    user_do agent-browser install
    user_do skills add vercel-labs/agent-browser --skill agent-browser \
        --global --agent codex claude-code --yes
    user_do agent-browser skills get core >/dev/null
    user_do agent-browser doctor --offline
}

install_terminal_browser() {
    install_setupvibe_helper install_terminal_browser.sh
    # shellcheck source=utils/install_terminal_browser.sh
    source "$REAL_HOME/.setupvibe/bin/install_terminal_browser.sh"
    setupvibe_install_terminal_browser
}

install_harlequin() {
    local helper_dir="$REAL_HOME/.setupvibe/bin"
    local helper_name

    for helper_name in install_harlequin.sh validate_harlequin.py; do
        install_setupvibe_helper "$helper_name"
    done
    # shellcheck source=utils/install_harlequin.sh
    source "$helper_dir/install_harlequin.sh"
    setupvibe_install_harlequin "$helper_dir/validate_harlequin.py"
}

install_pet() {
    omarchy_pkg_add fzf
    install_setupvibe_helper install_pet.mjs
    user_do node "$REAL_HOME/.setupvibe/bin/install_pet.mjs" --bin-dir "$REAL_HOME/.local/bin"
}

install_redis_tui() {
    install_setupvibe_helper install_redis_tui.sh
    # shellcheck source=utils/install_redis_tui.sh
    source "$REAL_HOME/.setupvibe/bin/install_redis_tui.sh"
    setupvibe_install_redis_tui
}

install_yazi() {
    if ! command -v yazi >/dev/null 2>&1 || ! command -v ya >/dev/null 2>&1; then
        omarchy_pkg_add yazi
    fi
    user_do env PATH="$PATH" yazi --version
    user_do env PATH="$PATH" ya --version
}

main() {
    local arg
    for arg in "$@"; do
        case "$arg" in
            --yes) ASSUME_YES=true ;;
            --repair) REPAIR_ONLY=true ;;
            --help|-h) usage; return 0 ;;
            *) die "Opção desconhecida: $arg" ;;
        esac
    done

    detect_user
    check_omarchy
    path_prepend_once "$REAL_HOME/.local/share/mise/shims"
    path_prepend_once "$REAL_HOME/.local/bin"
    export PATH
    confirm_installation

    if $REPAIR_ONLY; then
        configure_php_zip
        configure_rails
        configure_portainer
        echo "Reparo de PHP ZIP, Ruby/Rails e Docker/Portainer concluído."
        return 0
    fi

    install_additional_packages
    install_setupvibe_files
    configure_php_and_rails
    configure_python_go_rust
    configure_javascript
    configure_lazy_ui
    install_optional_ai_tools
    install_environment_skill
    write_starship_config
    write_aliases
    append_shell_integration
    configure_portainer
    configure_tailscale
    configure_ssh
    install_agent_browser
    install_terminal_browser
    install_harlequin
    install_pet
    install_redis_tui
    install_yazi

    echo ""
    echo -e "${GREEN}${BOLD}SetupVibe Omarchy ${OMARCHY_MAJOR} concluído.${NC}"
    echo "Abra um novo terminal ou execute: source ~/.bashrc"
    echo "Arquivos adicionados em ~/.config/setupvibe e ~/.setupvibe."
}

# Prompts read /dev/tty; automated tools must not consume the installer stream.
main "$@" </dev/null
