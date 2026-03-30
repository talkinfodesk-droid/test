import { getMonthNumber, getDifficultyByMonth, PROBLEMS_PER_SESSION } from '@/lib/learning/difficulty'

describe('월차 계산 (getMonthNumber)', () => {
  it('learning_started_at이 null이면 1개월차를 반환한다', () => {
    expect(getMonthNumber(null)).toBe(1)
  })

  it('오늘 시작했으면 1개월차를 반환한다', () => {
    const today = new Date().toISOString()
    expect(getMonthNumber(today)).toBe(1)
  })

  it('2개월 전에 시작했으면 3개월차를 반환한다', () => {
    const twoMonthsAgo = new Date()
    twoMonthsAgo.setMonth(twoMonthsAgo.getMonth() - 2)
    expect(getMonthNumber(twoMonthsAgo.toISOString())).toBe(3)
  })

  it('12개월 전에 시작했으면 13개월차를 반환한다', () => {
    const yearAgo = new Date()
    yearAgo.setFullYear(yearAgo.getFullYear() - 1)
    expect(getMonthNumber(yearAgo.toISOString())).toBe(13)
  })
})

describe('난이도 매핑 (getDifficultyByMonth)', () => {
  it('1~2월차는 난이도 1 (초급)', () => {
    expect(getDifficultyByMonth(1)).toBe(1)
    expect(getDifficultyByMonth(2)).toBe(1)
  })

  it('3~4월차는 난이도 2 (중급)', () => {
    expect(getDifficultyByMonth(3)).toBe(2)
    expect(getDifficultyByMonth(4)).toBe(2)
  })

  it('5~6월차는 난이도 3 (중상급)', () => {
    expect(getDifficultyByMonth(5)).toBe(3)
    expect(getDifficultyByMonth(6)).toBe(3)
  })

  it('7월차 이상은 난이도 4 (상급)', () => {
    expect(getDifficultyByMonth(7)).toBe(4)
    expect(getDifficultyByMonth(12)).toBe(4)
    expect(getDifficultyByMonth(100)).toBe(4)
  })
})

describe('학습 설정값', () => {
  it('세션당 문제 수는 10개이다', () => {
    expect(PROBLEMS_PER_SESSION).toBe(10)
  })
})
