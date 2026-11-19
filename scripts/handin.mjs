// Collects the answer, diagrams and source changes without Git or npm dependencies.
// With .pack-manifest.json, changes and deletions are recorded exactly. A plain ZIP download has no
// manifest: the whole folder is handed back, and the interviewer works out the changes from the repository.
import { existsSync, mkdirSync, readdirSync, readFileSync, renameSync, rmSync, statSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { checksum, isPackFile, isSafePath, MANIFEST, readManifest, RECEIPT } from './lib/pack.mjs';
import { checkSolution } from './lib/solution.mjs';
import { createZip } from './lib/zip.mjs';

const NAME = 'acme-planner-solution';
const OUT = path.join('handin', `${NAME}.zip`);
const temporary = `${OUT}.${process.pid}.tmp`;
const PLAIN_WARNING = 'No .pack-manifest.json here, so this is a plain ZIP: every file is included and changes are not recorded. The interviewer compares it with the original pack; list any files you deleted in SOLUTION.md.';

try {
  if (!existsSync('SOLUTION.md')) throw new Error('SOLUTION.md not found. Run this from the folder that contains README.md.');
  if (existsSync(RECEIPT)) throw new Error(`${RECEIPT} is reserved for the generated hand-in receipt. Rename your file and try again.`);
  const baseline = existsSync(MANIFEST) ? readManifest(readFileSync(MANIFEST, 'utf8')) : null;
  const current = new Map();
  const walk = (dir = '') => {
    for (const entry of readdirSync(dir || '.', { withFileTypes: true })) {
      const name = dir ? `${dir}/${entry.name}` : entry.name;
      if (!isPackFile(name)) continue;
      if (!isSafePath(name)) throw new Error(`Filename is not portable: ${name}. Rename it or ask for a manual handoff.`);
      if (entry.isSymbolicLink()) throw new Error(`Symbolic links are not supported: ${name}. Use regular files, or ask for a manual handoff.`);
      if (entry.isDirectory()) walk(name);
      else if (entry.isFile()) current.set(name, readFileSync(name));
    }
  };
  walk();

  const answer = current.get('SOLUTION.md').toString('utf8');
  let files;
  let warnings;
  let receipt;
  if (baseline) {
    const added = [];
    const modified = [];
    for (const [name, data] of current) {
      if (!Object.hasOwn(baseline.files, name)) added.push(name);
      else if (checksum(data) !== baseline.files[name]) modified.push(name);
    }
    const deleted = Object.keys(baseline.files).filter((name) => !current.has(name)).sort();
    files = [...new Set(['SOLUTION.md', ...[...current.keys()].filter((name) => name.startsWith('assets/')), ...added, ...modified])].sort();
    warnings = checkSolution(answer, [...added, ...modified, ...deleted]);
    receipt = { baselineCommit: baseline.commit, added: added.sort(), modified: modified.sort(), deleted, included: files, warnings };
  } else {
    files = [...current.keys()].sort();
    warnings = [PLAIN_WARNING, ...checkSolution(answer, files)];
    receipt = { baselineCommit: null, added: null, modified: null, deleted: null, included: files, warnings };
  }
  const entries = files.map((name) => ({ name: `${NAME}/${name}`, data: current.get(name), mtime: statSync(name).mtime }));
  entries.push({ name: `${NAME}/${RECEIPT}`, data: Buffer.from(`${JSON.stringify(receipt, null, 2)}\n`) });
  const zip = createZip(entries);
  mkdirSync('handin', { recursive: true });
  writeFileSync(temporary, zip);
  renameSync(temporary, OUT);

  console.log(`Packed ${files.length} file(s), plus ${RECEIPT} (${baseline ? `baseline ${baseline.commit.slice(0, 7)}` : 'plain ZIP, no baseline'}):`);
  for (const file of files) console.log(`  ${file}`);
  for (const file of receipt.deleted ?? []) console.log(`  DELETED: ${file} (recorded in ${RECEIPT})`);
  if (warnings.length) {
    console.log('\nReminders only; unfinished work can still be handed in:');
    for (const warning of warnings) console.log(`  - ${warning}`);
  }
  console.log('\nThese checks do not validate code or prove that referenced files implement a change.');
  console.log(`Hand-in file: ${path.resolve(OUT)}\nCheck the file list, then ask the interviewer to copy the ZIP and confirm receipt.`);
} catch (error) {
  rmSync(temporary, { force: true });
  console.error(`Hand-in failed: ${error.message}\nNo new hand-in was written. Ask the interviewer to collect the whole working folder if needed.`);
  process.exit(1);
}
