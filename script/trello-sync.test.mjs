import test from 'node:test';
import assert from 'node:assert/strict';
import { importCards, syncPullRequest, issueNumbers, findList, lists, resolveMember } from './trello-sync.mjs';

const id = '0123456789abcdef01234567';
const marker = `<!-- trello-card:${id} -->`;

function fixture() {
  const state = {
    card: { id, idBoard: 'board', idList: 'backlog', name: 'HU18', desc: 'Descripción', shortUrl: 'https://trello.com/c/abcd1234' },
    issues: [], attachments: [], writes: [], reports: [], members: [], repoLabels: [],
    pr: { number: 7, state: 'open', draft: false, merged: false, body: 'Closes #1', base: { ref: 'main' }, head: { repo: { full_name: 'owner/repo' } }, author_association: 'COLLABORATOR' },
  };
  const trello = async (path, method = 'GET', body) => {
    if (method !== 'GET') {
      state.writes.push({ service: 'trello', path, method, body });
      if (method === 'PUT') Object.assign(state.card, body);
      else state.attachments.push(body);
      return {};
    }
    if (path.endsWith('/lists')) return Object.entries(lists).map(([id, name]) => ({ id, name }));
    if (path === '/lists/backlog/cards') return [state.card];
    if (path.endsWith('/attachments')) return state.attachments;
    if (path.startsWith('/boards/board/members')) return state.members;
    if (path === `/cards/${id}`) return state.card;
    throw new Error(`Unexpected Trello call: ${path}`);
  };
  const github = async (path, method = 'GET', body) => {
    if (method === 'POST' && path === '/labels') {
      state.writes.push({ service: 'github', path, method, body });
      const label = { name: body.name, color: body.color };
      state.repoLabels.push(label);
      return label;
    }
    if (method === 'PATCH') {
      state.writes.push({ service: 'github', path, method, body });
      const issue = state.issues[0];
      if (body.assignees) issue.assignees = body.assignees.map(login => ({ login }));
      if (body.labels) issue.labels = body.labels.map(name => ({ name }));
      return issue;
    }
    if (method === 'POST') {
      state.writes.push({ service: 'github', path, method, body });
      const issue = { ...body, number: 1, html_url: 'https://github.com/owner/repo/issues/1' };
      state.issues.push(issue);
      return issue;
    }
    if (path.startsWith('/labels?')) return state.repoLabels;
    if (path.startsWith('/issues?')) return state.issues;
    if (path === '/issues/1') return state.issues[0];
    if (path === '/pulls/7') return state.pr;
    throw new Error(`Unexpected GitHub call: ${path}`);
  };
  return { state, context: { trello, github, board: { id: 'board' }, repository: 'owner/repo', defaultBranch: 'main', number: 7, report: line => state.reports.push(line) } };
}

test('vista previa no realiza escrituras', async () => {
  const { state, context } = fixture();
  await importCards({ ...context, dryRun: true });
  assert.equal(state.writes.length, 0);
  assert.match(state.reports[0], /CREAR: HU18/);
});

test('repetir importación conserva issue cerrado y adjunto sin duplicarlos', async () => {
  const { state, context } = fixture();
  await importCards({ ...context, dryRun: false });
  state.issues[0].state = 'closed';
  state.card.desc = 'Nueva descripción';
  await importCards({ ...context, dryRun: false });
  assert.equal(state.issues.length, 1);
  assert.equal(state.attachments.length, 1);
  assert.match(state.issues[0].body, /Descripción/);
  assert.equal(state.writes.length, 2);
});

test('reintento repara enlace faltante sin recrear issue', async () => {
  const { state, context } = fixture();
  state.issues.push({ number: 1, body: marker, html_url: 'https://github.com/owner/repo/issues/1' });
  await importCards({ ...context, dryRun: false });
  assert.equal(state.writes.length, 1);
  assert.equal(state.writes[0].service, 'trello');
});

test('omite tarjetas movidas, archivadas, de otro tablero y plantillas', async () => {
  for (const update of [{ idList: 'development' }, { closed: true }, { idBoard: 'other' }, { isTemplate: true }]) {
    const { state, context } = fixture();
    Object.assign(state.card, update);
    await importCards({ ...context, dryRun: false });
    assert.equal(state.writes.length, 0);
  }
});

test('referencias requieren palabra de cierre y línea independiente', () => {
  assert.deepEqual(issueNumbers('Closes #12\nFixes #13\nCloses #12\nMención #14\nCloses other/repo#15\n<!--\nCloses #16\n-->\n```\nCloses #17\n```'), [12, 13]);
});

test('PR abierto pasa a revisión y merge pasa a Hecho', async () => {
  const { state, context } = fixture();
  state.issues.push({ body: marker });
  await syncPullRequest(context);
  assert.equal(state.card.idList, 'review');
  state.pr.merged = true;
  state.pr.state = 'closed';
  await syncPullRequest(context);
  assert.equal(state.card.idList, 'done');
});

test('PR cerrado, borrador, externo o no autorizado no mueve tarjetas', async () => {
  for (const update of [{ state: 'closed' }, { draft: true }, { author_association: 'NONE' }, { head: { repo: { full_name: 'other/repo' } } }, { base: { ref: 'release' } }]) {
    const { state, context } = fixture();
    Object.assign(state.pr, update);
    await syncPullRequest(context);
    assert.equal(state.writes.length, 0);
  }
});

test('no retrocede Hecho ni mueve tarjetas ajenas o archivadas', async () => {
  for (const update of [{ idList: 'done' }, { idBoard: 'other' }, { closed: true }]) {
    const { state, context } = fixture();
    state.issues.push({ body: marker });
    Object.assign(state.card, update);
    await syncPullRequest(context);
    assert.equal(state.writes.length, 0);
  }
});

