import { createServerSupabaseClient } from '@/lib/supabase/server'
import { getMonthNumber, getDifficultyByMonth } from '@/lib/learning/difficulty'
import { NextResponse } from 'next/server'
import { MOCK_HOME } from '@/lib/mock-data'

export async function GET() {
  try {
    const supabase = await createServerSupabaseClient()

    const { data: { user } } = await supabase.auth.getUser()
    if (!user) {
      return NextResponse.json(MOCK_HOME)
    }

    const { data: profile } = await supabase
      .from('users')
      .select('nickname, learning_started_at')
      .eq('id', user.id)
      .single()

    if (!profile) {
      return NextResponse.json(MOCK_HOME)
    }

    const monthNumber = getMonthNumber(profile.learning_started_at)
    const difficulty = getDifficultyByMonth(monthNumber)

    const today = new Date()
    today.setHours(0, 0, 0, 0)
    const { data: todaySession } = await supabase
      .from('learning_sessions')
      .select('id, status')
      .eq('user_id', user.id)
      .gte('started_at', today.toISOString())
      .limit(1)
      .single()

    const { data: lastSession } = await supabase
      .from('learning_sessions')
      .select('id, started_at, status')
      .eq('user_id', user.id)
      .eq('status', 'completed')
      .order('started_at', { ascending: false })
      .limit(1)
      .single()

    let lastSessionSummary = null
    if (lastSession) {
      const { data: sessionProblems } = await supabase
        .from('session_problems')
        .select('id')
        .eq('session_id', lastSession.id)

      if (sessionProblems) {
        const spIds = sessionProblems.map((sp) => sp.id)
        const { data: attempts } = await supabase
          .from('attempts')
          .select('is_correct, attempt_number')
          .in('session_problem_id', spIds)
          .eq('attempt_number', 1)

        const totalProblems = sessionProblems.length
        const correctCount = attempts?.filter((a) => a.is_correct).length ?? 0

        lastSessionSummary = {
          date: lastSession.started_at,
          totalProblems,
          correctCount,
          wrongCount: totalProblems - correctCount,
        }
      }
    }

    const { count: savedWordCount } = await supabase
      .from('user_words')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', user.id)

    return NextResponse.json({
      nickname: profile.nickname,
      monthNumber,
      difficulty,
      todayCompleted: todaySession?.status === 'completed',
      todaySessionId: todaySession?.id ?? null,
      lastSessionSummary,
      savedWordCount: savedWordCount ?? 0,
    })
  } catch {
    return NextResponse.json(MOCK_HOME)
  }
}
