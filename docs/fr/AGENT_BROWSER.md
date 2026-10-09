# Agent Browser

> Automatisation du navigateur et intégration des agents — v0.41.11, ajout local du fork

Desktop Unix ajoute `agent-browser` à l'étape 14 et déplace le nettoyage à
l'étape 15. Desktop Windows ajoute sa propre étape. Le CLI, le navigateur et
la skill officielle sont préparés pour Codex et Claude Code dans tous les
projets. Server et Omarchy n'incluent pas cette étape.

## Exigences par plateforme

| Plateforme | Navigateur | Dépendances |
| --- | --- | --- |
| macOS 13+, Intel ou Apple Silicon | Chrome for Testing via `agent-browser install` | Node.js 24 via Homebrew ; aucune bibliothèque Linux ni compilation Rust |
| Windows 11 22H2+, x64 | Chrome for Testing via `agent-browser.cmd install` | Node.js 24 du MSI officiel ; lanceurs CMD compatibles avec les stratégies PowerShell restrictives |
| Ubuntu 24.04+, Debian 12+, Zorin OS 18+, WSL ; x86_64 | Chrome for Testing | Node.js 24, bibliothèques APT, polices, Xvfb/Xauth et Vulkan |
| Les mêmes systèmes Linux ; ARM64 | Chromium téléchargé via Playwright | Les mêmes dépendances ; sans Snap, installation globale de Playwright ni projet de tests |

Chrome actuel exige macOS 13+. Les autres étapes acceptent toujours macOS 12,
mais l'étape navigateur signale une erreur sur ce système. Windows ARM reste
hors du support de SetupVibe. Le paquet npm exige Node.js 24+ ; le CLI natif
n'exige ni pnpm ni compilation Rust.

Playwright sert uniquement à télécharger Chromium pour Linux ARM64, refusé par
l'installateur officiel `agent-browser install`. Les téléchargements restent
dans `~/.cache/ms-playwright`. SetupVibe lie le répertoire indiqué par Playwright
à `~/.agent-browser/browsers/chrome-setupvibe-arm64`, sans dépendre du format du
cache ni remplacer la configuration utilisateur. Le paquet temporaire du
téléchargeur est supprimé après réussite ou échec.

L'enregistrement avec `agent-browser record` exige FFmpeg dans le `PATH`. Les
étapes de base du Desktop l'installent déjà sous Linux et macOS ; les utilitaires
Windows l'installent et le valident également.

## Dépendances Linux et permissions

La liste complète des bibliothèques de `cli/src/install.rs` se trouve dans le
[guide anglais](../en/AGENT_BROWSER.md). Elle inclut GTK, X11/XCB, Cairo/Pango,
audio, NSS/NSPR, D-Bus, CUPS, DRM/GBM et `libnss3-tools`.

APT est actualisé avant de résoudre les noms `t64`, dont `libasound2t64` et
`libgtk-3-0t64`. `--no-remove` empêche la suppression de paquets existants.
Les paquets `fonts-noto-color-emoji`, `fonts-noto-cjk`, `fonts-freefont-ttf`,
`xvfb`, `xauth`, `libvulkan1` et `mesa-vulkan-drivers` sont aussi installés.

Seules les bibliothèques système utilisent `sys_do`. npm, navigateurs, skills
et validations s'exécutent comme `REAL_USER`, même avec `sudo bash`. Les
paquets npm globaux Linux restent dans `~/.npm-global`. Une nouvelle exécution
réutilise les téléchargements compatibles.

## Utilisation par les agents

La skill officielle est installée globalement :

```bash
skills add vercel-labs/agent-browser --skill agent-browser --global --agent codex claude-code --yes
agent-browser skills get core
agent-browser skills get core --full
agent-browser skills list
```

Les agents chargent des instructions correspondant au CLI installé. Ne copiez
pas le guide depuis `node_modules`. Les instructions propres aux projets peuvent
compléter la skill globale.

## Validation et première utilisation

L'installation valide le CLI, les instructions incluses et
`agent-browser doctor --offline`, qui ouvre `about:blank` dans une session
temporaire puis la ferme. Les bibliothèques manquantes ou un échec de lancement
font échouer l'étape. Aucun dashboard, port public ou service permanent ne
démarre pendant l'installation.

Ouvrez un nouveau terminal :

```bash
agent-browser --version
agent-browser doctor --offline
agent-browser open https://example.com
agent-browser snapshot -i
agent-browser screenshot
agent-browser close
```

Utilisez `--headed` pour afficher le navigateur. Sans écran Linux, Xvfb démarre
automatiquement. Refaites un snapshot après une modification de page.
SetupVibe ne désactive pas le sandbox par défaut.

Sous Windows, `-Uninstall` supprime le CLI avant Node.js et conserve les caches
du navigateur, les sessions, les identifiants et les skills.

## Exécuter ce fork

Exécutez `bash desktop.sh` depuis ce checkout Unix ou
`powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\desktop.ps1` depuis
ce checkout Windows. Les URL canoniques upstream n'incluent pas les changements
locaux non publiés de votre fork.

## Références officielles

- [Installation d'agent-browser](https://agent-browser.dev/installation)
- [Bibliothèques et installateur natif](https://github.com/vercel-labs/agent-browser/blob/main/cli/src/install.rs)
- [Navigateurs Playwright](https://playwright.dev/docs/browsers)
- [Options Skills CLI](https://github.com/vercel-labs/skills#options)
- [Exigences Chrome](https://support.google.com/chrome/a/answer/7100626)
