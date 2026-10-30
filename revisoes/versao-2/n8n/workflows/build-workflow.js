#!/usr/bin/env node
// Gera gestor-tarefas-telegram.json a partir de src/processar-comando.js.
// Uso: node n8n/workflows/build-workflow.js
'use strict';
const fs = require('fs');
const path = require('path');

const dir = __dirname;
const jsCode = fs.readFileSync(path.join(dir, 'src', 'processar-comando.js'), 'utf8').replace(/\n+$/, '');

const workflow = {
  name: 'Gestor - Tarefas via Telegram',
  nodes: [
    {
      parameters: { updates: ['message'], additionalFields: {} },
      id: '6f1d2c1e-0a11-4c6b-9a10-000000000001',
      name: 'Telegram Trigger',
      type: 'n8n-nodes-base.telegramTrigger',
      typeVersion: 1.2,
      position: [0, 0],
      webhookId: '9b3f6a52-7a64-4c0e-8d2a-000000000001',
      credentials: { telegramApi: { id: '', name: 'Telegram Gestor' } },
    },
    {
      parameters: { mode: 'runOnceForAllItems', language: 'javaScript', jsCode },
      id: '6f1d2c1e-0a11-4c6b-9a10-000000000002',
      name: 'Processar comando',
      type: 'n8n-nodes-base.code',
      typeVersion: 2,
      position: [260, 0],
    },
    {
      parameters: {
        chatId: '={{ $json.chatId }}',
        text: '={{ $json.reply }}',
        // O texto ja sai escapado em HTML pelo no de codigo; parse_mode fixo evita erro 400
        // quando a tarefa contem _ * [ ] ou < >.
        additionalFields: { appendAttribution: false, parse_mode: 'HTML' },
      },
      id: '6f1d2c1e-0a11-4c6b-9a10-000000000003',
      name: 'Responder no Telegram',
      type: 'n8n-nodes-base.telegram',
      typeVersion: 1.2,
      position: [520, 0],
      webhookId: '9b3f6a52-7a64-4c0e-8d2a-000000000003',
      credentials: { telegramApi: { id: '', name: 'Telegram Gestor' } },
    },
  ],
  connections: {
    'Telegram Trigger': { main: [[{ node: 'Processar comando', type: 'main', index: 0 }]] },
    'Processar comando': { main: [[{ node: 'Responder no Telegram', type: 'main', index: 0 }]] },
  },
  settings: { executionOrder: 'v1' },
  pinData: {},
};

fs.writeFileSync(path.join(dir, 'gestor-tarefas-telegram.json'), JSON.stringify(workflow, null, 2) + '\n');
console.log('gestor-tarefas-telegram.json gerado.');
