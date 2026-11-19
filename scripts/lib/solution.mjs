export const answerHeadings = [
  'Summary',
  'A1. Current state',
  'A2. Production risks',
  'A3. Improvements',
  'A4. Cloud-agnostic and on-premises',
  'B1. Know before the customer does',
  'B2. Who is told what',
  'B3. Performance degradation',
  'B4. User behaviour and product improvement',
  'B5. Path to 99.9 %',
  'C1. Environment copies and provider pins',
  'C2. Cross-state reads and apply order',
  'C3. Dead code and stale imports',
  'C4. First-boot configuration and run commands',
  'C5. Local infrastructure checks',
  'C6. Infrastructure code in TypeScript',
  'Roadmap (next 90 days)',
  'What I would do next',
  'Assumptions and open questions',
  'Tools and AI used',
  'R1. Work summary',
  'R2. What went well',
  'R3. What went badly and troubles encountered',
  'R4. Where the AI was wrong',
  'R5. Where I disagree with the AI',
  'R6. Agentic delivery',
];

const NAME_FIELD = /^\**\s*(first name|vorname|last name|nachname)\s*:?\s*\**\s*:?\s*(.*)$/i;

// The "First name" and "Last name" fields at the top of SOLUTION.md, before the first section.
export function candidateName(text) {
  const name = { firstName: '', lastName: '' };
  const preamble = text.replace(/<!--[\s\S]*?-->/g, '').split(/\r?\n(?=#{2,3}\s)/)[0];
  for (const line of preamble.split(/\r?\n/)) {
    const field = NAME_FIELD.exec(line.replace(/^\s*[-*+]\s+/, ''));
    if (!field) continue;
    const value = field[2].replace(/^[\s_*]+|[\s_*]+$/g, '');
    if (/^your (?:first|last) name$/i.test(value)) continue;
    name[/^(?:first name|vorname)$/i.test(field[1]) ? 'firstName' : 'lastName'] = value;
  }
  return name;
}

export function checkSolution(text, changedFiles) {
  const sections = new Map();
  let body;
  let fence;
  // Ignore headings inside fenced code, HTML hints and the template's visible prompts.
  for (const line of text.replace(/<!--[\s\S]*?-->/g, '').split(/\r?\n/)) {
    const marker = /^\s*(`{3,}|~{3,})/.exec(line)?.[1];
    if (marker && (!fence || (marker[0] === fence[0] && marker.length >= fence.length))) {
      fence = fence ? undefined : marker;
      body?.push(line);
      continue;
    }
    const heading = !fence && /^#{2,3}\s+(.*)$/.exec(line);
    if (heading) {
      body = [];
      sections.set(heading[1].trim(), body);
    } else if (body && (fence || (!line.startsWith('>') && line.trim() !== '_Your answer here._'))) {
      body.push(line);
    }
  }
  const warnings = [];
  const { firstName, lastName } = candidateName(text);
  if (!firstName || !lastName) warnings.push('Missing name: fill in First name and Last name at the top of SOLUTION.md');
  for (const title of answerHeadings) {
    if (!sections.has(title)) warnings.push(`Missing heading: ${title}`);
    else if (!sections.get(title).join('\n').trim()) warnings.push(`Still empty: ${title}`);
  }
  const hasCode = (title) => {
    const content = (sections.get(title) ?? []).join('\n');
    return /(?:^|\n)\s*(`{3,}|~{3,})[^\n]*\n[\s\S]*?\S[\s\S]*?\n\s*\1/.test(content)
      || changedFiles.some((file) => file !== 'SOLUTION.md' && !file.startsWith('assets/') && content.includes(file));
  };
  for (const title of ['A3. Improvements', 'B1. Know before the customer does']) {
    if (!hasCode(title)) warnings.push(`No code block or changed-file reference found: ${title}`);
  }
  if (!answerHeadings.filter((title) => /^C[1-6]\./.test(title)).some(hasCode)) {
    warnings.push('No code block or changed-file reference found: choose one C1–C6 implementation');
  }
  return warnings;
}
