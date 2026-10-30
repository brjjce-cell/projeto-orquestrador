#!/usr/bin/env node
// Testa o nó "Processar comando" EXATAMENTE como entregue em gestor-tarefas-telegram.json.
// Simula $input e $getWorkflowStaticData (com serializacao JSON entre execucoes, como o n8n faz).
// Uso: node tests/test-workflow.js
'use strict';
const fs = require('fs');
const path = require('path');
const assert = require('assert');

const root = path.join(__dirname, '..');
const wfPath = path.join(root, 'n8n', 'workflows', 'gestor-tarefas-telegram.json');
const srcPath = path.join(root, 'n8n', 'workflows', 'src', 'processar-comando.js');
const wf = JSON.parse(fs.readFileSync(wfPath, 'utf8'));
const node = wf.nodes.find((n) => n.name === 'Processar comando');
const code = node.parameters.jsCode;

let passed = 0, failed = 0;
const test = (name, fn) => {
  try { fn(); passed++; console.log('  ok   ' + name); }
  catch (e) { failed++; console.log('  FAIL ' + name + '\n       ' + e.message.split('\n')[0]); }
};

const OWNER = 111222333;
function makeBot(allowedId = String(OWNER)) {
  const src = allowedId === null ? code : code.replace("const ALLOWED_ID = 'COLE_SEU_ID_AQUI';", "const ALLOWED_ID = '" + allowedId + "';");
  const fn = new Function('$input', '$getWorkflowStaticData', src);
  let persisted = {};
  let uid = 1000;
  const run = (updates) => {
    const live = JSON.parse(JSON.stringify(persisted)); // o n8n carrega do banco a cada execucao
    const items = updates.map((u) => ({ json: u }));
    const res = fn({ all: () => items, first: () => items[0] }, () => live);
    persisted = JSON.parse(JSON.stringify(live));
    return res.map((r) => r.json);
  };
  const upd = (text, o = {}) => ({
    update_id: o.update_id !== undefined ? o.update_id : ++uid,
    message: {
      message_id: 1,
      from: { id: o.from !== undefined ? o.from : OWNER, is_bot: !!o.bot },
      chat: { id: o.chat !== undefined ? o.chat : OWNER, type: o.type || 'private' },
      ...(o.noText ? {} : { text }),
    },
  });
  const say = (text, o) => { const r = run([upd(text, o)]); return r.length ? r[0].reply : null; };
  return { run, upd, say, store: () => persisted };
}

console.log('Fluxo - JSON entregue');
test('codigo do JSON == src/processar-comando.js (build em dia)', () => {
  assert.strictEqual(code, fs.readFileSync(srcPath, 'utf8').replace(/\n+$/, ''));
});
test('estrutura: Trigger -> Processar -> Responder; parse_mode HTML; sem credencial embutida', () => {
  assert.deepStrictEqual(Object.keys(wf.connections), ['Telegram Trigger', 'Processar comando']);
  const resp = wf.nodes.find((n) => n.name === 'Responder no Telegram');
  assert.strictEqual(resp.parameters.additionalFields.parse_mode, 'HTML');
  for (const n of wf.nodes.filter((x) => x.credentials)) assert.strictEqual(n.credentials.telegramApi.id, '');
});
test('ALLOWED_ID entregue e o placeholder (nenhum ID real versionado)', () => {
  assert.ok(code.includes("const ALLOWED_ID = 'COLE_SEU_ID_AQUI';"));
});

