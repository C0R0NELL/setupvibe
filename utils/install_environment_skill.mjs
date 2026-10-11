import { spawnSync } from 'node:child_process';
import { randomUUID } from 'node:crypto';
import { promises as fs } from 'node:fs';
import { homedir } from 'node:os';
import path from 'node:path';

const skillName = 'setupvibe-environment';
const rawSource = 'https://raw.githubusercontent.com/C0R0NELL/setupvibe/main/skills/setupvibe-environment/SKILL.md';
const home = homedir();
const configHome = process.env.XDG_CONFIG_HOME || path.join(home, '.config');
const targets = [
  ['codex', path.join(home, '.agents', 'skills')],
  ['claude-code', path.join(process.env.CLAUDE_CONFIG_DIR?.trim() || path.join(home, '.claude'), 'skills')],
  ['opencode', path.join(configHome, 'opencode', 'skills')],
  ['grok', path.join(process.env.GROK_HOME?.trim() || path.join(home, '.grok'), 'skills')],
  ['kimi-code-cli', path.join(home, '.agents', 'skills')],
  ['gemini-cli', path.join(home, '.gemini', 'skills')],
  ['cursor', path.join(home, '.cursor', 'skills')],
  ['github-copilot', path.join(home, '.copilot', 'skills')],
  ['antigravity-cli', path.join(home, '.gemini', 'antigravity-cli', 'skills')],
  ['amp', path.join(configHome, 'agents', 'skills')],
];

async function install() {
  const args = process.argv.slice(2);
  let source = rawSource;
  let skillsPackage;
  for (let i = 0; i < args.length; i += 2) {
    if (!args[i + 1]) throw new Error(`Missing value for ${args[i]}`);
    if (args[i] === '--source') source = args[i + 1];
    else if (args[i] === '--skills-package') skillsPackage = args[i + 1];
    else throw new Error(`Unknown option: ${args[i]}`);
  }
  if (!skillsPackage || !path.isAbsolute(skillsPackage)) {
    throw new Error('An absolute --skills-package directory is required.');
  }
  if (source !== rawSource && !path.isAbsolute(source)) {
    throw new Error('The skill source must be a local absolute path or the fork raw URL.');
  }

  const pkg = JSON.parse(await fs.readFile(path.join(skillsPackage, 'package.json'), 'utf8'));
  if (pkg.name !== 'skills' || typeof pkg.bin?.skills !== 'string') {
    throw new Error('The installed Skills CLI package does not expose its expected entrypoint.');
  }
  const entrypoint = path.resolve(skillsPackage, pkg.bin.skills);
  if (!entrypoint.startsWith(path.resolve(skillsPackage) + path.sep)) {
    throw new Error('The Skills CLI entrypoint must belong to its package directory.');
  }

  // Use Node directly so Windows needs no .ps1 launcher or execution-policy change.
  const result = spawnSync(process.execPath, [
    entrypoint, 'add', source, '--skill', skillName, '--global', '--agent',
    ...targets.map(([agent]) => agent), '--copy', '--yes', '--json',
  ], { encoding: 'utf8', timeout: 180_000, maxBuffer: 4 * 1024 * 1024 });
  if (result.stderr) process.stderr.write(result.stderr);
  if (result.error) throw result.error;
  if (result.status !== 0) {
    throw new Error(`Skills CLI failed: ${result.stdout.trim() || result.signal || result.status}`);
  }
  const installed = JSON.parse(result.stdout);
  if (installed.length !== 1 || installed[0].name !== skillName ||
      installed[0].status !== 'installed' || !path.isAbsolute(installed[0].path || '')) {
    throw new Error('Skills CLI did not confirm installation of the environment skill.');
  }
  const content = await fs.readFile(path.join(installed[0].path, 'SKILL.md'));

  // Skills CLI maps several native harnesses to the shared .agents directory.
  // Also publish this one file to their documented native roots for discovery.
  for (const root of new Set(targets.map(([, directory]) => directory))) {
    const directory = path.join(root, skillName);
    const destination = path.join(directory, 'SKILL.md');
    await fs.mkdir(directory, { recursive: true });
    try {
      if ((await fs.readFile(destination)).equals(content)) continue;
    } catch (error) {
      if (error.code !== 'ENOENT') throw error;
    }
    const temporary = path.join(directory, `.SKILL.${randomUUID()}.tmp`);
    try {
      await fs.writeFile(temporary, content, { flag: 'wx', mode: 0o644 });
      await fs.rename(temporary, destination);
    } finally {
      await fs.rm(temporary, { force: true });
    }
  }
  console.log(`Installed ${skillName} for ${targets.length} harnesses in the target user's skill directories.`);
}

install().catch((error) => {
  console.error(`Environment skill installation failed: ${error.message}`);
  process.exitCode = 1;
});
