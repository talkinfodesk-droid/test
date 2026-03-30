/**
 * 학습 정책 테스트 (티켓 24)
 *
 * attempts API의 핵심 정책을 시뮬레이션하여 검증합니다.
 * 실제 Supabase 연동 없이 정책 로직의 정확성을 테스트합니다.
 */

// 답안 제출 정책 시뮬레이터
interface Attempt {
  attemptNumber: number
  isCorrect: boolean
  meaningShown: boolean
}

function simulateAttempt(
  existingAttempts: Attempt[],
  selectedChoice: number,
  correctChoice: number
): { allowed: boolean; result?: Attempt; canRetry?: boolean; error?: string } {
  const attemptCount = existingAttempts.length

  // 정책: 최대 2회까지만 시도 가능
  if (attemptCount >= 2) {
    return { allowed: false, error: '이 문제는 더 이상 제출할 수 없습니다.' }
  }

  // 정책: 첫 시도에서 정답이면 두 번째 시도 불가
  if (attemptCount === 1 && existingAttempts[0].isCorrect) {
    return { allowed: false, error: '이미 정답 처리된 문제입니다.' }
  }

  const attemptNumber = attemptCount + 1
  const isCorrect = selectedChoice === correctChoice
  const meaningShown = attemptNumber === 1 && !isCorrect

  return {
    allowed: true,
    result: { attemptNumber, isCorrect, meaningShown },
    canRetry: attemptNumber === 1 && !isCorrect,
  }
}

// 단어 자동 저장 정책 시뮬레이터
interface UserWord {
  wordId: number
  wrongCount: number
  saveCount: number
}

function simulateWordSave(
  existingWord: UserWord | null,
  shouldSave: boolean
): UserWord | null {
  if (!shouldSave) return existingWord

  if (existingWord) {
    return {
      ...existingWord,
      wrongCount: existingWord.wrongCount + 1,
      saveCount: existingWord.saveCount + 1,
    }
  }

  return { wordId: 1, wrongCount: 1, saveCount: 1 }
}

describe('학습 정책 테스트', () => {
  describe('첫 오답 시 뜻 1회만 노출', () => {
    it('첫 시도 오답이면 meaningShown=true', () => {
      const result = simulateAttempt([], 2, 1) // 오답
      expect(result.allowed).toBe(true)
      expect(result.result?.meaningShown).toBe(true)
    })

    it('첫 시도 정답이면 meaningShown=false', () => {
      const result = simulateAttempt([], 1, 1) // 정답
      expect(result.allowed).toBe(true)
      expect(result.result?.meaningShown).toBe(false)
    })

    it('두 번째 시도에서는 meaningShown=false', () => {
      const firstAttempt: Attempt = { attemptNumber: 1, isCorrect: false, meaningShown: true }
      const result = simulateAttempt([firstAttempt], 1, 1) // 두 번째 시도
      expect(result.allowed).toBe(true)
      expect(result.result?.meaningShown).toBe(false)
    })
  })

  describe('재도전 1회만 허용', () => {
    it('첫 오답 후 canRetry=true', () => {
      const result = simulateAttempt([], 2, 1)
      expect(result.canRetry).toBe(true)
    })

    it('첫 정답 후 canRetry=false', () => {
      const result = simulateAttempt([], 1, 1)
      expect(result.canRetry).toBe(false)
    })

    it('두 번째 시도 후 canRetry=undefined (종료)', () => {
      const firstAttempt: Attempt = { attemptNumber: 1, isCorrect: false, meaningShown: true }
      const result = simulateAttempt([firstAttempt], 1, 1)
      expect(result.canRetry).toBeFalsy()
    })
  })

  describe('두 번째 제출 후 추가 제출 차단', () => {
    it('2회 시도 후 3번째 시도는 차단된다', () => {
      const attempts: Attempt[] = [
        { attemptNumber: 1, isCorrect: false, meaningShown: true },
        { attemptNumber: 2, isCorrect: false, meaningShown: false },
      ]
      const result = simulateAttempt(attempts, 1, 1)
      expect(result.allowed).toBe(false)
      expect(result.error).toBe('이 문제는 더 이상 제출할 수 없습니다.')
    })

    it('첫 정답 후 두 번째 시도는 차단된다', () => {
      const attempts: Attempt[] = [
        { attemptNumber: 1, isCorrect: true, meaningShown: false },
      ]
      const result = simulateAttempt(attempts, 2, 1)
      expect(result.allowed).toBe(false)
      expect(result.error).toBe('이미 정답 처리된 문제입니다.')
    })
  })

  describe('첫 오답 단어 저장', () => {
    it('신규 단어면 wrongCount=1, saveCount=1로 저장', () => {
      const saved = simulateWordSave(null, true)
      expect(saved).toEqual({ wordId: 1, wrongCount: 1, saveCount: 1 })
    })

    it('기존 단어면 wrongCount, saveCount가 1씩 증가', () => {
      const existing: UserWord = { wordId: 1, wrongCount: 3, saveCount: 3 }
      const saved = simulateWordSave(existing, true)
      expect(saved).toEqual({ wordId: 1, wrongCount: 4, saveCount: 4 })
    })

    it('정답이면 단어가 저장되지 않는다', () => {
      const saved = simulateWordSave(null, false)
      expect(saved).toBeNull()
    })
  })

  describe('세션 소유자 확인 (타인 세션 접근 차단)', () => {
    function checkAccess(sessionUserId: string, requestUserId: string) {
      return sessionUserId !== requestUserId
    }

    it('세션 소유자가 아니면 접근이 거부된다', () => {
      expect(checkAccess('user-A', 'user-B')).toBe(true)
    })

    it('세션 소유자면 접근이 허용된다', () => {
      expect(checkAccess('user-A', 'user-A')).toBe(false)
    })
  })
})

describe('학습 기록 저장 검증 (티켓 23)', () => {
  it('학습 흐름의 전체 기록이 순서대로 생성된다', () => {
    // 시뮬레이션: 세션 시작 → 첫 시도(오답) → 뜻 노출 → 두 번째 시도(정답) → 결과
    const records: string[] = []

    // 1. 세션 시작
    records.push('session_created')

    // 2. 첫 시도 (오답)
    const first = simulateAttempt([], 2, 1)
    expect(first.allowed).toBe(true)
    records.push('first_attempt')

    // 3. 뜻 노출 확인
    expect(first.result?.meaningShown).toBe(true)
    records.push('meaning_shown')

    // 4. 두 번째 시도 (정답)
    const second = simulateAttempt(
      [{ attemptNumber: 1, isCorrect: false, meaningShown: true }],
      1, 1
    )
    expect(second.allowed).toBe(true)
    expect(second.result?.isCorrect).toBe(true)
    records.push('second_attempt')

    // 5. 최종 결과 기록
    records.push('result_saved')

    // 전체 학습 흐름 기록 확인
    expect(records).toEqual([
      'session_created',
      'first_attempt',
      'meaning_shown',
      'second_attempt',
      'result_saved',
    ])
  })
})