console.log('Configuracao / privacidade');
test('nao configurado: so informa o ID em conversa privada e nao executa comandos', () => {
  const b = makeBot(null);
  const r = b.say('/nova x');
  assert.ok(/Seu ID do Telegram e: 111222333/.test(r));
  assert.deepStrictEqual(b.store(), {});
});
test('nao configurado: em grupo fica em silencio (nao revela ID)', () => {
  const b = makeBot(null);
  assert.strictEqual(b.say('oi', { type: 'group', chat: -100123 }), null);
});
test('outro usuario (privado) e ignorado', () => {
  const b = makeBot();
  assert.strictEqual(b.say('/nova x', { from: 999, chat: 999 }), null);
  assert.deepStrictEqual(b.store(), {});
});
test('grupo/supergrupo/canal: silencio, mesmo sendo o dono', () => {
  const b = makeBot();
  for (const type of ['group', 'supergroup', 'channel']) {
    assert.strictEqual(b.say('/nova vaza?', { type, chat: -100777 }), null, type);
    assert.strictEqual(b.say('/listar', { type, chat: -100777 }), null, type);
  }
  assert.deepStrictEqual(b.store(), {});
});
test('mensagens de bots, sem texto ou sem message sao ignoradas', () => {
  const b = makeBot();
  assert.strictEqual(b.say('/nova x', { bot: true }), null);
  assert.strictEqual(b.say('', { noText: true }), null);
  assert.deepStrictEqual(b.run([{ update_id: 5 }]), []);
});
test('sufixo @bot nos comandos e aceito', () => {
  const b = makeBot();
  assert.ok(/Tarefa criada: \[ \] #1 a/.test(b.say('/nova@GestorBot a')));
});

console.log('Criar / listar / concluir');
test('criar e listar', () => {
  const b = makeBot();
  assert.strictEqual(b.say('/nova Comprar pao'), 'Tarefa criada: [ ] #1 Comprar pao');
  assert.strictEqual(b.say('/add Ligar'), 'Tarefa criada: [ ] #2 Ligar');
  assert.strictEqual(b.say('/listar'), 'Tarefas pendentes:\n[ ] #1 Comprar pao\n[ ] #2 Ligar');
});
test('concluir e listar pendentes/todas', () => {
  const b = makeBot();
  b.say('/nova a'); b.say('/nova b');
  assert.strictEqual(b.say('/concluir 1'), 'Concluida: [x] #1 a');
  assert.strictEqual(b.say('/listar'), 'Tarefas pendentes:\n[ ] #2 b');
  assert.strictEqual(b.say('/listar todas'), 'Todas as tarefas:\n[x] #1 a\n[ ] #2 b');
  assert.strictEqual(b.say('/concluir 1'), 'A tarefa #1 ja estava concluida.');
  assert.strictEqual(b.say('/concluir #2'), 'Concluida: [x] #2 b');
  assert.strictEqual(b.say('/listar'), 'Nenhuma tarefa pendente.');
});
test('listas vazias e ajuda', () => {
  const b = makeBot();
  assert.strictEqual(b.say('/listar todas'), 'Nenhuma tarefa cadastrada.');
  assert.ok(b.say('/ajuda').startsWith('Comandos:'));
  assert.ok(b.say('texto solto').startsWith('Comandos:'));
});
test('/nova sem texto, texto longo, espacos/quebras normalizados', () => {
  const b = makeBot();
  assert.strictEqual(b.say('/nova'), 'Use: /nova &lt;descricao da tarefa&gt;');
  assert.ok(/muito longa/.test(b.say('/nova ' + 'x'.repeat(501))));
  assert.strictEqual(b.say('/nova   a \n\n  b\t c  '), 'Tarefa criada: [ ] #1 a b c');
  assert.strictEqual(b.say('/nova ' + 'y'.repeat(500)).length > 500, true);
});
test('HTML/Markdown no texto e escapado (sem erro 400 no Telegram)', () => {
  const b = makeBot();
  assert.strictEqual(b.say('/nova <b>x</b> & _y_ *z*'), 'Tarefa criada: [ ] #1 &lt;b&gt;x&lt;/b&gt; &amp; _y_ *z*');
  assert.ok(b.say('/listar').includes('&lt;b&gt;x&lt;/b&gt;'));
});

console.log('Numeros invalidos em /concluir');
test('rejeita 3abc, 1.5, -1, 0, vazio, 1 2, 0x10, 1e3, ids enormes', () => {
  const b = makeBot();
  b.say('/nova a'); b.say('/nova b'); b.say('/nova c'); b.say('/nova d');
  for (const bad of ['3abc', '1.5', '-1', '0', '', '1 2', '0x10', '1e3', '#', '##1', '٣', '99999999999999999999', '3,']) {
    const r = b.say('/concluir ' + bad);
    assert.ok(r.startsWith('Use: /concluir'), JSON.stringify(bad) + ' -> ' + r);
  }
  assert.strictEqual(b.say('/listar').split('\n').length, 5, 'nenhuma tarefa foi concluida por engano');
  assert.strictEqual(b.say('/concluir 9'), 'Tarefa #9 nao encontrada.');
  assert.strictEqual(b.say('/concluir 007'), 'Tarefa #7 nao encontrada.');
  assert.strictEqual(b.say('/concluir 3'), 'Concluida: [x] #3 c');
  assert.strictEqual(b.say('/done 4'), 'Concluida: [x] #4 d');
});
test('/listar com argumento invalido nao lista', () => {
  const b = makeBot(); b.say('/nova a');
  assert.ok(b.say('/listar xyz').startsWith('Use: /listar'));
  assert.ok(b.say('/listar todos').startsWith('Todas'));
});

console.log('Duplicidade');
test('mesmo update_id reenviado nao cria tarefa de novo', () => {
  const b = makeBot();
  const u = b.upd('/nova unica', { update_id: 42 });
  assert.strictEqual(b.run([u]).length, 1);
  assert.strictEqual(b.run([u]).length, 0);
  assert.strictEqual(b.run([u]).length, 0);
  assert.strictEqual(b.store().tasks.length, 1);
});
test('lote com varios updates: todos processados, repetidos descartados', () => {
  const b = makeBot();
  const r = b.run([b.upd('/nova a', { update_id: 1 }), b.upd('/nova b', { update_id: 2 }), b.upd('/nova a', { update_id: 1 }), b.upd('/nova c', { update_id: 3 })]);
  assert.strictEqual(r.length, 3);
  assert.deepStrictEqual(b.store().tasks.map((t) => t.text), ['a', 'b', 'c']);
});
test('memoria de update_id e limitada (200) e mantem os mais recentes', () => {
  const b = makeBot();
  for (let i = 1; i <= 260; i++) b.run([b.upd('/listar', { update_id: i })]);
  assert.strictEqual(b.store().seen.length, 200);
  assert.strictEqual(b.run([b.upd('/listar', { update_id: 260 })]).length, 0);
});
test('ids novos nao colidem apos reinicio de contador (nextId > maior id)', () => {
  const b = makeBot();
  b.say('/nova a'); b.say('/nova b');
  const s = b.store(); // simula static data corrompido/zerado de nextId
  delete s.nextId;
  const b2 = makeBot();
  b2.run([]); // no-op
  // reaproveita o estado persistido manualmente
  const fn = new Function('$input', '$getWorkflowStaticData', code.replace("const ALLOWED_ID = 'COLE_SEU_ID_AQUI';", "const ALLOWED_ID = '" + OWNER + "';"));
  const live = JSON.parse(JSON.stringify(s));
  const res = fn({ all: () => [{ json: b.upd('/nova c') }] }, () => live);
  assert.strictEqual(res[0].json.reply, 'Tarefa criada: [ ] #3 c');
});

console.log('Limites');
test('limite de 200 PENDENTES; concluidas nao contam e liberam espaco', () => {
  const b = makeBot();
  for (let i = 1; i <= 200; i++) assert.ok(b.say('/nova t' + i).startsWith('Tarefa criada'));
  assert.ok(/Limite de 200 tarefas pendentes/.test(b.say('/nova extra')));
  assert.ok(b.say('/concluir 1').startsWith('Concluida'));
  assert.ok(b.say('/nova extra').startsWith('Tarefa criada: [ ] #201'));
});
test('concluidas antigas sao podadas (mantem as 100 mais recentes) e novas nao ficam bloqueadas', () => {
  const b = makeBot();
  for (let i = 1; i <= 150; i++) { b.say('/nova t' + i); b.say('/concluir ' + i); }
  const t = b.store().tasks;
  assert.strictEqual(t.length, 100);
  assert.strictEqual(t[0].id, 51);
  assert.ok(b.say('/nova depois').startsWith('Tarefa criada: [ ] #151'));
});
test('/listar muito grande e truncado abaixo de 4096 com rodape', () => {
  const b = makeBot();
  for (let i = 1; i <= 100; i++) b.say('/nova ' + 'palavra '.repeat(40).trim() + ' ' + i);
  const r = b.say('/listar');
  assert.ok(r.length < 4096, 'tamanho ' + r.length);
  assert.ok(/\n\(\+\d+ nao exibidas\)$/.test(r), r.slice(-60));
  const shown = (r.match(/\[ \] #/g) || []).length;
  assert.strictEqual(shown + Number(r.match(/\(\+(\d+) nao/)[1]), 100);
});
test('/listar pequeno nao tem rodape', () => {
  const b = makeBot(); b.say('/nova a');
  assert.ok(!/nao exibidas/.test(b.say('/listar')));
});
test('worst case: 200 pendentes de 500 caracteres de "<" ainda < 4096 apos escape', () => {
  const b = makeBot();
  for (let i = 1; i <= 200; i++) b.say('/nova ' + '<'.repeat(500));
  assert.ok(b.say('/listar').length < 4096);
});

console.log('\n' + passed + ' passaram, ' + failed + ' falharam');
process.exit(failed ? 1 : 0);
