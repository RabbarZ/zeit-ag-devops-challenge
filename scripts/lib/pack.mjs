import { createHash } from 'node:crypto';
import path from 'node:path';

export const MANIFEST = '.pack-manifest.json';
export const RECEIPT = 'HANDIN.json';
const excludedDirectories = new Set(['.git', 'node_modules', '.terraform', '.terraform-cache', 'dist', 'handin', 'interviewer']);

export const checksum = (data) => createHash('sha256').update(data).digest('hex');

export const isSafePath = (name) => Boolean(name) && !/[\\:\x00]/.test(name)
  && !name.startsWith('/') && !name.split('/').includes('..') && name === path.posix.normalize(name);

export function isPackFile(name) {
  const parts = name.split('/');
  const base = parts.at(-1);
  return !parts.some((part) => excludedDirectories.has(part))
    && ![MANIFEST, RECEIPT, '.gitattributes', '.DS_Store'].includes(base)
    && !/^\.env(?:\.|$)/.test(base)
    && !/\.tfstate(?:\.|$)|\.tfplan$|^crash\.log/.test(base);
}

export function readManifest(text) {
  const manifest = JSON.parse(text);
  if (manifest.version !== 1 || !/^[a-f0-9]{40,64}$/.test(manifest.commit ?? '')
      || !manifest.files || Array.isArray(manifest.files) || typeof manifest.files !== 'object'
      || !Object.hasOwn(manifest.files, 'SOLUTION.md')) {
    throw new Error('Invalid pack manifest.');
  }
  for (const [name, hash] of Object.entries(manifest.files)) {
    if (!isSafePath(name) || !isPackFile(name) || !/^[a-f0-9]{64}$/.test(hash)) {
      throw new Error(`Invalid manifest entry: ${name}`);
    }
  }
  return manifest;
}
