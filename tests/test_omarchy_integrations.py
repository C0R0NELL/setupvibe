"""Exercise Omarchy's real integration functions with isolated user data and CLIs."""

import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import tomllib
import unittest


ROOT = Path(__file__).resolve().parents[1]


class OmarchyIntegrationTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="setupvibe-omarchy-")
        self.addCleanup(self.temporary.cleanup)
        self.directory = Path(self.temporary.name)
        self.home = self.directory / "user home"
        self.bin = self.home / ".local/bin"
        self.bin.mkdir(parents=True)
        self.checkout = self.directory / "local checkout"
        self.checkout.mkdir()
        for name in ("utils", "skills", "conf"):
            (self.checkout / name).symlink_to(ROOT / name, target_is_directory=True)
        source = (ROOT / "omarchy.sh").read_text()
        library = re.sub(r'(?m)^main "\$@"[^\n]*\n?\Z', "", source)
        self.assertNotEqual(source, library)
        self.script = self.checkout / "omarchy.sh"
        self.script.write_text(library)
        self.log = self.directory / "calls.log"
        self.log.touch()
        self.npm_root = self.directory / "npm packages"
        skills = self.npm_root / "skills"
        skills.mkdir(parents=True)
        (skills / "package.json").write_text(json.dumps({"name": "skills", "bin": {"skills": "cli.mjs"}}))
        (skills / "cli.mjs").write_text("""
import fs from 'node:fs';
import path from 'node:path';
const args = process.argv.slice(2);
if (process.env.MOCK_SKILL_PARTIAL === '1') {
  console.log(JSON.stringify([{name: 'setupvibe-environment', status: 'failed'}]));
  process.exit(0);
}
for (const option of ['--global', '--copy', '--yes', '--json']) {
  if (!args.includes(option)) throw new Error(`Missing ${option}`);
}
const destination = path.join(process.env.HOME, '.agents/skills/setupvibe-environment');
fs.mkdirSync(destination, {recursive: true});
fs.copyFileSync(path.join(args[1], 'SKILL.md'), path.join(destination, 'SKILL.md'));
console.log(JSON.stringify([{name: 'setupvibe-environment', status: 'installed', path: destination}]));
""")
        self.environment = os.environ | {
            "HOME": str(self.home), "REAL_HOME": str(self.home),
            "REAL_USER": "tester", "REAL_GROUP": "tester",
            "PATH": f"{self.bin}:{os.environ['PATH']}",
            "XDG_CONFIG_HOME": str(self.home / ".config"),
            "CLAUDE_CONFIG_DIR": str(self.home / ".claude"),
            "GROK_HOME": str(self.home / ".grok"),
            "MOCK_LOG": str(self.log), "MOCK_NPM_ROOT": str(self.npm_root),
            "TMPDIR": str(self.directory),
        }
        for key in ("SUDO_USER", "LG_CONFIG_FILE", "CONFIG_DIR"):
            self.environment.pop(key, None)
        self.command("npm", '''printf 'npm %s\\n' "$*" >> "$MOCK_LOG"
case "$*" in
  'root --global') printf '%s\\n' "$MOCK_NPM_ROOT" ;;
  'config get prefix') printf '%s\\n' "$HOME/.local" ;;
esac
''')
        self.command("skills", 'printf "skills %s\\n" "$*" >> "$MOCK_LOG"\n')
        self.command("agent-browser", '''printf 'agent-browser %s\\n' "$*" >> "$MOCK_LOG"
if [[ "${MOCK_CONSUME_STDIN:-}" == 1 ]]; then cat >/dev/null; fi
if [[ "$*" == 'doctor --offline' && "${MOCK_BROWSER_FAIL:-}" == 1 ]]; then exit 31; fi
''')
        self.command("fzf", 'printf "fzf 0.60.0\\n"\n')

    def command(self, name, body):
        target = self.bin / name
        target.write_text("#!/bin/bash\nset -euo pipefail\n" + body)
        target.chmod(0o755)

    def run_shell(self, commands, *, extra_env=None, use_real_user_do=False):
        program = 'source "$OMARCHY_LIBRARY"\n' + commands
        if not use_real_user_do:
            program = 'source "$OMARCHY_LIBRARY"\nuser_do() { "$@"; }\n' + commands
        return subprocess.run(
            ["bash"], input=program, text=True, capture_output=True, timeout=30,
            env=self.environment | {"OMARCHY_LIBRARY": str(self.script)} | (extra_env or {}),
        )

    def require_success(self, result):
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_environment_skill_copies_current_source_and_preserves_other_skills(self):
        unrelated = self.home / ".claude/skills/unrelated/SKILL.md"
        unrelated.parent.mkdir(parents=True)
        unrelated.write_text("user-owned skill\n")
        for _ in range(2):
            self.require_success(self.run_shell("install_environment_skill\n"))
        expected = (ROOT / "skills/setupvibe-environment/SKILL.md").read_bytes()
        for root in (".agents", ".claude", ".config/opencode", ".grok", ".gemini", ".cursor", ".copilot", ".gemini/antigravity-cli", ".config/agents"):
            self.assertEqual((self.home / root / "skills/setupvibe-environment/SKILL.md").read_bytes(), expected)
        self.assertEqual(unrelated.read_text(), "user-owned skill\n")

    def test_environment_skill_rejects_partial_installation(self):
        result = self.run_shell("install_environment_skill\necho SKILL_COMPLETED\n", extra_env={"MOCK_SKILL_PARTIAL": "1"})
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("SKILL_COMPLETED", result.stdout)
        self.assertFalse((self.home / ".claude/skills/setupvibe-environment").exists())

    def test_browser_uses_arch_packages_and_reports_failed_launch(self):
        commands = '''omarchy_pkg_add() { printf 'packages %s\\n' "$*" >> "$MOCK_LOG"; }
install_agent_browser
echo BROWSER_COMPLETED
'''
        self.require_success(self.run_shell(commands))
        log = self.log.read_text()
        for expected in ("nss", "xorg-server-xvfb", "xorg-xauth", "vulkan-icd-loader", "--allow-scripts=agent-browser", "agent-browser install", "agent-browser skills get core", "agent-browser doctor --offline", "--agent codex claude-code"):
            self.assertIn(expected, log)
        self.assertNotIn("--with-deps", log)
        failed = self.run_shell(commands, extra_env={"MOCK_BROWSER_FAIL": "1"})
        self.assertEqual(failed.returncode, 31, failed.stderr)
        self.assertNotIn("BROWSER_COMPLETED", failed.stdout)

    def test_lazy_ui_merges_existing_configuration_without_replacing_backup(self):
        self.command("lazygit", 'printf "%s\\n" "$XDG_CONFIG_HOME/lazygit"\n')
        self.command("lazydocker", ":\n")
        for app in ("lazygit", "lazydocker"):
            directory = self.home / ".config" / app
            directory.mkdir(parents=True)
            (directory / "config.yml").write_text("gui:\n  sidePanelWidth: 42\ncustom: retained\n")
            (directory / "config.yml.bak").write_text("first backup\n")
        for _ in range(2):
            self.require_success(self.run_shell("configure_lazy_ui\n"))
        for app in ("lazygit", "lazydocker"):
            directory = self.home / ".config" / app
            self.assertIn("sidePanelWidth: 42", (directory / "config.yml").read_text())
            self.assertIn("custom: retained", (directory / "config.yml").read_text())
            self.assertEqual((directory / "config.yml.bak").read_text(), "first backup\n")
        self.assertIn("showFileIcons: true", (self.home / ".config/lazygit/config.yml").read_text())
        self.assertIn('border: "rounded"', (self.home / ".config/lazydocker/config.yml").read_text())

    def test_user_commands_keep_managed_path_through_sudo(self):
        self.command("setupvibe-user-tool", "echo USER_TOOL_FOUND\n")
        result = self.run_shell('''id() { echo 0; }
sudo() { shift 3; env -i HOME="$REAL_HOME" PATH=/usr/bin:/bin "$@"; }
user_do setupvibe-user-tool
''', use_real_user_do=True)
        self.require_success(result)
        self.assertIn("USER_TOOL_FOUND", result.stdout)

    def test_download_runs_as_target_user_and_cleans_failed_transfer(self):
        result = self.run_shell('''user_do() { printf 'user_do %s\\n' "$1" >> "$MOCK_LOG"; "$@"; }
curl() { return 22; }
safe_download https://example.invalid/tool "$REAL_HOME/downloaded-tool"
''')
        self.assertNotEqual(result.returncode, 0)
        log = self.log.read_text()
        self.assertIn("user_do mktemp", log)
        self.assertIn("user_do curl", log)
        self.assertIn("user_do rm", log)
        self.assertEqual(list(self.directory.glob("tmp.*")), [])
        self.assertFalse((self.home / "downloaded-tool").exists())

    def test_remote_helper_uses_fork_main_and_leaves_no_download_temporary(self):
        remote_library = self.directory / "downloaded-omarchy.sh"
        remote_library.write_text(self.script.read_text())
        self.script = remote_library
        self.command("lazygit", 'printf "%s\\n" "$XDG_CONFIG_HOME/lazygit"\n')
        self.command("lazydocker", ":\n")
        result = self.run_shell('''curl() {
    local destination="" url=""
    while (( $# )); do
        case "$1" in
            --output) destination=$2; shift 2 ;;
            https://*) url=$1; shift ;;
            *) shift ;;
        esac
    done
    printf 'download %s\\n' "$url" >> "$MOCK_LOG"
    cp "$MOCK_LAZY_HELPER" "$destination"
}
configure_lazy_ui
''', extra_env={"MOCK_LAZY_HELPER": str(ROOT / "utils/configure_lazy_ui.py")})
        self.require_success(result)
        self.assertIn("download https://raw.githubusercontent.com/C0R0NELL/setupvibe/main/utils/configure_lazy_ui.py", self.log.read_text())
        self.assertEqual(list(self.directory.glob("tmp.*")), [])
        self.assertTrue((self.home / ".config/lazygit/config.yml").exists())

    def test_pet_reuses_official_helper_and_preserves_snippets(self):
        self.command("pet", "echo 'pet version 1.0.1'\n")
        snippets = self.home / ".config/pet/snippet.toml"
        snippets.parent.mkdir(parents=True)
        snippets.write_text("user snippets\n")
        result = self.run_shell('''omarchy_pkg_add() { printf 'packages %s\\n' "$*" >> "$MOCK_LOG"; }
install_pet
''')
        self.require_success(result)
        self.assertIn("packages fzf", self.log.read_text())
        self.assertNotIn("pet-bin", self.log.read_text())
        self.assertTrue((self.home / ".setupvibe/bin/install_pet.mjs").exists())
        self.assertEqual(snippets.read_text(), "user snippets\n")

    def test_main_calls_integrations_and_stops_before_success_on_browser_failure(self):
        self.command("lazygit", 'printf "%s\\n" "$XDG_CONFIG_HOME/lazygit"\n')
        self.command("lazydocker", ":\n")
        stubs = ""
        for name in (
            "detect_user", "check_omarchy", "confirm_installation", "install_additional_packages",
            "install_setupvibe_files", "configure_php_and_rails", "configure_python_go_rust",
            "configure_javascript", "install_optional_ai_tools", "write_starship_config",
            "write_aliases", "append_shell_integration", "configure_portainer",
            "configure_tailscale", "configure_ssh", "install_terminal_browser",
            "install_harlequin", "install_pet", "install_redis_tui", "install_yazi",
        ):
            stubs += f'{name}() {{ printf "STAGE: {name}\\n"; }}\n'
        stubs += 'omarchy_pkg_add() { printf "packages %s\\n" "$*" >> "$MOCK_LOG"; }\n'
        # Reuse the production entrypoint, including its input redirection.
        entrypoint = (ROOT / "omarchy.sh").read_text().splitlines()[-1]
        commands = stubs + entrypoint + '\necho CALLER_COMPLETED\n'
        result = self.run_shell(commands, extra_env={"MOCK_CONSUME_STDIN": "1"})
        self.require_success(result)
        self.assertIn("CALLER_COMPLETED", result.stdout)
        self.assertIn("STAGE: install_yazi", result.stdout)
        self.assertIn("concluído.", result.stdout)
        self.assertTrue((self.home / ".claude/skills/setupvibe-environment/SKILL.md").exists())
        self.assertTrue((self.home / ".config/lazygit/config.yml").exists())
        self.assertIn("agent-browser doctor --offline", self.log.read_text())
        failed = self.run_shell(commands, extra_env={"MOCK_BROWSER_FAIL": "1"})
        self.assertEqual(failed.returncode, 31, failed.stderr)
        self.assertNotIn("STAGE: install_yazi", failed.stdout)
        self.assertNotIn("concluído.", failed.stdout)

    def test_starship_preserves_existing_config_and_uses_shared_template_for_new_user(self):
        config = self.home / ".config/setupvibe/starship.toml"
        self.require_success(self.run_shell("write_starship_config\n"))
        self.assertIn("$hostname", config.read_text())
        prompt_format = tomllib.loads(config.read_text())["format"]
        self.assertTrue(prompt_format.startswith("[](color_orange)"))
        self.assertIn("[ ](fg:color_bg1)", prompt_format)
        self.assertIn("[](bg:color_yellow fg:color_orange)", prompt_format)
        config.write_text("# user customization\n")
        self.require_success(self.run_shell("write_starship_config\n"))
        self.assertEqual(config.read_text(), "# user customization\n")

    def test_native_packages_do_not_request_bundled_php_extensions(self):
        result = self.run_shell('''omarchy_pkg_add() { printf 'packages %s\\n' "$*" >> "$MOCK_LOG"; }
install_additional_packages
''')
        self.require_success(result)
        self.assertNotIn("php-zip", self.log.read_text())
        self.assertNotIn("php-intl", self.log.read_text())

    def test_php_zip_uses_managed_ini_and_preserves_main_configuration(self):
        system = self.home / "fake-system"
        ini = system / "etc/php/php.ini"
        ini.parent.mkdir(parents=True)
        ini.write_text("; user PHP configuration\n")
        self.command("php", '''case "$*" in
    *PHP_CONFIG_FILE_SCAN_DIR*) echo /etc/php/conf.d ;;
    *'extension=zip'*) exit 0 ;;
    *extension_loaded*) test -e "$MOCK_SYSTEM_ROOT/etc/php/conf.d/99-setupvibe-zip.ini" ;;
    *) exit 2 ;;
esac
''')
        commands = '''sys_do() {
    local -a args=()
    while (( $# )); do
        case "$1" in
            -o|-g) shift 2 ;;
            /etc/php*) args+=("$MOCK_SYSTEM_ROOT$1"); shift ;;
            *) args+=("$1"); shift ;;
        esac
    done
    "${args[@]}"
}
configure_php_zip
'''
        for _ in range(2):
            self.require_success(self.run_shell(commands, extra_env={"MOCK_SYSTEM_ROOT": str(system)}))
        self.assertEqual(ini.read_text(), "; user PHP configuration\n")
        self.assertEqual((ini.parent / "conf.d/99-setupvibe-zip.ini").read_text().count("extension=zip"), 1)

    def ruby_fixture(self):
        self.command("rails", "exit 127\n")
        self.command("bundle", "exit 127\n")
        self.command("ruby", '''case "$*" in
    *RbConfig*) printf '%s' "${MOCK_RUBY_BINDIR:-/usr/bin}" ;;
    *) echo 'ruby 3.4.12' ;;
esac
''')
        self.command("gem", '''test -e "$HOME/gem-ready" || exit 127
if [[ "$1" == install ]]; then
    printf 'gem %s\\n' "$*" >> "$MOCK_LOG"
    printf '#!/bin/bash\\necho Rails\\n' > "$HOME/.local/bin/rails"
    printf '#!/bin/bash\\necho Bundler\\n' > "$HOME/.local/bin/bundle"
    chmod +x "$HOME/.local/bin/rails" "$HOME/.local/bin/bundle"
else
    echo '3.6.9'
fi
''')
        return '''omarchy_pkg_add() {
    printf 'packages %s\\n' "$*" >> "$MOCK_LOG"
    touch "$HOME/gem-ready"
}
configure_rails
'''

    def test_rails_repairs_missing_native_rubygems_and_installs_in_user_bin(self):
        commands = self.ruby_fixture()
        for _ in range(2):
            self.require_success(self.run_shell(commands))
        log = self.log.read_text()
        self.assertIn("packages rubygems", log)
        self.assertIn("--user-install", log)
        self.assertIn(f"--bindir {self.bin}", log)
        self.assertTrue((self.bin / "rails").exists())
        self.assertTrue((self.bin / "bundle").exists())
        self.assertEqual(log.count("gem install"), 1)

    def test_rails_recovers_gem_from_active_ruby_directory_without_replacing_ruby(self):
        commands = self.ruby_fixture()
        ruby_bin = self.home / "managed ruby/bin"
        ruby_bin.mkdir(parents=True)
        gem = ruby_bin / "gem"
        gem.write_text((self.bin / "gem").read_text())
        gem.chmod(0o755)
        (self.home / "gem-ready").touch()
        self.command("gem", "exit 127\n")
        self.require_success(self.run_shell(commands, extra_env={"MOCK_RUBY_BINDIR": str(ruby_bin)}))
        self.assertNotIn("packages", self.log.read_text())
        self.assertTrue((self.bin / "rails").exists())

    def test_rails_does_not_replace_a_managed_ruby_missing_gem(self):
        result = self.run_shell(self.ruby_fixture(), extra_env={"MOCK_RUBY_BINDIR": "/custom/mise/ruby/bin"})
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Ruby ativo", result.stderr)
        self.assertNotIn("packages", self.log.read_text())

    def docker_fixture(self):
        self.command("docker", '''printf 'docker %s\\n' "$*" >> "$MOCK_LOG"
if [[ "${1:-}" == --host ]]; then shift 2; fi
case "$*" in
    'context inspect '*) echo "${MOCK_DOCKER_ENDPOINT:-unix:///var/run/docker.sock}" ;;
    info)
        test -e "$HOME/docker-ready" || exit 1
        [[ "${MOCK_ROOT_CHECK:-}" == 1 || "${MOCK_REFRESHED_GROUPS:-}" == 1 ]] ;;
    'compose version') exit 0 ;;
    'compose -f '*) touch "$HOME/portainer-started" ;;
    *) exit 2 ;;
esac
''')
        self.command("sudo", '''printf 'sudo %s\\n' "$*" >> "$MOCK_LOG"
shift 3
export MOCK_REFRESHED_GROUPS=1
exec "$@"
''')
        compose = self.home / ".setupvibe/portainer-compose.yml"
        compose.parent.mkdir(parents=True)
        compose.write_text((ROOT / "conf/portainer-compose.yml").read_text())
        return '''id() { echo tester; }
getent() { echo 'docker:x:990:'; }
sys_do() {
    printf 'system %s\\n' "$*" >> "$MOCK_LOG"
    case "$1" in
        systemctl)
            [[ "${MOCK_DOCKER_START_FAIL:-}" != 1 ]] || return 44
            touch "$HOME/docker-ready" ;;
        usermod|groupadd) return 0 ;;
        env) MOCK_ROOT_CHECK=1 "$@" ;;
        *) return 3 ;;
    esac
}
configure_portainer
'''

    def test_portainer_starts_local_service_and_refreshes_user_group(self):
        self.require_success(self.run_shell(self.docker_fixture()))
        log = self.log.read_text()
        self.assertIn("systemctl enable --now docker", log)
        self.assertIn("usermod -aG docker tester", log)
        self.assertIn("sudo -u tester -H env", log)
        self.assertTrue((self.home / "portainer-started").exists())

    def test_portainer_refuses_remote_context_without_starting_local_daemon(self):
        result = self.run_shell(self.docker_fixture(), extra_env={"MOCK_DOCKER_ENDPOINT": "ssh://production.example"})
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("system ", self.log.read_text())
        self.assertFalse((self.home / "portainer-started").exists())

    def test_portainer_reports_failed_daemon_start(self):
        result = self.run_shell(self.docker_fixture(), extra_env={"MOCK_DOCKER_START_FAIL": "1"})
        self.assertEqual(result.returncode, 44, result.stdout + result.stderr)
        self.assertFalse((self.home / "portainer-started").exists())

    def test_repair_mode_runs_only_affected_configuration(self):
        commands = '''detect_user() { :; }
check_omarchy() { :; }
confirm_installation() { :; }
configure_php_zip() { echo REPAIR_PHP; }
configure_rails() { echo REPAIR_RAILS; }
configure_portainer() { echo REPAIR_PORTAINER; }
install_additional_packages() { echo UNEXPECTED_FULL_INSTALL; exit 7; }
main --repair
'''
        result = self.run_shell(commands)
        self.require_success(result)
        for marker in ("REPAIR_PHP", "REPAIR_RAILS", "REPAIR_PORTAINER"):
            self.assertIn(marker, result.stdout)
        self.assertNotIn("UNEXPECTED_FULL_INSTALL", result.stdout)


if __name__ == "__main__":
    unittest.main()
