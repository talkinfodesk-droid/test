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

  // 문제 목록 조회 (정답 제외)
  const { data: sessionProblems } = await supabase
    .from('session_problems')
    .select(`
      id,
      order_index,
      problem_id,
      problems (
        id,
        sentence,
        choices,
        difficulty,
        topic,
        word_id,
        words (
          word,
          meaning_ko
        )
      )
    `)
    .eq('session_id', sessionId)
    .order('order_index', { ascending: true })

  if (!sessionProblems) {
    return NextResponse.json({ error: 'Problems not found' }, { status: 404 })
  }

  // 정답(correct_choice)을 제외하고 반환
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const problems = sessionProblems.map((sp: any) => {
    const problem = sp.problems

    return {
      sessionProblemId: sp.id,
      orderIndex: sp.order_index,
      problemId: problem.id,
      sentence: problem.sentence,
      choices: problem.choices,
      difficulty: problem.difficulty,
      topic: problem.topic,
      word: problem.words?.word ?? '',
    }
  })

  return NextResponse.json({
    sessionId,
    status: session.status,
    problems,
  })
}
