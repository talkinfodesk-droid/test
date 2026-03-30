/**
 * 월차 기반 난이도 매핑
 * 1~2월차: 난이도 1 (초급)
 * 3~4월차: 난이도 2 (중급)
 * 5~6월차: 난이도 3 (중상급)
 * 7월차~: 난이도 4 (상급)
 */
export function getDifficultyByMonth(monthNumber: number): number {
  if (monthNumber <= 2) return 1
  if (monthNumber <= 4) return 2
  if (monthNumber <= 6) return 3
  return 4
}

/**
 * 학습 시작일 기준 현재 월차 계산
 */
export function getMonthNumber(learningStartedAt: string | null): number {
  if (!learningStartedAt) return 1

  const start = new Date(learningStartedAt)
  const now = new Date()
  const diffMonths =
    (now.getFullYear() - start.getFullYear()) * 12 +
    (now.getMonth() - start.getMonth())

  return Math.max(1, diffMonths + 1)
}

export const DIFFICULTY_LABELS: Record<number, string> = {
  1: '초급',
  2: '중급',
  3: '중상급',
  4: '상급',
}

export const PROBLEMS_PER_SESSION = 10
