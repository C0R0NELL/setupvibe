# DEBIAN.md — Contexto Linux e validação dos instaladores

Este arquivo registra o contexto operacional do SetupVibe em Debian, os padrões
de implementação dos scripts Unix e o procedimento de teste em containers.

## Regra de uso

Este é um contexto obrigatório para trabalhos que alterem, investiguem ou
testem `desktop.sh`, `server.sh`, arquivos de `conf/` usados no Linux ou a
documentação Linux.

Antes de atuar nesse escopo:

1. Leia `AGENTS.md` ou `CLAUDE.md`, conforme o agente em uso.
2. Leia este arquivo por completo.
3. Preserve as diferenças entre Desktop e Server descritas aqui.
4. Atualize este arquivo quando um teste real revelar uma nova limitação,
   causa raiz ou exigência de validação do Linux.

`AGENTS.md` e `CLAUDE.md` continuam sendo os contextos primários dos agentes.
Este arquivo é um contexto técnico suplementar da plataforma, não o contexto de
um terceiro agente.

## Escopo Linux do projeto

O SetupVibe oferece duas edições Unix executáveis em Debian:

- `desktop.sh`: instalador interativo de 15 etapas para desktop, WSL e
  ambientes completos de desenvolvimento.
- `server.sh`: instalador de 9 etapas, com opção não interativa `--yes`,
  concentrado em operações, Docker, shell, monitoramento e CLIs de IA.

Debian 12 ou mais recente é suportado. A validação descrita neste arquivo foi
feita em Debian GNU/Linux 13.6 `trixie`, arquitetura `amd64`.

## Modelo de privilégios

Os scripts podem ser iniciados por um usuário comum, por `sudo bash` ou
diretamente como root. A identidade que receberá ferramentas e configurações
deve ser mantida separada da identidade do processo:

- `REAL_USER`: usuário-alvo.
- `REAL_HOME`: diretório pessoal do usuário-alvo.
- `REAL_GROUP`: grupo primário do usuário-alvo.
- `user_do`: executa uma operação como `REAL_USER`.
- `sys_do`: executa somente a operação que exige privilégio administrativo.

Nunca use apenas `id -u` do processo para decidir onde instalar ferramentas do
usuário. Quando `sudo bash desktop.sh` é usado, o processo é root, mas o
destino continua sendo `REAL_USER`.

### `sudo` e `PATH`

O `sudo` normalmente aplica `secure_path` e pode remover diretórios como:

- `~/.local/bin`
- `~/.npm-global/bin`
- `~/.cargo/bin`
- `~/.bun/bin`

Exportar `PATH` no shell pai não garante que `user_do comando` encontrará um
executável instalado nesses diretórios. Para ferramentas gerenciadas pelo
script, use uma destas abordagens:

- caminho absoluto do executável;
- `user_do env PATH="$caminho_gerenciado:$PATH" comando`;
- um `bash -c` curto que defina explicitamente o `PATH`.

Depois da instalação, execute o comando ou `--version` usando o mesmo ambiente
que o usuário receberá.

Antes de repassar o `PATH` para serviços, remova entradas duplicadas preservando
a primeira ocorrência. Não basta impedir novas duplicatas: o ambiente herdado
de `sudo` ou do shell também pode chegar duplicado.

### Pacotes npm globais

Quando `REAL_USER` não é root, pacotes npm globais devem usar
`$REAL_HOME/.npm-global`, inclusive quando o instalador foi iniciado por
`sudo`. O fluxo correto é:

1. criar o diretório como `REAL_USER`;
2. configurar `npm config set prefix "$REAL_HOME/.npm-global"`;
3. executar o npm com `PATH="$REAL_HOME/.npm-global/bin:$PATH"`;
4. validar cada comando instalado com esse mesmo `PATH`.

Sem isso, o npm tenta alterar `/usr/lib/node_modules` como usuário comum e
falha com `EACCES`.

### Pacotes pip globais para o usuário

