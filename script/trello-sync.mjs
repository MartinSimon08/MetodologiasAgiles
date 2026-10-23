import { appendFileSync, readFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';

export const lists = {
  backlog: 'Sprint Backlog',
  review: 'En Revisión / Esperando Merge',
  done: 'Hecho',
};

const professorName = 'emilio';

export const participants = [
  { login: 'MartinSimon08', aliases: ['martin simon', 'martinsimon', 'martinforlini', 'martin'] },
  { login: 'mateolafalce', aliases: ['mateo lafalce', 'mateolafalce', 'lafalce', 'mateo'] },
  { login: 'MatiDelozano', aliases: ['matias delozano', 'matidelozano', 'delozano', 'matias'] },
  { login: 'ValentnTorres', aliases: ['valentin torres', 'valentntorres', 'valentin', 'torres'] },
  { login: 'fetcpao', aliases: ['fermin etchanchu', 'etchanchu', 'paoltroni', 'fetcpao', 'fermin', 'fer'] },
];

const trelloColors = {
  green: '61bd4f',
  yellow: 'f2d600',
  orange: 'ff9f1a',
  red: 'eb5a46',
  purple: 'c377e0',
  blue: '0079bf',
  sky: '00c2e0',
  lime: '51e898',
  pink: 'ff78cb',
  black: '344563',
};

function normalize(value) {
  return value.normalize('NFD').replace(/\p{M}/gu, '').toLowerCase();
}

function matchesAlias(text, alias) {
  const needle = normalize(alias);
  if (needle.length < 4) return new RegExp(`(?:^|[^a-z0-9])${needle}(?:[^a-z0-9]|$)`).test(text);
  return text.includes(needle);
}

export function resolveMember(member, people = participants) {
  const text = normalize(`${member.fullName ?? ''} ${member.username ?? ''}`);
  if (text.includes(professorName)) return { role: 'profesor' };
  const username = normalize(member.username ?? '');
  const byLogin = people.find(person => normalize(person.login) === username);
  if (byLogin) return { login: byLogin.login };
  const matches = people.filter(person => person.aliases.some(alias => matchesAlias(text, alias)));
  if (matches.length === 1) return { login: matches[0].login };
  if (matches.length > 1) return { ambiguous: matches.map(person => person.login) };
  return { unmapped: true };
}

function memberLabel(member) {
  return member.fullName || member.username || member.id;
}

export function cardAssignment(card, membersById, people = participants) {
  const logins = [];
  const notes = [];
  const seen = new Set();
  for (const memberId of card.idMembers ?? []) {
    const member = membersById.get(memberId);
    if (!member) {
      notes.push(`SIN MAPEO: miembro ${memberId} en ${card.name}`);
      continue;
    }
    const resolved = resolveMember(member, people);
    if (resolved.login && !seen.has(resolved.login)) {
      seen.add(resolved.login);
      logins.push(resolved.login);
    } else if (resolved.ambiguous) {
      notes.push(`MAPEO AMBIGUO: ${memberLabel(member)} coincide con ${resolved.ambiguous.join(', ')}`);
    } else if (resolved.unmapped) {
      notes.push(`SIN MAPEO: ${memberLabel(member)} en ${card.name}`);
    }
  }
  const labelList = [];
  const labelNames = new Set();
  for (const label of card.labels ?? []) {
    const name = (label.name ?? '').trim();
    if (!name) {
      if (label.color) notes.push(`ETIQUETA SIN NOMBRE: ${label.color} en ${card.name}`);
      continue;
    }
    if (labelNames.has(name)) continue;
    labelNames.add(name);
    labelList.push({ name, color: trelloColors[label.color] ?? 'ededed' });
  }
  return { logins, labelList, notes };
}

function namesOf(values, key) {
  return (values ?? []).map(value => value[key] ?? value);
}

function sameSet(left, right) {
  const a = [...left].sort();
  const b = [...right].sort();
  return a.length === b.length && a.every((value, index) => value === b[index]);
}

function detail(logins, labelNames) {
  const parts = [];
  if (logins.length) parts.push(`responsables: ${logins.join(', ')}`);
  if (labelNames.length) parts.push(`etiquetas: ${labelNames.join(', ')}`);
  return parts.length ? ` | ${parts.join(' | ')}` : '';
}

async function githubLabels(github) {
  const known = new Map();
  for (let page = 1; ; page++) {
    const batch = await github(`/labels?per_page=100&page=${page}`);
    for (const label of batch) known.set(label.name, label);
    if (batch.length < 100) break;
  }
  return known;
}

async function ensureLabels(github, labelList, { dryRun, report }) {
  if (!labelList.length) return;
  const known = await githubLabels(github);
  for (const label of labelList) {
    if (known.has(label.name)) continue;
    if (dryRun) {
      report(`CREAR ETIQUETA: ${label.name}`);
      continue;
    }
    await github('/labels', 'POST', { name: label.name, color: label.color });
    known.set(label.name, label);
  }
}

export function issueNumbers(body = '') {
  const text = body.replace(/<!--[\s\S]*?-->/g, '').replace(/```[\s\S]*?```/g, '');
  return [...new Set([...text.matchAll(/^\s*(?:close[sd]?|fix(?:e[sd])?|resolve[sd]?)\s+#([1-9]\d*)\s*[.!]?\s*$/gim)]
    .map(match => Number(match[1])))];
}

export function cardId(body = '') {
  return body.match(/^<!-- trello-card:([a-f0-9]{24}) -->$/m)?.[1];
}

export function findList(all, name) {
  const matches = all.filter(list => !list.closed && list.name === name);
  if (matches.length !== 1) throw new Error(`Se esperaba una única lista abierta: ${name}`);
  return matches[0];
}

export async function importCards({ trello, github, board, dryRun, report }) {
  const backlog = findList(await trello(`/boards/${board.id}/lists`), lists.backlog);
  const cards = await trello(`/lists/${backlog.id}/cards`);
  const existing = new Map();
  for (let page = 1; ; page++) {
    const issues = await github(`/issues?state=all&per_page=100&page=${page}`);
    for (const issue of issues) {
      const id = !issue.pull_request && cardId(issue.body ?? '');
      if (!id) continue;
      if (existing.has(id)) throw new Error(`Hay varios issues para la tarjeta ${id}. Resolver antes de importar.`);
      existing.set(id, issue);
    }
    if (issues.length < 100) break;
  }
  const memberList = await trello(`/boards/${board.id}/members?fields=id,fullName,username`);
  const membersById = new Map(memberList.map(member => [member.id, member]));
  for (const snapshot of cards) {
    const card = await trello(`/cards/${snapshot.id}`);
    if (card.closed || card.isTemplate || card.idBoard !== board.id || card.idList !== backlog.id) continue;
    const { logins, labelList, notes } = cardAssignment(card, membersById);
    for (const note of notes) report(note);
    const labelNames = labelList.map(label => label.name);
    let issue = existing.get(card.id);
    if (!issue) {
      if (dryRun) {
        await ensureLabels(github, labelList, { dryRun, report });
        report(`CREAR: ${card.name} (${card.shortUrl})${detail(logins, labelNames)}`);
        continue;
      }
      await ensureLabels(github, labelList, { dryRun, report });
      const payload = {
        title: card.name,
        body: `${card.desc ?? ''}\n\nTrello: ${card.shortUrl}\n\n<!-- trello-card:${card.id} -->`,
      };
      if (logins.length) payload.assignees = logins;
      if (labelNames.length) payload.labels = labelNames;
      issue = await github('/issues', 'POST', payload);
      existing.set(card.id, issue);
      report(`CREADO: #${issue.number} — ${card.name}`);
    } else {
      report(`EXISTENTE: #${issue.number} — ${card.name}`);
      const patch = {};
      if (logins.length && !sameSet(namesOf(issue.assignees, 'login'), logins)) patch.assignees = logins;
      if (labelNames.length && !sameSet(namesOf(issue.labels, 'name'), labelNames)) patch.labels = labelNames;
      if (Object.keys(patch).length) {
        await ensureLabels(github, labelList, { dryRun, report });
        if (dryRun) {
          report(`ACTUALIZAR: #${issue.number}${detail(logins, labelNames)}`);
        } else {
          issue = await github(`/issues/${issue.number}`, 'PATCH', patch);
          existing.set(card.id, issue);
          report(`ACTUALIZADO: #${issue.number} ${card.name}`);
        }
      }
    }
    const attachments = await trello(`/cards/${card.id}/attachments`);
    if (!attachments.some(attachment => attachment.url === issue.html_url)) {
      if (dryRun) report(`ENLAZAR: #${issue.number} → ${card.shortUrl}`);
      else await trello(`/cards/${card.id}/attachments`, 'POST', { url: issue.html_url, name: `GitHub issue #${issue.number}` });
    }
  }
  report(dryRun ? 'Vista previa finalizada. No se modificó GitHub ni Trello.' : 'Importación finalizada.');
}

export async function syncPullRequest({ trello, github, board, number, repository, defaultBranch, report }) {
  const pr = await github(`/pulls/${number}`);
  if (pr.base.ref !== defaultBranch || pr.head.repo?.full_name !== repository ||
      !['OWNER', 'MEMBER', 'COLLABORATOR'].includes(pr.author_association)) {
    report('PR fuera del alcance de la integración.');
    return;
  }
  if ((!pr.merged && pr.state !== 'open') || pr.draft) {
    report('PR cerrado sin merge o en borrador: no se mueve ninguna tarjeta.');
    return;
  }
  const numbers = issueNumbers(pr.body ?? '');
  if (!numbers.length) {
    report('Sin referencias. Usar una línea independiente: Closes #123');
    return;
  }
  const destination = findList(await trello(`/boards/${board.id}/lists`), pr.merged ? lists.done : lists.review);
  const done = findList(await trello(`/boards/${board.id}/lists`), lists.done);
  for (const issueNumber of numbers) {
    const issue = await github(`/issues/${issueNumber}`);
    const id = !issue.pull_request && cardId(issue.body ?? '');
    if (!id) {
      report(`OMITIDO: #${issueNumber} no tiene una tarjeta importada.`);
      continue;
    }
    const card = await trello(`/cards/${id}`);
    if (card.closed || card.idBoard !== board.id || (!pr.merged && card.idList === done.id)) {
      report(`OMITIDO: #${issueNumber}, tarjeta archivada, ajena al tablero o ya terminada.`);
      continue;
    }
    if (card.idList !== destination.id) await trello(`/cards/${id}`, 'PUT', { idList: destination.id });
    report(`#${issueNumber} → ${destination.name}`);
  }
}

export function apiClient(base, headers) {
  return async (path, method = 'GET', body) => {
    let response;
    try {
      response = await fetch(`${base}${path}`, {
        method,
        headers: { ...headers, 'Content-Type': 'application/json' },
        body: body === undefined ? undefined : JSON.stringify(body),
        signal: AbortSignal.timeout(30000),
        redirect: 'error',
      });
    } catch {
      throw new Error(`${method} ${path.split('?')[0]}: error de red o timeout. Revisar antes de reintentar.`);
    }
    if (!response.ok) throw new Error(`${method} ${path.split('?')[0]}: HTTP ${response.status}`);
    return response.status === 204 ? undefined : response.json();
  };
}

async function main() {
  for (const name of ['TRELLO_API_KEY', 'TRELLO_TOKEN', 'GITHUB_TOKEN', 'GITHUB_REPOSITORY', 'GITHUB_EVENT_PATH']) {
    if (!process.env[name]) throw new Error(`Falta configurar ${name}`);
  }
  const event = JSON.parse(readFileSync(process.env.GITHUB_EVENT_PATH, 'utf8'));
  const repository = process.env.GITHUB_REPOSITORY;
  const trello = apiClient('https://api.trello.com/1', {
    Authorization: `OAuth oauth_consumer_key="${process.env.TRELLO_API_KEY}", oauth_token="${process.env.TRELLO_TOKEN}"`,
  });
  const github = apiClient(`https://api.github.com/repos/${repository}`, {
    Authorization: `Bearer ${process.env.GITHUB_TOKEN}`,
    Accept: 'application/vnd.github+json',
    'X-GitHub-Api-Version': '2022-11-28',
  });
  const report = line => {
    console.log(JSON.stringify(line));
    if (process.env.GITHUB_STEP_SUMMARY) {
      const escaped = line.replace(/[&<>]/g, character => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;' })[character]);
      appendFileSync(process.env.GITHUB_STEP_SUMMARY, `<pre>${escaped}</pre>\n`);
    }
  };
  const board = await trello('/boards/S2Asw6vB');
  if (board.closed) throw new Error('El tablero está archivado.');
  const context = { trello, github, board, report, repository, defaultBranch: event.repository.default_branch };
  if (process.env.GITHUB_EVENT_NAME === 'workflow_dispatch') {
    await importCards({ ...context, dryRun: process.env.DRY_RUN !== 'false' });
  } else if (process.env.GITHUB_EVENT_NAME === 'pull_request_target') {
    await syncPullRequest({ ...context, number: event.pull_request.number });
  } else {
    throw new Error('Evento no admitido.');
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main().catch(error => {
    console.error(error.message);
    process.exitCode = 1;
  });
}
