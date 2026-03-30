import { requireAdmin } from '@/lib/supabase/admin'
import { NextResponse } from 'next/server'
import { MOCK_ADMIN_STATS } from '@/lib/mock-data'

export async function GET() {
  try {
    const { supabase, isAdmin } = await requireAdmin()
    if (!isAdmin) return NextResponse.json(MOCK_ADMIN_STATS)

    // 전체 평균 정답률
    const { data: allFirstAttempts } = await supabase
      .from('attempts')
      .select('is_correct')
      .eq('attempt_number', 1)

    let avgAccuracy = 0
    if (allFirstAttempts && allFirstAttempts.length > 0) {
      const correct = allFirstAttempts.filter((a) => a.is_correct).length
      avgAccuracy = Math.round((correct / allFirstAttempts.length) * 100)
    }

    // 자주 틀린 문제 (첫 시도 오답 기준, 상위 10개)
    const { data: wrongAttempts } = await supabase
      .from('attempts')
      .select('session_problem_id')
      .eq('attempt_number', 1)
      .eq('is_correct', false)

    // session_problem_id → problem_id 매핑을 위해 집계
    const spIdCounts: Record<number, number> = {}
    wrongAttempts?.forEach((a) => {
      spIdCounts[a.session_problem_id] = (spIdCounts[a.session_problem_id] || 0) + 1
    })

    // 상위 session_problem_id들의 problem_id 조회
    const topSpIds = Object.entries(spIdCounts)
      .sort(([, a], [, b]) => b - a)
      .slice(0, 20)
      .map(([id]) => Number(id))

    let frequentlyWrongProblems: { problemId: number; sentence: string; word: string; wrongCount: number }[] = []
    if (topSpIds.length > 0) {
      const { data: sps } = await supabase
        .from('session_problems')
        .select('id, problem_id, problems(sentence, words(word))')
        .in('id', topSpIds)

      // problem_id 기준으로 오답 수 집계
      const problemWrongCounts: Record<number, { sentence: string; word: string; count: number }> = {}
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      sps?.forEach((sp: any) => {
        const pid = sp.problem_id
        const wrongCount = spIdCounts[sp.id] || 0
        if (!problemWrongCounts[pid]) {
          problemWrongCounts[pid] = {
            sentence: sp.problems?.sentence ?? '',
            word: sp.problems?.words?.word ?? '',
            count: 0,
          }
        }
        problemWrongCounts[pid].count += wrongCount
      })

      frequentlyWrongProblems = Object.entries(problemWrongCounts)
        .map(([id, v]) => ({ problemId: Number(id), sentence: v.sentence, word: v.word, wrongCount: v.count }))
        .sort((a, b) => b.wrongCount - a.wrongCount)
        .slice(0, 10)
    }

    // 자주 틀린 단어 (user_words 기준 상위 10개)
    const { data: topWrongWords } = await supabase
      .from('user_words')
      .select('word_id, wrong_count, words(word, meaning_ko)')
      .order('wrong_count', { ascending: false })
      .limit(10)

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const frequentlyWrongWords = (topWrongWords ?? []).map((uw: any) => ({
      wordId: uw.word_id,
      word: uw.words?.word,
      meaningKo: uw.words?.meaning_ko,
      wrongCount: uw.wrong_count,
    }))

    // 최근 7일 학습 추이
    const recentDays: { date: string; count: number }[] = []
    for (let i = 6; i >= 0; i--) {
      const d = new Date()
      d.setDate(d.getDate() - i)
      d.setHours(0, 0, 0, 0)
      const nextD = new Date(d)
      nextD.setDate(nextD.getDate() + 1)

      const { count } = await supabase
        .from('learning_sessions')
        .select('*', { count: 'exact', head: true })
        .gte('started_at', d.toISOString())
        .lt('started_at', nextD.toISOString())

      recentDays.push({
        date: d.toISOString().split('T')[0],
        count: count ?? 0,
      })
    }

    return NextResponse.json({
      avgAccuracy,
      frequentlyWrongProblems,
      frequentlyWrongWords,
      recentLearningTrend: recentDays,
    })
  } catch {
    return NextResponse.json(MOCK_ADMIN_STATS)
  }
}