O Python fornecido pelo APT e pelo Homebrew é marcado como externamente
gerenciado conforme a PEP 668. Para um pacote solicitado como global, mas que
deve pertencer a `REAL_USER`, use o interpretador absoluto correspondente e
instale com `python -m pip --user --break-system-packages`; nunca use `sudo pip`.

Resolva o diretório dos executáveis com `python -m site --user-base` executado
via `user_do`, porque ele é `~/.local/bin` no Linux e
`~/Library/Python/X.Y/bin` no macOS. Adicione esse diretório ao `PATH`, valide o
import do pacote e execute a validação do CLI com a identidade e o `HOME` do
usuário-alvo.

### Navegador para agentes no Desktop

A etapa 14 instala `agent-browser`, navegador e skill oficial global para Codex
e Claude. Instale bibliotecas Linux usando `sys_do`, após atualizar os índices
APT, e selecione variantes `t64` disponíveis. Use `apt-get install --no-remove`
para evitar que a transição de nomes remova pacotes existentes. Inclua fontes,
`libnss3-tools`, Xvfb/Xauth e Vulkan além das bibliotecas de GTK, X11 e áudio.

O instalador oficial `agent-browser install` rejeita Linux ARM64. Nessa
arquitetura, baixe Chromium por um pacote Playwright temporário do usuário;
obtenha o caminho com `chromium.executablePath()` e ligue seu diretório a
`~/.agent-browser/browsers/chrome-setupvibe-arm64`. Não dependa apenas do fallback
de cache do agent-browser: versões recentes do Playwright usam
`chrome-linux-arm64`, que o fallback atual não reconhece. Preserve arquivos de
configuração e remova o pacote temporário em caso de sucesso ou falha.

Downloads e validações devem executar como `REAL_USER`, nunca como root por
conveniência. Valide as instruções com `agent-browser skills get core` e a
abertura real com `agent-browser doctor --offline`; esse comando usa uma sessão
temporária em `about:blank` e a fecha. Um retorno de `--version` sozinho não
comprova que o navegador funciona. Não aplique `--no-sandbox` por padrão.

## APT e repositórios

- Chaves APT pertencem a `/etc/apt/keyrings/`.
- Remova somente arquivos de repositório reconhecidamente gerenciados pelo
  SetupVibe.
- Não remova repositórios por busca genérica de conteúdo: eles podem pertencer
  ao usuário ou a outro gerenciador.
- Exclua entradas legadas antes de adicionar a fonte atual para evitar conflito
  de assinatura.
- O `server.sh` deve aguardar locks do APT, pois VMs recém-iniciadas podem estar
  executando `unattended-upgrades`.
- Para Debian instável (`forky`, `sid` ou `experimental`), o repositório Docker
  usa o codinome estável compatível definido pelo script.
- Em Debian, o Server usa `ansible-core`; não presuma que o metapacote
  `ansible` esteja disponível.

## Downloads e arquivos temporários

Downloads gerenciados devem:

1. usar HTTPS;
2. falhar em erros HTTP;
3. repetir de forma limitada erros transitórios de rede;
4. ter timeout de conexão, timeout total e tamanho mínimo;
5. rejeitar respostas HTML;
6. verificar SHA-256 quando o projeto publica ou fixa um checksum;
7. instalar o arquivo final com proprietário, grupo e modo explícitos.

Não baixe como root para um nome previsível em `/tmp` e depois execute
`user_do mv`. O sticky bit de `/tmp` permite que o usuário copie o conteúdo,
mas impede a remoção do arquivo criado por root; `mv` pode criar o destino e
ainda retornar erro ao tentar remover a origem.

Use `mktemp` e finalize com `sys_do install -o "$REAL_USER" -g "$REAL_GROUP"`.
O binário `ctop` deve ser verificado com o checksum correspondente à
arquitetura antes de ser instalado em `~/.local/bin/ctop`.

## Interatividade do Desktop

`desktop.sh` depende de um terminal real para:

