-- ============================================================
--  StudyDash — Schema SQL para Supabase (PostgreSQL)
--  Execute este arquivo no SQL Editor do Supabase
-- ============================================================

-- ── Extensão para UUIDs ──────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ── Tabela: subjects (matérias) ──────────────────────────
CREATE TABLE IF NOT EXISTS subjects (
  id          TEXT PRIMARY KEY,          -- ex: 'faculdade', 'hcia'
  title       TEXT NOT NULL,
  deadline    TEXT NOT NULL,             -- formato DD/MM/YYYY
  notes       TEXT DEFAULT '',
  color       TEXT NOT NULL DEFAULT '#2dd4a0',
  icon        TEXT NOT NULL DEFAULT '📚',
  short_name  TEXT NOT NULL,
  sort_order  INT  DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── Tabela: task_groups (grupos dentro de cada matéria) ──
CREATE TABLE IF NOT EXISTS task_groups (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  subject_id  TEXT NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
  label       TEXT NOT NULL,
  sort_order  INT  DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── Tabela: tasks (tarefas) ──────────────────────────────
CREATE TABLE IF NOT EXISTS tasks (
  id          TEXT PRIMARY KEY,
  subject_id  TEXT NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
  group_id    UUID REFERENCES task_groups(id) ON DELETE SET NULL,
  text        TEXT NOT NULL,
  done        BOOLEAN DEFAULT FALSE,
  done_at     TIMESTAMPTZ,
  sort_order  INT  DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── Tabela: schedule_focus (foco editável por dia) ───────
CREATE TABLE IF NOT EXISTS schedule_focus (
  day         TEXT PRIMARY KEY,          -- 'Segunda', 'Terça', etc.
  focus_text  TEXT DEFAULT '',
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── Tabela: pomodoro_sessions (histórico de sessões) ─────
CREATE TABLE IF NOT EXISTS pomodoro_sessions (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  subject_id   TEXT REFERENCES subjects(id) ON DELETE SET NULL,
  duration_min INT  NOT NULL DEFAULT 30,
  session_date DATE DEFAULT CURRENT_DATE,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ── View: progresso por matéria ──────────────────────────
CREATE OR REPLACE VIEW subject_progress AS
SELECT
  s.id,
  s.title,
  s.short_name,
  s.deadline,
  s.color,
  s.icon,
  COUNT(t.id)                                             AS total_tasks,
  COUNT(t.id) FILTER (WHERE t.done = TRUE)               AS done_tasks,
  ROUND(
    COUNT(t.id) FILTER (WHERE t.done = TRUE)::NUMERIC /
    NULLIF(COUNT(t.id), 0) * 100
  )                                                       AS progress_pct
FROM subjects s
LEFT JOIN tasks t ON t.subject_id = s.id
GROUP BY s.id, s.title, s.short_name, s.deadline, s.color, s.icon;

-- ── View: sessões Pomodoro de hoje ───────────────────────
CREATE OR REPLACE VIEW today_pomodoro AS
SELECT
  COUNT(*)                        AS session_count,
  COALESCE(SUM(duration_min), 0)  AS total_minutes
FROM pomodoro_sessions
WHERE session_date = CURRENT_DATE;

-- ── Row Level Security ───────────────────────────────────
-- Fase inicial: acesso total (sem autenticação ainda)
-- Quando adicionar login, substituir por políticas com auth.uid()
ALTER TABLE subjects          ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_groups       ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks             ENABLE ROW LEVEL SECURITY;
ALTER TABLE schedule_focus    ENABLE ROW LEVEL SECURITY;
ALTER TABLE pomodoro_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "allow_all_subjects"       ON subjects          FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_task_groups"    ON task_groups       FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_tasks"          ON tasks             FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_schedule_focus" ON schedule_focus    FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_pomodoro"       ON pomodoro_sessions FOR ALL USING (true) WITH CHECK (true);

-- ── Índices ──────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_tasks_subject    ON tasks(subject_id);
CREATE INDEX IF NOT EXISTS idx_tasks_group      ON tasks(group_id);
CREATE INDEX IF NOT EXISTS idx_tasks_done       ON tasks(done);
CREATE INDEX IF NOT EXISTS idx_task_groups_subj ON task_groups(subject_id);
CREATE INDEX IF NOT EXISTS idx_pomo_date        ON pomodoro_sessions(session_date);