test('importación pagina issues antes de crear para evitar duplicados', async () => {
  const { state, context } = fixture();
  const original = context.github;
  context.github = (path, ...args) => {
    if (path.endsWith('page=1')) return Array.from({ length: 100 }, () => ({ body: '' }));
    if (path.endsWith('page=2')) return [{ number: 1, body: marker, html_url: 'https://github.com/owner/repo/issues/1' }];
    return original(path, ...args);
  };
  await importCards({ ...context, dryRun: false });
  assert.equal(state.writes.length, 1);
  assert.equal(state.writes[0].service, 'trello');
});

test('el profesor no es participante y el resto mapea a su usuario de GitHub', () => {
  assert.deepEqual(resolveMember({ fullName: 'Emilio López', username: 'emilio' }), { role: 'profesor' });
  assert.equal(resolveMember({ fullName: 'Martin Simon', username: 'martin' }).login, 'MartinSimon08');
  assert.equal(resolveMember({ fullName: 'Mateo Lafalce', username: 'mateolafalce' }).login, 'mateolafalce');
  assert.equal(resolveMember({ fullName: 'Matias Delozano', username: 'mdelozano' }).login, 'MatiDelozano');
  assert.equal(resolveMember({ fullName: 'Valentín Torres', username: 'valentin' }).login, 'ValentnTorres');
  assert.equal(resolveMember({ fullName: 'Fer', username: 'fer' }).login, 'fetcpao');
  assert.equal(resolveMember({ fullName: 'Juan Pérez', username: 'juan' }).unmapped, true);
  assert.deepEqual(resolveMember({ fullName: 'Ana', username: 'ana' }, [
    { login: 'a', aliases: ['ana'] },
    { login: 'b', aliases: ['ana'] },
  ]).ambiguous, ['a', 'b']);
});

test('importación asigna participantes, omite al profesor y copia etiquetas', async () => {
  const { state, context } = fixture();
  state.members = [
    { id: 'mateo', fullName: 'Mateo Lafalce', username: 'mateolafalce' },
    { id: 'emilio', fullName: 'Emilio López', username: 'emilio' },
    { id: 'fer', fullName: 'Fermín Etchanchú', username: 'fetcpao' },
    { id: 'juan', fullName: 'Juan Pérez', username: 'juan' },
  ];
  state.card.idMembers = ['mateo', 'emilio', 'fer', 'juan', 'ausente'];
  state.card.labels = [
    { name: 'Backend', color: 'blue' },
    { name: 'Backend', color: 'blue' },
    { name: '', color: 'red' },
    { name: 'Sprint II', color: 'yellow' },
  ];
  await importCards({ ...context, dryRun: false });
  const created = state.writes.find(write => write.path === '/issues');
  assert.deepEqual(created.body.assignees, ['mateolafalce', 'fetcpao']);
  assert.deepEqual(created.body.labels, ['Backend', 'Sprint II']);
  assert.deepEqual(state.repoLabels.map(label => label.name), ['Backend', 'Sprint II']);
  assert.equal(state.repoLabels[0].color, '0079bf');
  assert.match(state.reports.join('\n'), /SIN MAPEO: Juan Pérez/);
  assert.match(state.reports.join('\n'), /SIN MAPEO: miembro ausente/);
  assert.match(state.reports.join('\n'), /ETIQUETA SIN NOMBRE: red/);
  assert.equal(state.reports.some(line => /emilio/i.test(line)), false);
});

test('vista previa informa responsables y etiquetas sin escribir', async () => {
  const { state, context } = fixture();
  state.members = [{ id: 'martin', fullName: 'Martin Simon', username: 'martin' }];
  state.card.idMembers = ['martin'];
  state.card.labels = [{ name: 'Frontend', color: 'green' }];
  await importCards({ ...context, dryRun: true });
  assert.equal(state.writes.length, 0);
  assert.match(state.reports.join('\n'), /CREAR: HU18.*responsables: MartinSimon08/);
  assert.match(state.reports.join('\n'), /etiquetas: Frontend/);
  assert.match(state.reports.join('\n'), /CREAR ETIQUETA: Frontend/);
});

test('reimportar actualiza responsables y no repite la actualización', async () => {
  const { state, context } = fixture();
  state.members = [{ id: 'vali', fullName: 'Valentín Torres', username: 'valentin' }];
  state.card.idMembers = ['vali'];
  state.card.labels = [{ name: 'Backend', color: 'blue' }];
  state.repoLabels = [{ name: 'Backend', color: '0079bf' }];
  state.issues.push({ number: 1, body: marker, html_url: 'https://github.com/owner/repo/issues/1', assignees: [], labels: [] });
  await importCards({ ...context, dryRun: false });
  assert.equal(state.writes.filter(write => write.method === 'PATCH').length, 1);
  assert.deepEqual(state.writes.find(write => write.method === 'PATCH').body, {
    assignees: ['ValentnTorres'],
    labels: ['Backend'],
  });
  const writes = state.writes.length;
  await importCards({ ...context, dryRun: false });
  assert.equal(state.writes.length, writes);
});

test('listas ausentes o ambiguas y relaciones duplicadas fallan sin escrituras', async () => {
  assert.throws(() => findList([], lists.backlog));
  assert.throws(() => findList([{ name: lists.backlog }, { name: lists.backlog }], lists.backlog));
  const { state, context } = fixture();
  state.issues.push({ body: marker }, { body: marker });
  await assert.rejects(importCards({ ...context, dryRun: false }), /varios issues/);
  assert.equal(state.writes.length, 0);
});