- confirmar o roadmap;
- configurar nome e e-mail do Git quando ausentes.

O script deve validar `/dev/tty` antes de alterar o sistema e sair com erro
claro quando não houver terminal. Todo `read </dev/tty` também deve tratar
EOF ou perda do terminal. Sem essa proteção, o prompt de Git pode entrar em
loop infinito em automações sem TTY.

Em Docker, use `docker exec -it` para o Desktop. O Server pode usar execução
sem TTY com `--yes`.

## systemd e Docker dentro do container

Um container comum não representa adequadamente o instalador porque os scripts
habilitam e validam serviços como:

- `cron`;
- `docker`;
- `ssh`;
- `tailscaled`.

O teste de integração usa systemd como PID 1, container privilegiado e `tmpfs`
para `/run` e `/run/lock`.

Docker dentro de Docker não deve usar `overlay2` sobre o filesystem `overlay`
do container externo. Essa combinação falha e não representa um defeito do
SetupVibe. Somente no ambiente de teste aninhado, configure o daemon interno:

```json
{
  "features": {
    "containerd-snapshotter": false
  },
  "storage-driver": "vfs"
}
```

O driver `vfs` consome mais espaço e é mais lento, mas permite validar Docker
Compose e Portainer no container. Essa configuração não deve ser aplicada a
uma instalação Debian real.

## Receita reproduzível do container

Use uma imagem de teste descartável com um usuário comum e `sudo` sem senha:

```dockerfile
FROM debian:13

ENV container=docker

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates dbus systemd systemd-sysv sudo \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --shell /bin/bash tester \
    && printf '%s\n' 'tester ALL=(ALL) NOPASSWD:ALL' \
        > /etc/sudoers.d/tester \
    && chmod 0440 /etc/sudoers.d/tester

STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]
```

Crie o container com o repositório montado somente para leitura:

```bash
docker run -d \
    --name setupvibe-debian-desktop \
    --privileged \
    --security-opt label=disable \
    --tmpfs /run \
    --tmpfs /run/lock \
    -v "$PWD:/workspace:ro" \
    setupvibe/debian-systemd:13
```

Configure `vfs` no daemon Docker interno antes de testar a etapa DevOps. Em
seguida, execute:

```bash
# Desktop: TTY obrigatório
docker exec -it --user tester setupvibe-debian-desktop \
    sudo bash /workspace/desktop.sh

# Server: modo não interativo suportado
docker exec --user tester setupvibe-debian-server \
    sudo bash /workspace/server.sh --yes
```

O mount somente para leitura garante que o instalador não modifica
acidentalmente o checkout. Estado instalado e logs permanecem dentro do
container.

## Estratégia de validação

Uma mudança Linux não está validada apenas por `bash -n`. Use, conforme o
escopo:

1. `bash -n` para sintaxe.
2. `shellcheck` para problemas estáticos.
3. execução limpa no Debian suportado;
4. nova execução no mesmo container para testar idempotência;
5. resumo final com todas as etapas em `OK`;
6. validação dos comandos instalados;
7. validação dos serviços com `systemctl is-active`;
8. validação de Portainer com `docker ps`;
9. teste negativo do Desktop sem TTY.

Avisos de dependências opcionais do npm não são por si só falhas. O critério é
o exit code da instalação e a execução bem-sucedida dos comandos gerenciados.

Versões atuais do npm controlam scripts de instalação de dependências em
instalações globais. Aprove somente os pacotes nativos necessários com
`--allow-scripts`; não use a opção ampla que libera todos os scripts.

## Aprendizados da investigação de julho de 2026

### Desktop sem TTY

Uma execução sem `docker exec -it` revelou que `read </dev/tty` falhava e o
prompt de Git repetia indefinidamente. O Desktop agora encerra antes de alterar
o sistema quando não encontra terminal interativo.

### Prefixo npm incorreto

