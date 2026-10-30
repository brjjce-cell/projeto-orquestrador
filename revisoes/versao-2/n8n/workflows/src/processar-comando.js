// ============================================================
// Gestor - nó "Processar comando" (n8n Code, modo "Run Once for All Items")
// Fonte editável. O JSON do workflow é gerado por ../build-workflow.js.
//
// CONFIGURACAO: troque pelo SEU ID numerico do Telegram (nao e segredo, mas nao o versione).
// Enquanto estiver 'COLE_SEU_ID_AQUI', o bot responde APENAS em conversa privada,
// informando o ID de quem escreveu, e NAO executa comandos.
// ============================================================
const ALLOWED_ID = 'COLE_SEU_ID_AQUI';

const MAX_PENDING = 200;   // limite de tarefas PENDENTES (concluidas nao contam)
const KEEP_DONE = 100;     // concluidas mantidas no historico (as mais antigas sao apagadas)
const MAX_TEXT = 500;      // tamanho maximo da descricao
const MAX_REPLY = 3800;    // limite seguro p/ o teto de 4096 do Telegram
const SEEN_MAX = 200;      // update_ids recentes lembrados (anti-duplicidade)

const esc = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
const HELP = 'Comandos:\n/nova <texto> - cria tarefa\n/listar - lista pendentes\n/listar todas - lista todas\n/concluir <n> - conclui a tarefa n';

const out = [];
let store = null;
const getStore = () => {
  if (store) return store;
  store = $getWorkflowStaticData('global');
  if (!Array.isArray(store.tasks)) store.tasks = [];
  if (!Array.isArray(store.seen)) store.seen = [];
  const maxId = store.tasks.reduce((m, t) => Math.max(m, Number(t.id) || 0), 0);
  store.nextId = Math.max(Number(store.nextId) || 1, maxId + 1);
  return store;
};

const fmt = (t) => (t.done ? '[x] ' : '[ ] ') + '#' + t.id + ' ' + t.text;

for (const item of $input.all()) {
  const json = item.json || {};
  const msg = json.message;

  // Apenas mensagens de texto de pessoas, em conversa PRIVADA. Grupos/canais: silencio total
  // (assim nenhuma tarefa vaza para um grupo e o bot nao responde a ninguem la).
  if (!msg || typeof msg.text !== 'string' || !msg.chat || msg.chat.type !== 'private') continue;
  if (!msg.from || msg.from.is_bot) continue;

  const chatId = msg.chat.id;
  const fromId = String(msg.from.id);

  if (ALLOWED_ID === 'COLE_SEU_ID_AQUI') {
    out.push({ json: { chatId, reply: 'Bot ainda nao configurado. Seu ID do Telegram e: ' + fromId + '. Cole esse valor em ALLOWED_ID no no "Processar comando" do workflow.' } });
    continue;
  }
  if (fromId !== String(ALLOWED_ID)) continue;

  const s = getStore();

  // Anti-duplicidade: o Telegram reenvia o mesmo update se o webhook demorar/falhar.
  const uid = json.update_id;
  if (uid !== undefined && uid !== null) {
    if (s.seen.includes(uid)) continue;
    s.seen.push(uid);
    if (s.seen.length > SEEN_MAX) s.seen.splice(0, s.seen.length - SEEN_MAX);
  }

  const text = msg.text.replace(/[\u0000-\u001f\u007f]+/g, ' ').replace(/\s+/g, ' ').trim();
  const m = text.match(/^\/([A-Za-z0-9_]+)(?:@[A-Za-z0-9_]+)?(?:\s+(.*))?$/);
  const cmd = m ? m[1].toLowerCase() : '';
  const arg = m && m[2] ? m[2].trim() : '';
  let reply;

  switch (cmd) {
    case 'nova':
    case 'add': {
      if (!arg) { reply = 'Use: /nova <descricao da tarefa>'; break; }
      if (arg.length > MAX_TEXT) { reply = 'Descricao muito longa (max. ' + MAX_TEXT + ' caracteres).'; break; }
      const pending = s.tasks.filter((t) => !t.done).length;
      if (pending >= MAX_PENDING) { reply = 'Limite de ' + MAX_PENDING + ' tarefas pendentes atingido. Conclua algumas antes de criar novas.'; break; }
      const task = { id: s.nextId++, text: arg, done: false, createdAt: new Date().toISOString() };
      s.tasks.push(task);
      reply = 'Tarefa criada: ' + fmt(task);
      break;
    }
    case 'listar':
    case 'lista': {
      const a = arg.toLowerCase();
      if (a !== '' && a !== 'todas' && a !== 'todos') { reply = 'Use: /listar  ou  /listar todas'; break; }
      const all = a !== '';
      const list = s.tasks.filter((t) => all || !t.done);
      if (!list.length) { reply = all ? 'Nenhuma tarefa cadastrada.' : 'Nenhuma tarefa pendente.'; break; }
      const head = all ? 'Todas as tarefas:' : 'Tarefas pendentes:';
      let body = esc(head);
      let shown = 0;
      for (const t of list) {
        const line = '\n' + esc(fmt(t));
        // reserva espaco para o rodape "(+N nao exibidas)"
        if (body.length + line.length > MAX_REPLY - 40) break;
        body += line;
        shown++;
      }
      if (shown < list.length) body += '\n(+' + (list.length - shown) + ' nao exibidas)';
      reply = body;
      out.push({ json: { chatId, reply } });
      continue;
    }
    case 'concluir':
    case 'done': {
      const dm = arg.match(/^#?(\d{1,9})$/);
      const id = dm ? parseInt(dm[1], 10) : 0;
      if (!dm || id < 1) { reply = 'Use: /concluir <numero>  (ex.: /concluir 3)'; break; }
      const t = s.tasks.find((x) => x.id === id);
      if (!t) { reply = 'Tarefa #' + id + ' nao encontrada.'; break; }
      if (t.done) { reply = 'A tarefa #' + id + ' ja estava concluida.'; break; }
      t.done = true;
      t.doneAt = new Date().toISOString();
      // Poda: mantem so as KEEP_DONE concluidas mais recentes.
      const done = s.tasks.filter((x) => x.done).sort((a, b) => String(a.doneAt).localeCompare(String(b.doneAt)));
      const drop = new Set(done.slice(0, Math.max(0, done.length - KEEP_DONE)).map((x) => x.id));
      if (drop.size) s.tasks = s.tasks.filter((x) => !drop.has(x.id));
      reply = 'Concluida: ' + fmt(t);
      break;
    }
    default:
      reply = HELP;
  }

  out.push({ json: { chatId, reply: esc(reply) } });
}

return out;
