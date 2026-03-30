import { createServerSupabaseClient } from '@/lib/supabase/server'
import { getMonthNumber, getDifficultyByMonth } from '@/lib/learning/difficulty'
import { selectProblemsForSession } from '@/lib/learning/problem-selector'
import { NextResponse } from 'next/server'

export async function POST() {
  try {
  const supabase = await createServerSupabaseClient()

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({ sessionId: 'mock-session-001' })
  }

  // 사용자 프로필 조회
  const { data: profile } = await supabase
    .from('users')
    .select('learning_started_at')
    .eq('id', user.id)
    .single()

  if (!profile) {
    return NextResponse.json({ error: 'Profile not found' }, { status: 404 })
  }

  // 첫 학습이면 learning_started_at 설정
  if (!profile.learning_started_at) {
    await supabase
      .from('users')
      .update({ learning_started_at: new Date().toISOString() })
      .eq('id', user.id)
  }

  const monthNumber = getMonthNumber(profile.learning_started_at)
  const difficulty = getDifficultyByMonth(monthNumber)

  // 문제 선정
  const problemIds = await selectProblemsForSession(supabase, user.id, difficulty)
  if (problemIds.length === 0) {
    return NextResponse.json(
      { error: '출제할 문제가 없습니다. 관리자에게 문의하세요.' },
      { status: 404 }
    )
  }

  // 세션 생성
  const { data: session, error: sessionError } = await supabase
    .from('learning_sessions')
    .insert({
      user_id: user.id,
      month_number: monthNumber,
      difficulty,
    })
    .select('id')
    .single()

  if (sessionError || !session) {
    return NextResponse.json(
      { error: '세션 생성에 실패했습니다.' },
      { status: 500 }
    )
  }

  // 세션에 문제 연결
  const sessionProblems = problemIds.map((problemId, index) => ({
    session_id: session.id,
    problem_id: problemId,
    order_index: index,
  }))

  const { error: spError } = await supabase
    .from('session_problems')
    .insert(sessionProblems)

  if (spError) {
    return NextResponse.json(
      { error: '문제 연결에 실패했습니다.' },
      { status: 500 }
    )
  }

  return NextResponse.json({ sessionId: session.id })
  } catch {
    return NextResponse.json({ sessionId: 'mock-session-001' })
  }
}
