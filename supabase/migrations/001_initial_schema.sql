-- 사용자 프로필 테이블
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nickname TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  learning_started_at TIMESTAMPTZ
);

-- 단어 테이블
CREATE TABLE words (
  id SERIAL PRIMARY KEY,
  word TEXT NOT NULL,
  meaning_ko TEXT NOT NULL,
  example_en TEXT NOT NULL,
  example_ko TEXT NOT NULL,
  difficulty INTEGER NOT NULL CHECK (difficulty BETWEEN 1 AND 4),
  topic TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 문제 테이블
CREATE TABLE problems (
  id SERIAL PRIMARY KEY,
  word_id INTEGER NOT NULL REFERENCES words(id) ON DELETE CASCADE,
  sentence TEXT NOT NULL,
  choices JSONB NOT NULL,
  correct_choice INTEGER NOT NULL,
  difficulty INTEGER NOT NULL CHECK (difficulty BETWEEN 1 AND 4),
  topic TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 학습 세션 테이블
CREATE TABLE learning_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  month_number INTEGER NOT NULL,
  difficulty INTEGER NOT NULL,
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  status TEXT NOT NULL DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'completed'))
);

-- 세션별 문제 테이블
CREATE TABLE session_problems (
  id SERIAL PRIMARY KEY,
  session_id UUID NOT NULL REFERENCES learning_sessions(id) ON DELETE CASCADE,
  problem_id INTEGER NOT NULL REFERENCES problems(id) ON DELETE CASCADE,
  order_index INTEGER NOT NULL
);

-- 답안 제출 테이블
CREATE TABLE attempts (
  id SERIAL PRIMARY KEY,
  session_problem_id INTEGER NOT NULL REFERENCES session_problems(id) ON DELETE CASCADE,
  attempt_number INTEGER NOT NULL CHECK (attempt_number IN (1, 2)),
  selected_choice INTEGER NOT NULL,
  is_correct BOOLEAN NOT NULL,
  meaning_shown BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (session_problem_id, attempt_number)
);

-- 사용자 단어장 테이블
CREATE TABLE user_words (
  id SERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  word_id INTEGER NOT NULL REFERENCES words(id) ON DELETE CASCADE,
  wrong_count INTEGER NOT NULL DEFAULT 1,
  save_count INTEGER NOT NULL DEFAULT 1,
  last_wrong_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_saved_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, word_id)
);

-- 인덱스
CREATE INDEX idx_problems_difficulty ON problems(difficulty) WHERE is_active = TRUE;
CREATE INDEX idx_learning_sessions_user ON learning_sessions(user_id);
CREATE INDEX idx_learning_sessions_user_date ON learning_sessions(user_id, started_at);
CREATE INDEX idx_session_problems_session ON session_problems(session_id);
CREATE INDEX idx_attempts_session_problem ON attempts(session_problem_id);
CREATE INDEX idx_user_words_user ON user_words(user_id);

-- RLS 정책
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE learning_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE session_problems ENABLE ROW LEVEL SECURITY;
ALTER TABLE attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_words ENABLE ROW LEVEL SECURITY;

-- users: 본인 조회/수정
CREATE POLICY "Users can view own profile" ON users
  FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON users
  FOR INSERT WITH CHECK (auth.uid() = id);

-- learning_sessions: 본인만
CREATE POLICY "Users can view own sessions" ON learning_sessions
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own sessions" ON learning_sessions
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own sessions" ON learning_sessions
  FOR UPDATE USING (auth.uid() = user_id);

-- session_problems: 본인 세션만
CREATE POLICY "Users can view own session problems" ON session_problems
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM learning_sessions
      WHERE learning_sessions.id = session_problems.session_id
      AND learning_sessions.user_id = auth.uid()
    )
  );
CREATE POLICY "Users can create own session problems" ON session_problems
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM learning_sessions
      WHERE learning_sessions.id = session_problems.session_id
      AND learning_sessions.user_id = auth.uid()
    )
  );

-- attempts: 본인 세션 문제만
CREATE POLICY "Users can view own attempts" ON attempts
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM session_problems
      JOIN learning_sessions ON learning_sessions.id = session_problems.session_id
      WHERE session_problems.id = attempts.session_problem_id
      AND learning_sessions.user_id = auth.uid()
    )
  );
CREATE POLICY "Users can create own attempts" ON attempts
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM session_problems
      JOIN learning_sessions ON learning_sessions.id = session_problems.session_id
      WHERE session_problems.id = attempts.session_problem_id
      AND learning_sessions.user_id = auth.uid()
    )
  );

-- user_words: 본인만
CREATE POLICY "Users can view own words" ON user_words
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own words" ON user_words
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own words" ON user_words
  FOR UPDATE USING (auth.uid() = user_id);

-- words, problems: 모든 인증 사용자 읽기 가능
ALTER TABLE words ENABLE ROW LEVEL SECURITY;
ALTER TABLE problems ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view active words" ON words
  FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can view active problems" ON problems
  FOR SELECT USING (auth.role() = 'authenticated');
