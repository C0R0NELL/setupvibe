# Agent Browser

> Automatización del navegador e integración con agentes — v0.41.11, adición local del fork

Desktop Unix añade `agent-browser` en el paso 14 y mueve la limpieza al paso 15.
Desktop Windows añade su propia etapa. Prepara la CLI, el navegador y la skill
oficial para Codex y Claude Code en todos los proyectos. Server y Omarchy no
incluyen esta etapa.

## Requisitos por plataforma

| Plataforma | Navegador | Dependencias |
| --- | --- | --- |
| macOS 13+, Intel o Apple Silicon | Chrome for Testing mediante `agent-browser install` | Node.js 24 mediante Homebrew; no necesita bibliotecas Linux ni compilar Rust |
| Windows 11 22H2+, x64 | Chrome for Testing mediante `agent-browser.cmd install` | Node.js 24 del MSI oficial; lanzadores CMD compatibles con políticas PowerShell restringidas |
| Ubuntu 24.04+, Debian 12+, Zorin OS 18+, WSL; x86_64 | Chrome for Testing | Node.js 24, bibliotecas APT, fuentes, Xvfb/Xauth y Vulkan |
| Los mismos sistemas Linux; ARM64 | Chromium descargado mediante Playwright | Las mismas dependencias; sin Snap, Playwright global ni proyecto de pruebas |

Chrome actual requiere macOS 13+. Los otros pasos mantienen soporte para macOS
12, pero la etapa de navegador informa un error allí. Windows ARM sigue fuera
del soporte de SetupVibe. El paquete npm requiere Node.js 24+; la CLI nativa
no necesita instalar pnpm ni compilar Rust.

Playwright solo descarga Chromium para Linux ARM64, rechazado por el instalador
oficial `agent-browser install`. Las descargas permanecen en
`~/.cache/ms-playwright`. SetupVibe enlaza el directorio indicado por Playwright
a `~/.agent-browser/browsers/chrome-setupvibe-arm64`, sin depender del formato
del caché ni reemplazar la configuración del usuario. El paquete temporal del
instalador se elimina tanto al terminar correctamente como al fallar.

La grabación con `agent-browser record` requiere FFmpeg en el `PATH`. Los pasos
base del Desktop ya lo instalan en Linux y macOS; las utilidades de Windows
también lo instalan y validan.

## Dependencias Linux y permisos

La lista completa de bibliotecas de `cli/src/install.rs` está en la
[guía inglesa](../en/AGENT_BROWSER.md). Incluye GTK, X11/XCB, Cairo/Pango,
audio, NSS/NSPR, D-Bus, CUPS, DRM/GBM y `libnss3-tools`.

APT se actualiza antes de resolver nombres `t64`, como `libasound2t64` y
`libgtk-3-0t64`. `--no-remove` evita eliminar paquetes existentes. También se
instalan `fonts-noto-color-emoji`, `fonts-noto-cjk`, `fonts-freefont-ttf`,
`xvfb`, `xauth`, `libvulkan1` y `mesa-vulkan-drivers`.

Solo las bibliotecas de sistema usan `sys_do`. npm, navegadores, skills y
validaciones usan `REAL_USER`, incluso con `sudo bash`. Los paquetes npm
globales en Linux permanecen en `~/.npm-global`. Repetir la instalación
reutiliza las descargas compatibles.

## Uso por los agentes

La skill oficial se instala globalmente:

```bash
skills add vercel-labs/agent-browser --skill agent-browser --global --agent codex claude-code --yes
agent-browser skills get core
agent-browser skills get core --full
agent-browser skills list
```

El agente carga instrucciones que corresponden a la CLI instalada. No copie
el manual desde `node_modules`; las instrucciones de cada proyecto pueden
complementar la skill global.

## Validación y primer uso

El instalador valida la CLI, las instrucciones incluidas y
`agent-browser doctor --offline`, que abre `about:blank` en una sesión temporal
y la cierra. Si faltan bibliotecas o falla el inicio, la etapa falla. No inicia
dashboard, puerto público ni servicio permanente.

Abra un terminal nuevo:

```bash
agent-browser --version
agent-browser doctor --offline
agent-browser open https://example.com
agent-browser snapshot -i
agent-browser screenshot
agent-browser close
```

`--headed` muestra el navegador; Xvfb inicia automáticamente en Linux sin
pantalla. Genere otro snapshot después de cambiar la página. SetupVibe no
desactiva el sandbox por defecto.

Windows `-Uninstall` elimina la CLI antes de Node.js y conserva la caché del
navegador, sesiones, credenciales y skills.

## Ejecutar este fork

Ejecute `bash desktop.sh` desde este checkout Unix o
`powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\desktop.ps1` desde
este checkout Windows. Las URL canónicas del upstream no incluyen cambios
locales no publicados de su fork.

## Referencias oficiales

- [Instalación de agent-browser](https://agent-browser.dev/installation)
- [Dependencias e instalador nativo](https://github.com/vercel-labs/agent-browser/blob/main/cli/src/install.rs)
- [Navegadores de Playwright](https://playwright.dev/docs/browsers)
- [Opciones de Skills CLI](https://github.com/vercel-labs/skills#options)
- [Requisitos de Chrome](https://support.google.com/chrome/a/answer/7100626)
