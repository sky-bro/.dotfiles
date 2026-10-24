#!/usr/bin/env node
// Use the installed dsh dependencies and credential store; never print a grant.
import { createRequire } from 'node:module';
import { pathToFileURL } from 'node:url';
import { homedir } from 'node:os';
import { join } from 'node:path';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { randomUUID } from 'node:crypto';
import { createInterface } from 'node:readline/promises';

const require = createRequire(join(homedir(), '.local/lib/node_modules/@deepseek-ai/dsh/package.json'));
const load = (name) => import(pathToFileURL(require.resolve(name)).href);
const command = process.argv[2] ?? 'status';
if (!['status', 'login', 'logout'].includes(command)) {
  console.error('Usage: node config/dsh/codex-login.mjs [status|login|logout] [--device]');
  process.exit(2);
}
const { Context } = await load('@deepseek-ai/cordis');
const { default: Credentials } = await load('@deepseek-ai/dsh-credentials-local');
const { credentialKey } = await load('@deepseek-ai/dsh-credentials');
// pi-ai exports are import-only; resolve the installed ESM file explicitly.
const { openaiCodexProvider } = await import(pathToFileURL(join(homedir(), '.local/lib/node_modules/@deepseek-ai/dsh/node_modules/@earendil-works/pi-ai/dist/providers/openai-codex.js')).href);
const dshHome = process.env.DSH_HOME ?? join(homedir(), '.dsh');
const ctx = new Context();
const fiber = ctx.plugin(Credentials, { dshHome, watch: false });
let rl;
try {
  await fiber.await();
  const key = credentialKey('llm-pi-ai', 'openai-codex');
  if (command === 'status') {
    const record = await ctx.credentials.readRecord(key);
    console.log(record?.kind === 'grant' ? 'Codex OAuth credential configured in dsh.' : 'Codex OAuth is not configured in dsh.');
  } else if (command === 'logout') {
    await ctx.credentials.deleteRecord(key);
    console.log('Removed dsh Codex login. Codex CLI login is unchanged.');
  } else {
    await mkdir(dshHome, { recursive: true, mode: 0o700 });
    const deviceFile = join(dshHome, 'codex-device-id');
    let deviceId;
    try { deviceId = (await readFile(deviceFile, 'utf8')).trim(); }
    catch (error) {
      if (error.code !== 'ENOENT') throw error;
      deviceId = randomUUID();
      await writeFile(deviceFile, deviceId + '\n', { mode: 0o600, flag: 'wx' });
    }
    const abort = new AbortController();
    process.once('SIGINT', () => abort.abort());
    const credential = await openaiCodexProvider().auth.oauth.login({
      signal: abort.signal,
      notify(event) {
        if (event.type === 'auth_url') console.log('\nOpen this URL in your browser:\n' + event.url);
        else if (event.type === 'device_code') console.log('\nOpen ' + event.verificationUri + '\nEnter code: ' + event.userCode);
        else if (event.message) console.log(event.message);
      },
      async prompt(question) {
        if (question.type === 'select' && question.options.some(o => o.id === 'browser')) {
          return process.argv.includes('--device') ? 'device_code' : 'browser';
        }
        if (!process.stdin.isTTY) throw new Error('Additional input required; run this login command in a real terminal.');
        rl ??= createInterface({ input: process.stdin, output: process.stdout });
        return rl.question(question.message + ': ', { signal: question.signal ?? abort.signal });
      },
    }, { getDeviceId: () => deviceId });
    await ctx.credentials.modifyRecord(key, () => ({ kind: 'grant', payload: credential }));
    console.log('Codex OAuth saved securely to the dsh credential store.');
  }
} catch (error) {
  // OAuth failures may contain transport details. Avoid dumping response bodies.
  console.error('dsh Codex login failed (' + (error.cause?.code ?? error.code ?? error.name) + '). Retry in a real terminal.');
  process.exitCode = 1;
} finally {
  rl?.close();
  await fiber.dispose();
}
