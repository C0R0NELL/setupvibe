# SetupVibe Environment Skill

> User-level skill distribution for Desktop and Server — v0.41.11

Desktop step 13, Server step 7, and Windows after Skills CLI installation
install [`setupvibe-environment`](../../skills/setupvibe-environment/SKILL.md).
This is a product skill shipped with SetupVibe. The skills under `.codex/skills`
and `.claude/skills` remain development instructions for maintaining this repo.

## Current content

The discovery description tells agents to consult already-installed tools and
choose suitable commands for the user's request. Tables list tools, command
examples, practical uses, and availability in Unix Desktop, Server, and native
Windows. They cover image previews, media, browser automation, file search,
JSON, GitHub, containers, infrastructure, diagnostics, sessions, and agent
tooling. Ordinary language runtimes such as Python and Node.js are omitted.

The skill prefers the user's existing Herdr workspace within their request
and authorization. It covers context checks, explicit pane targets, and
detaching/reconnecting while preserving processes and user focus. Tmux remains
an alternative when requested, already in use, or Herdr is unavailable.

The skill distinguishes executable names from shell aliases and interactive
interfaces. It includes platform-specific details such as `agent-browser.cmd`
on Windows, Chafa's character mode over SSH, and Cronboard's lack of
noninteractive help/version flags. Agents check the current executable before
using it because edition, installation results, and later user changes affect
availability. Discovery and automatic activation depend on the harness.

## Installation and locations

The installer uses the existing [Skills CLI](https://github.com/vercel-labs/skills)
with explicit agents, `--global`, `--copy`, `--yes`, and `--json`. Explicit
targets prepare the directories even if those agents are installed later.
Copy mode avoids symlink privileges on Windows. JSON mode reports a failed
installation if any target fails, instead of silently accepting partial success.
The shared Node helper also copies `SKILL.md` to documented native user roots
because Skills CLI maps several harnesses to the common `.agents/skills` root.

These are the default user skill roots. Each contains
`setupvibe-environment/SKILL.md` after installation:

| Harness | Skills CLI ID | Default user skill root |
| --- | --- | --- |
| Codex | `codex` | `~/.agents/skills` |
| Claude Code | `claude-code` | `~/.claude/skills` |
| OpenCode | `opencode` | `~/.config/opencode/skills` |
| Grok Build | `grok` | `~/.grok/skills` |
| Kimi Code CLI | `kimi-code-cli` | `~/.agents/skills` |
| Gemini CLI | `gemini-cli` | `~/.gemini/skills` |
| Cursor | `cursor` | `~/.cursor/skills` |
| GitHub Copilot | `github-copilot` | `~/.copilot/skills` |
| Antigravity CLI | `antigravity-cli` | `~/.gemini/antigravity-cli/skills` |
| Amp | `amp` | `~/.config/agents/skills` |

Codex and Kimi use the shared `.agents/skills` directory; creating `.codex` or
`.kimi` directories is unnecessary for this skill. OpenCode's global root is
under `.config`, rather than `~/.opencode`. The directory is named `skills`
(plural), with one folder per skill. Windows resolves `~` to the signed-in
user's home directory; WSL has its own Linux user home.

The installer resolves supported location overrides, including `XDG_CONFIG_HOME`,
`CLAUDE_CONFIG_DIR`, and `GROK_HOME`. No agent configuration, credentials,
profiles, or project instructions are written by this installation.

## Source and updates

When running a local checkout, the installer uses the skill directory beside
the script. When running the published script through curl or PowerShell, it
downloads the product skill from the direct raw URL on this fork's `main` branch:

```text
https://raw.githubusercontent.com/C0R0NELL/setupvibe/main/skills/setupvibe-environment/SKILL.md
```

The shared helper is loaded locally or downloaded from
`utils/install_environment_skill.mjs` on the same fork and branch. It uses the
existing Node.js runtime and Skills CLI; no extra runtime is installed.

Rerunning the installer replaces this skill's managed copies with the current
source. Other skill directories are preserved. Edit the source in the fork to
make lasting changes. Windows `-Uninstall` preserves installed skills, matching
the existing policy for agent-browser skills.

To inspect installed user skills:

```bash
skills list --global
```

Start a new agent session or use its skill reload command when needed. The
installer prepares instructions for the listed harnesses; it does not install
additional agent executables beyond each edition's existing tool list.

## Sources

- [Skills CLI supported agents and installation options](https://github.com/vercel-labs/skills)
- [Codex skill discovery](https://developers.openai.com/codex/skills/)
- [Claude Code personal skills](https://code.claude.com/docs/en/skills)
- [OpenCode skill locations](https://opencode.ai/docs/skills/)
- [Grok Build skill locations](https://github.com/xai-org/grok-build/blob/main/crates/codegen/xai-grok-shell/README.md#skills)
- [Kimi Code CLI skill locations](https://moonshotai.github.io/kimi-code/en/customization/skills)
- [Gemini CLI user skills](https://geminicli.com/docs/cli/using-agent-skills/)
