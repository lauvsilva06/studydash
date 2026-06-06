// ============================================================
//  StudyDash — api.js
//  Camada de acesso ao Supabase (substitui o localStorage)
//  Importado pelo index.html via <script type="module">
// ============================================================

// ── Configuração ─────────────────────────────────────────
// Substitua pelos seus valores em: supabase.com → Project Settings → API
export const SUPABASE_URL = 'https://ujzoytjwpjnwawnlowwg.supabase.co';
export const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVqem95dGp3cGpud2F3bmxvd3dnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA3MzUxMDUsImV4cCI6MjA5NjMxMTEwNX0._-9XPGF3Z4xjc8XEGbdUpsmqwUJdwc5xWpaOotylDbY';

const HEADERS = {
  'Content-Type':  'application/json',
  'apikey':        SUPABASE_KEY,
  'Authorization': `Bearer ${SUPABASE_KEY}`,
  'Prefer':        'return=representation',
};

// ── Helper genérico de fetch ──────────────────────────────
async function req(method, path, body = null) {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/${path}`, {
    method,
    headers: HEADERS,
    body: body ? JSON.stringify(body) : null,
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.message || `HTTP ${res.status} — ${path}`);
  }
  // DELETE retorna 204 (sem body)
  if (res.status === 204) return null;
  return res.json();
}

// ── SUBJECTS ─────────────────────────────────────────────

/** Retorna todas as matérias com progresso calculado */
export async function fetchSubjects() {
  // Usa a view subject_progress criada no schema
  return req('GET', 'subject_progress?order=sort_order.asc');
}

/** Atualiza notas de uma matéria */
export async function updateSubjectNotes(id, notes) {
  return req('PATCH', `subjects?id=eq.${id}`, { notes });
}

// ── TASK GROUPS ──────────────────────────────────────────

/** Retorna grupos de uma matéria com suas tarefas */
export async function fetchGroupsWithTasks(subjectId) {
  // Busca grupos
  const groups = await req('GET',
    `task_groups?subject_id=eq.${subjectId}&order=sort_order.asc`
  );
  // Busca tarefas da matéria
  const tasks = await req('GET',
    `tasks?subject_id=eq.${subjectId}&order=sort_order.asc`
  );
  // Agrupa tarefas por group_id
  return groups.map(g => ({
    ...g,
    tasks: tasks.filter(t => t.group_id === g.id),
  }));
}

// ── TASKS ─────────────────────────────────────────────────

/** Marca/desmarca uma tarefa */
export async function toggleTask(id, done) {
  return req('PATCH', `tasks?id=eq.${id}`, {
    done,
    done_at: done ? new Date().toISOString() : null,
  });
}

/** Adiciona nova tarefa a um grupo */
export async function addTask(subjectId, groupId, text, sortOrder = 999) {
  const newId = `${subjectId}_${Date.now()}`;
  return req('POST', 'tasks', {
    id: newId,
    subject_id: subjectId,
    group_id:   groupId,
    text,
    sort_order: sortOrder,
  });
}

/** Remove uma tarefa */
export async function deleteTask(id) {
  return req('DELETE', `tasks?id=eq.${id}`);
}

// ── SCHEDULE FOCUS ────────────────────────────────────────

/** Retorna todos os focos do cronograma */
export async function fetchScheduleFocus() {
  const rows = await req('GET', 'schedule_focus?order=day.asc');
  // Converte para objeto { Segunda: '...', Terça: '...', ... }
  return Object.fromEntries(rows.map(r => [r.day, r.focus_text]));
}

/** Salva o foco editado de um dia */
export async function updateScheduleFocus(day, focusText) {
  return req('PATCH', `schedule_focus?day=eq.${encodeURIComponent(day)}`, {
    focus_text: focusText,
    updated_at: new Date().toISOString(),
  });
}

// ── POMODORO SESSIONS ─────────────────────────────────────

/** Registra uma sessão Pomodoro concluída */
export async function saveSession(subjectId, durationMin = 30) {
  return req('POST', 'pomodoro_sessions', {
    subject_id:   subjectId,
    duration_min: durationMin,
    session_date: new Date().toISOString().slice(0, 10),
  });
}

/** Retorna totais do dia (usa a view today_pomodoro) */
export async function fetchTodayStats() {
  const rows = await req('GET', 'today_pomodoro');
  return rows[0] ?? { session_count: 0, total_minutes: 0 };
}
