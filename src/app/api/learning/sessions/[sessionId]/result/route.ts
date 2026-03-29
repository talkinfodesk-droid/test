import { createServerSupabaseClient } from '@/lib/supabase/server'
import { NextResponse } from 'next/server'

export async function GET(
  _request: Request,
  { params }: { params: { sessionId: string } }
) {
  const supabase = await createServerSupabaseClient()
  const { sessionId } = params

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  // 세션 소유자 확인
  const { data: session } = await supabase
    .from('learning_sessions')
    .select('id, user_id, status')
    .eq('id', sessionId)
    .single()

  if (!session) {
    return NextResponse.json({ error: 'Session not found' }, { status: 404 })
  }
  if (session.user_id !== user.id) {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
  }

  // 세션을 완료 상태로 변경
  if (session.status !== 'completed') {
    await supabase
      .from('learning_sessions')
      .update({ status: 'completed', completed_at: new Date().toISOString() })
      .eq('id', sessionId)
  }

  // 세션 문제 목록
  const { data: sessionProblems } = await supabase
    .from('session_problems')
    .select('id')
    .eq('session_id', sessionId)

  if (!sessionProblems || sessionProblems.length === 0) {
    return NextResponse.json({
      totalProblems: 0,
      correctCount: 0,
      wrongCount: 0,
      savedWordCount: 0,
    })
  }

  const spIds = sessionProblems.map((sp) => sp.id)

  // 첫 시도 기준으로 정답/오답 집계
  const { data: firstAttempts } = await supabase
    .from('attempts')
    .select('is_correct')
    .in('session_problem_id', spIds)
    .eq('attempt_number', 1)

  const totalProblems = sessionProblems.length
  const correctCount = firstAttempts?.filter((a) => a.is_correct).length ?? 0
  const wrongCount = totalProblems - correctCount

  // 이번 세션에서 저장된 단어 수 (meaning_shown된 문제 수)
  const { data: shownAttempts } = await supabase
    .from('attempts')
    .select('id')
    .in('session_problem_id', spIds)
    .eq('meaning_shown', true)

  const savedWordCount = shownAttempts?.length ?? 0

  return NextResponse.json({
    totalProblems,
    correctCount,
    wrongCount,
    savedWordCount,
  })
}
