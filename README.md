# StudyDash

Dashboard pessoal de estudos com back-end no Supabase e front-end no GitHub Pages.

---

## Estrutura do repositório

```
studydash/
├── frontend/
│   ├── index.html      ← Dashboard (front-end completo)
│   └── api.js          ← Camada de comunicação com Supabase
├── backend/
│   ├── schema.sql      ← Estrutura do banco (execute 1× no Supabase)
│   └── seed.sql        ← Dados iniciais (execute 1× depois do schema)
└── README.md
```

---

## Passo a passo de configuração

### 1. Criar conta e projeto no Supabase

1. Acesse [supabase.com](https://supabase.com) e crie uma conta gratuita
2. Clique em **New Project**
3. Escolha um nome (ex: `studydash`) e uma senha forte para o banco
4. Aguarde o projeto inicializar (~2 minutos)

### 2. Criar as tabelas

1. No painel do Supabase, vá em **SQL Editor → New query**
2. Cole o conteúdo de `backend/schema.sql` e clique em **Run**
3. Deve aparecer "Success. No rows returned"
4. Repita com o conteúdo de `backend/seed.sql` para inserir os dados iniciais

### 3. Pegar as credenciais

1. Vá em **Project Settings → API**
2. Copie:
   - **Project URL** → ex: `https://abcdefgh.supabase.co`
   - **anon public key** → chave longa começando com `eyJ...`

### 4. Configurar o front-end

Abra `frontend/api.js` e substitua as duas linhas no topo:

```javascript
export const SUPABASE_URL = 'https://SEU_PROJECT_ID.supabase.co';
export const SUPABASE_KEY = 'SUA_ANON_PUBLIC_KEY';
```

Pelos valores copiados no passo anterior.

### 5. Publicar no GitHub Pages

1. Crie um repositório no GitHub (pode ser privado ou público)
2. Faça upload de todos os arquivos, mantendo a estrutura de pastas
3. Vá em **Settings → Pages**
4. Em **Source**, selecione `Deploy from a branch`
5. Branch: `main` | Folder: `/frontend`
6. Clique em **Save**
7. Aguarde ~1 minuto e acesse a URL gerada: `https://seu-usuario.github.io/studydash`

---

## Integrando o api.js no index.html

O `index.html` atual usa `localStorage`. Para migrar para o Supabase,
adicione no início da tag `<script>` do `index.html`:

```html
<script type="module">
  import {
    fetchSubjects, fetchGroupsWithTasks,
    toggleTask, addTask, deleteTask,
    updateSubjectNotes, fetchScheduleFocus,
    updateScheduleFocus, saveSession, fetchTodayStats
  } from './api.js';

  // Substitua as funções que usam localStorage pelas do api.js
  // Exemplo — ao invés de:
  //   localStorage.setItem('sd_data_v5', JSON.stringify(subjects));
  // Use:
  //   await toggleTask(taskId, true);
</script>
```

> **Dica:** faça a migração função por função. Comece pelo `toggleTask`,
> teste, depois avance para `addTask`, `deleteTask`, e assim por diante.

---

## Como funciona o back-end (sem servidor)

```
Navegador (GitHub Pages)
       │
       │  fetch() com apikey no header
       ▼
Supabase REST API (PostgREST)
       │
       │  SQL automático
       ▼
PostgreSQL (gerenciado pelo Supabase)
```

O Supabase expõe o banco como uma API REST automaticamente —
não é necessário escrever nenhum código de servidor.
Cada tabela vira um endpoint: `GET /rest/v1/tasks`, `PATCH /rest/v1/tasks?id=eq.h1`, etc.

---

## Próximos passos (opcional)

| Feature | O que adicionar |
|---|---|
| Login com Google | Supabase Auth → `supabase.auth.signInWithOAuth({ provider: 'google' })` |
| Dados por usuário | Trocar as policies de `allow_all` por `auth.uid() = user_id` |
| Gráfico de progresso | Recharts ou Chart.js com dados da tabela `pomodoro_sessions` |
| Notificações de prazo | GitHub Actions agendado (cron) + Resend/Nodemailer |

---

## Tecnologias usadas

- **Front-end:** HTML, CSS, JavaScript puro — sem frameworks
- **Back-end:** [Supabase](https://supabase.com) (PostgreSQL + PostgREST)
- **Hospedagem:** [GitHub Pages](https://pages.github.com) (gratuito)
