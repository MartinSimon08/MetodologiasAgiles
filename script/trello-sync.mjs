import { appendFileSync, readFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';

export const lists = {
  backlog: 'Sprint Backlog',
  review: 'En Revisión / Esperando Merge',
  done: 'Hecho',
};

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
  for (const snapshot of cards) {
    const card = await trello(`/cards/${snapshot.id}`);
    if (card.closed || card.isTemplate || card.idBoard !== board.id || card.idList !== backlog.id) continue;
    let issue = existing.get(card.id);
    if (!issue) {
      if (dryRun) {
        report(`CREAR: ${card.name} (${card.shortUrl})`);
        continue;
      }
      issue = await github('/issues', 'POST', {
        title: card.name,
        body: `${card.desc ?? ''}\n\nTrello: ${card.shortUrl}\n\n<!-- trello-card:${card.id} -->`,
      });
      existing.set(card.id, issue);
      report(`CREADO: #${issue.number} — ${card.name}`);
    } else {
      report(`EXISTENTE: #${issue.number} — ${card.name}`);
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