O Desktop verificava o UID do processo root em vez de `REAL_USER`. Como
resultado, PNPM, PM2, n8n e todos os CLIs de IA tentavam usar `/usr` e falhavam
com `EACCES`. A decisão agora é baseada no usuário-alvo e cada comando é
validado com o `PATH` gerenciado.

### `ctop` e sticky bit de `/tmp`

O download era criado por root em `/tmp/ctop` e movido por `REAL_USER`. O
destino podia ser criado, mas a remoção da origem falhava com
`Operation not permitted`. O download agora usa arquivo temporário único,
checksum SHA-256 e instalação com propriedade explícita.

### Starship e CLIs instalados no diretório do usuário

Starship foi instalado corretamente em `~/.local/bin`, mas `user_do starship`
não o encontrou por causa do `secure_path` do sudo. O script passou a usar o
caminho absoluto. O mesmo princípio se aplica a Skills CLI e PM2.

### Fórmula Homebrew desativada

A fórmula `tldr` foi desativada pelo Homebrew em 24 de outubro de 2025 por
falta de manutenção. O Desktop instala a implementação mantida `tlrc`, que
continua oferecendo o comando `tldr`. Reruns devem desinstalar a fórmula
legada antes de instalar `tlrc`, pois ambas fornecem o mesmo executável.

### Scripts nativos bloqueados pelo npm

O npm bloqueou o script de instalação de `better-sqlite3`, dependência nativa
do Agentlytics. O pacote JavaScript era adicionado, mas o comando falhava ao
carregar o binding SQLite. A instalação agora aprova somente
`better-sqlite3` e valida a criação de um banco SQLite em memória. O
Agentlytics não oferece uma opção `--version`; usá-la inicia o fluxo
interativo e não é uma validação segura para automação.

O mesmo mecanismo bloqueou o `postinstall` do Claude Code e pode afetar outros
CLIs gerenciados. Cada pacote direto deve receber sua própria aprovação
`--allow-scripts` no comando de instalação. O n8n também exige aprovação
explícita para sua lista revisada de dependências com bindings ou geração de
artefatos.

### Idempotência do Starship e do `PATH`

`starship preset` recusa sobrescrever `~/.config/starship.toml` sem `--force`.
Como esse arquivo é gerenciado pelo Desktop, o rerun deve aplicar o preset com
essa opção.

Cada etapa adicionava novamente os mesmos diretórios ao `PATH`, o que gerava
uma variável enorme na unidade systemd do PM2. Diretórios gerenciados devem ser
inseridos somente quando ainda não estiverem presentes, e o caminho completo
deve ser deduplicado antes de ser fornecido ao PM2.

O gerador de startup do próprio PM2 acrescenta caminhos de sistema ao valor
recebido e pode reintroduzir duplicatas. No Linux, um drop-in systemd gerenciado
pelo SetupVibe deve sobrescrever o ambiente efetivo do serviço com o `PATH`
normalizado e executar `systemctl daemon-reload`.

### Falhas transitórias em downloads

Uma repetição completa chegou à etapa final e falhou ao baixar
`ecosystem.config.js` do GitHub. Downloads remotos são pontos de integração,
portanto uma resposta transitória não deve invalidar uma instalação longa sem
novas tentativas. O helper compartilhado agora exige HTTPS, aplica timeouts de
conexão e total e repete erros de transferência de forma limitada.

### PM2 e systemd

`pm2 startup systemd` executado como usuário comum apenas imprime o comando
administrativo necessário e retorna erro. A criação da unidade deve passar
por `sys_do`, com o caminho absoluto do PM2 disponível no `PATH`; operações
de estado como `pm2 save` continuam executando como `REAL_USER`.

### Tailscale em containers

Scripts de pacote podem respeitar `/usr/sbin/policy-rc.d` e instalar o
Tailscale sem iniciar o serviço. A etapa Linux deve executar e validar
explicitamente `systemctl enable --now tailscaled`.

### Resultado da execução

