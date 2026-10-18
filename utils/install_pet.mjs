import { createHash, randomUUID } from 'node:crypto';
import { constants } from 'node:fs';
import { chmod, copyFile, mkdir, mkdtemp, rename, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { parseArgs } from 'node:util';
import { pathToFileURL } from 'node:url';
import { setTimeout } from 'node:timers/promises';

export const version = '1.0.1';
// https://github.com/knqyf263/pet/releases/download/v1.0.1/pet_1.0.1_checksums.txt
export const checksums = {
  linux_x64: 'be6ca6b64953f3c63430b1519382bdf56a062a03944b9a3723513b285c91dd20',
  linux_arm64: 'f2a950f42789ec1e0952259c3c1731e03b2eb034bd830ae494a6268e9cac9273',
  win32_x64: '49c8346998958774513ee65977d8b9d9a327f76ca3a32caaa30ce1c98dadd64a',
};

export function verifyArchive(buffer, expected) {
  if (createHash('sha256').update(buffer).digest('hex') !== expected) {
    throw new Error('Pet archive SHA-256 mismatch');
  }
}

async function download(url) {
  for (let attempt = 1; attempt <= 3; attempt += 1) {
    try {
      const response = await fetch(url, { signal: AbortSignal.timeout(120_000) });
      if (!response.ok || !response.url.startsWith('https://')) {
        throw new Error(`Pet download failed: HTTP ${response.status}`);
      }
      if (response.headers.get('content-type')?.includes('text/html')) {
        throw new Error('Pet download returned HTML');
      }
      const buffer = Buffer.from(await response.arrayBuffer());
      if (buffer.length < 100_000) throw new Error('Pet archive is too small');
      return buffer;
    } catch (error) {
      if (attempt === 3) throw error;
      await setTimeout(1000 * attempt);
    }
  }
}

export async function installPet(binDirectory) {
  const checksum = checksums[`${process.platform}_${process.arch}`];
  if (!checksum) throw new Error(`Unsupported Pet platform: ${process.platform}/${process.arch}`);
  const directory = path.resolve(binDirectory);
  const temporary = await mkdtemp(path.join(tmpdir(), 'setupvibe-pet-'));
  const executable = process.platform === 'win32' ? 'pet.exe' : 'pet';
  const destination = path.join(directory, executable);
  const staged = path.join(directory, `.pet-${randomUUID()}`);
  const env = { ...process.env, PET_CONFIG_DIR: temporary };
  const expectedVersion = `pet version ${version}`;

  try {
    const selector = spawnSync('fzf', ['--version'], { encoding: 'utf8' });
    if (selector.error || selector.status !== 0) throw new Error('Pet requires a working fzf command');
    const existing = spawnSync(destination, ['version'], { encoding: 'utf8', env });
    if (existing.status === 0 && existing.stdout.trim() === expectedVersion) {
      console.log(`${expectedVersion} already installed; snippets preserved`);
      return;
    }

    const os = process.platform === 'win32' ? 'windows' : 'linux';
    const arch = process.arch === 'x64' ? 'amd64' : process.arch;
    const archive = `pet_${version}_${os}_${arch}.tar.gz`;
    const buffer = await download(`https://github.com/knqyf263/pet/releases/download/v${version}/${archive}`);
    verifyArchive(buffer, checksum);
    const archivePath = path.join(temporary, archive);
    await writeFile(archivePath, buffer);
    const tar = process.platform === 'win32' ? 'tar.exe' : 'tar';
    const extraction = spawnSync(tar, ['-xzf', archivePath, '-C', temporary], { stdio: 'inherit' });
    if (extraction.error || extraction.status !== 0) throw new Error('Could not extract the Pet archive');
    const payload = path.join(temporary, executable);
    const check = spawnSync(payload, ['version'], { encoding: 'utf8', env });
    if (check.error || check.status !== 0 || check.stdout.trim() !== expectedVersion) {
      throw new Error('Pet release binary did not pass its version check');
    }
    await mkdir(directory, { recursive: true });
    await copyFile(payload, staged, constants.COPYFILE_EXCL);
    await chmod(staged, 0o755);
    await rename(staged, destination);
    console.log(`${expectedVersion} installed in ${directory}; snippets preserved`);
  } finally {
    await rm(staged, { force: true });
    await rm(temporary, { recursive: true, force: true });
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  try {
    const { values } = parseArgs({ options: { 'bin-dir': { type: 'string' } } });
    if (!values['bin-dir']) throw new Error('--bin-dir is required');
    await installPet(values['bin-dir']);
  } catch (error) {
    console.error(`Pet installation failed: ${error.message}`);
    process.exitCode = 1;
  }
}
