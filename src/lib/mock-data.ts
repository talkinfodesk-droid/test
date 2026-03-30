// Supabase 미연결 시 사용하는 목업 데이터

export const MOCK_HOME = {
  nickname: '학습자',
  monthNumber: 3,
  difficulty: 2,
  todayCompleted: false,
  todaySessionId: null,
  lastSessionSummary: {
    date: new Date().toISOString(),
    totalProblems: 10,
    correctCount: 7,
    wrongCount: 3,
  },
  savedWordCount: 15,
}

export const MOCK_PROBLEMS = [
  {
    sessionProblemId: 1,
    orderIndex: 0,
    problemId: 1,
    sentence: 'She decided to ____ the old furniture.',
    choices: ['폐기하다', '수리하다', '장식하다', '구매하다'],
    difficulty: 2,
    topic: '일상생활',
    word: 'discard',
  },
  {
    sessionProblemId: 2,
    orderIndex: 1,
    problemId: 2,
    sentence: 'The project requires a ____ approach.',
    choices: ['체계적인', '무작위의', '느린', '단순한'],
    difficulty: 2,
    topic: '비즈니스',
    word: 'systematic',
  },
  {
    sessionProblemId: 3,
    orderIndex: 2,
    problemId: 3,
    sentence: 'We need to ____ the results carefully.',
    choices: ['분석하다', '무시하다', '복사하다', '삭제하다'],
    difficulty: 2,
    topic: '학습',
    word: 'analyze',
  },
  {
    sessionProblemId: 4,
    orderIndex: 3,
    problemId: 4,
    sentence: 'The weather was ____ for outdoor activities.',
    choices: ['적합한', '위험한', '추운', '습한'],
    difficulty: 2,
    topic: '자연',
    word: 'favorable',
  },
  {
    sessionProblemId: 5,
    orderIndex: 4,
    problemId: 5,
    sentence: 'Please ____ your opinion on this matter.',
    choices: ['표현하다', '숨기다', '바꾸다', '잊다'],
    difficulty: 2,
    topic: '소통',
    word: 'express',
  },
]

// 정답 매핑 (선택지 인덱스)
export const MOCK_ANSWERS: Record<number, { correctChoice: number; meaningKo: string }> = {
  1: { correctChoice: 0, meaningKo: '폐기하다, 버리다' },
  2: { correctChoice: 0, meaningKo: '체계적인, 조직적인' },
  3: { correctChoice: 0, meaningKo: '분석하다, 검토하다' },
  4: { correctChoice: 0, meaningKo: '적합한, 유리한' },
  5: { correctChoice: 0, meaningKo: '표현하다, 나타내다' },
}

export const MOCK_RESULT = {
  totalProblems: 5,
  correctCount: 3,
  wrongCount: 2,
  savedWordCount: 2,
}

export const MOCK_VOCABULARY = [
  { userWordId: 1, wordId: 1, wrongCount: 3, saveCount: 3, lastSavedAt: '2026-03-28T00:00:00Z', word: 'discard', meaningKo: '폐기하다', exampleEn: 'She decided to discard the old furniture.', exampleKo: '그녀는 오래된 가구를 버리기로 했다.', difficulty: 2, topic: '일상생활' },
  { userWordId: 2, wordId: 2, wrongCount: 2, saveCount: 2, lastSavedAt: '2026-03-29T00:00:00Z', word: 'systematic', meaningKo: '체계적인', exampleEn: 'The project requires a systematic approach.', exampleKo: '그 프로젝트는 체계적인 접근이 필요하다.', difficulty: 2, topic: '비즈니스' },
  { userWordId: 3, wordId: 4, wrongCount: 1, saveCount: 1, lastSavedAt: '2026-03-30T00:00:00Z', word: 'favorable', meaningKo: '적합한, 유리한', exampleEn: 'The weather was favorable for outdoor activities.', exampleKo: '날씨가 야외 활동에 적합했다.', difficulty: 2, topic: '자연' },
]

export const MOCK_MYPAGE = {
  nickname: '학습자',
  email: 'user@example.com',
  createdAt: '2026-01-15T00:00:00Z',
  learningStartedAt: '2026-01-20T00:00:00Z',
  monthNumber: 3,
  difficulty: 2,
  totalSessions: 45,
  savedWordCount: 15,
}

export const MOCK_ADMIN_DASHBOARD = {
  totalUsers: 128,
  todayLearners: 34,
  totalProblems: 500,
  totalWords: 320,
  avgAccuracy: 72,
}

export const MOCK_ADMIN_STATS = {
  avgAccuracy: 72,
  frequentlyWrongProblems: [
    { problemId: 12, sentence: 'The company will ____ new policies.', word: 'implement', wrongCount: 45 },
    { problemId: 8, sentence: 'She tried to ____ the situation.', word: 'mitigate', wrongCount: 38 },
    { problemId: 23, sentence: 'They need to ____ the contract.', word: 'negotiate', wrongCount: 31 },
  ],
  frequentlyWrongWords: [
    { wordId: 12, word: 'implement', meaningKo: '시행하다', wrongCount: 45 },
    { wordId: 8, word: 'mitigate', meaningKo: '완화하다', wrongCount: 38 },
    { wordId: 23, word: 'negotiate', meaningKo: '협상하다', wrongCount: 31 },
  ],
  recentLearningTrend: Array.from({ length: 7 }, (_, i) => {
    const d = new Date()
    d.setDate(d.getDate() - (6 - i))
    return { date: d.toISOString().split('T')[0], count: Math.floor(Math.random() * 40) + 10 }
  }),
}