O `server.sh --yes` concluiu as 9 etapas no Debian 13, com Docker, Portainer,
Tailscale, SSH e cron ativos. A primeira execução limpa do Desktop reproduziu
as falhas acima. A primeira execução de regressão confirmou as correções de
npm, `ctop` e Starship e revelou os casos adicionais de migração `tldr`,
scripts nativos do npm e privilégios do PM2.

A execução integral final e idempotente do `desktop.sh` concluiu as 14 etapas
com `OK`. Docker, cron, SSH, Tailscale e `pm2-tester` ficaram ativos; Portainer
ficou em execução na porta HTTPS 9443; e a restauração do Agentlytics pelo
serviço PM2 foi testada depois de encerrar manualmente o daemon. O ambiente
efetivo do serviço ficou sem caminhos duplicados. Também passaram as
validações de versões dos ecossistemas, CLIs de IA, `tldr` via `tlrc`, checksum
e propriedade do `ctop`, binding SQLite do Agentlytics e saída antecipada do
Desktop sem TTY.

## Validação do navegador para agentes em outubro de 2026

A etapa de navegador foi executada isoladamente em containers ARM64 de Debian
12 e Ubuntu 24.04, com Node.js 24, agent-browser 0.38.2 e Playwright 1.64.0.
Passaram instalação limpa, reexecução, dependências APT, descoberta do Chromium,
skill oficial global e verificação da propriedade dos arquivos do usuário.
Também passaram abertura real, snapshot, preenchimento, clique, leitura do DOM
e captura de tela. Os dois containers encerraram com código zero.

Os testes usaram `seccomp=unconfined` e `apparmor=unconfined` apenas nos
containers isolados para permitir o sandbox nativo do navegador. O instalador
não aplica essas opções nem `--no-sandbox` ao ambiente do usuário. O checkout
ficou montado somente para leitura e nenhum container de teste publicou portas.
Essa validação cobriu a nova etapa, não uma execução integral do Desktop.

O diagnóstico avisou que faltava FFmpeg nos containers que executaram apenas a
nova etapa. FFmpeg já é instalado nas etapas base do Desktop Unix e nas
utilidades do Windows; é necessário para `agent-browser record`.

## Chafa e prévias no terminal em outubro de 2026

Chafa é instalado pelo APT na etapa base de Desktop e Server. Os pacotes
testados foram 1.12.4 no Debian 12 e 1.14.0 no Ubuntu 24.04, em ARM64. Essas
versões diferem da versão mais recente publicada pelo projeto; mantenha os
exemplos compatíveis com os pacotes das distribuições suportadas.

Passaram instalação limpa, reexecução como usuário comum com `sudo`, validação
de versão, renderização de PNG com `--format symbols` e retorno de erro para
arquivo inexistente. Os testes usaram os helpers do Server em containers
descartáveis com o checkout somente para leitura, sem publicar portas ou
executar os instaladores completos. A renderização em caracteres permite
validar imagens sem depender de um protocolo gráfico ou de um terminal GUI.

## Distribuição da skill de ambiente em outubro de 2026

Skills CLI 1.7.1 trata agentes com raiz de projeto `.agents/skills` como
universais e instala suas skills globais nessa mesma raiz compartilhada,
mesmo quando o registro informa uma raiz nativa diferente. O helper
`utils/install_environment_skill.mjs` também publica o arquivo da skill nos
caminhos nativos documentados. Use `--json` com `--yes` para propagar falhas de
qualquer destino; a saída comum do CLI pode apenas listar falhas parciais.

A instalação local e a reexecução da nova função do Server passaram em
Debian 12 ARM64 com Node.js 24 e Skills CLI 1.7.1, num container sem rede ou
portas publicadas, com checkout somente para leitura. A execução começou
como root e usou `user_do` para instalar no usuário `node`; os nove caminhos
compartilhados/nativos e o helper ficaram com o proprietário correto. A
reexecução como usuário comum também passou. O teste não executou o
instalador completo nem alterou serviços da VPS.
