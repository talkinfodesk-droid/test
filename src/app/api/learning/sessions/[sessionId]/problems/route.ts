import { createServerSupabaseClient } from '@/lib/supabase/server'
import { NextResponse } from 'next/server'
import { MOCK_PROBLEMS } from '@/lib/mock-data'

export async function GET(
  _request: Request,
  { params }: { params: { sessionId: string } }
) {
  try {
    const supabase = await createServerSupabaseClient()
    const { sessionId } = params

    const { data: { user } } = await supabase.auth.getUser()
    if (!user) {
      return NextResponse.json({ sessionId, status: 'in_progress', problems: MOCK_PROBLEMS })
    }

    const { data: session } = await supabase
      .from('learning_sessions')
      .select('id, user_id, status')
      .eq('id', sessionId)
      .single()

    if (!session) {
      return NextResponse.json({ sessionId, status: 'in_progress', problems: MOCK_PROBLEMS })
    }

    if (session.user_id !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    const { data: sessionProblems } = await supabase
      .from('session_problems')
      .select(`
        id, order_index, problem_id,
        problems ( id, sentence, choices, difficulty, topic, word_id, words ( word, meaning_ko ) )
      `)
      .eq('session_id', sessionId)
      .order('order_index', { ascending: true })

    if (!sessionProblems || sessionProblems.length === 0) {
      return NextResponse.json({ sessionId, status: 'in_progress', problems: MOCK_PROBLEMS })
    }

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const problems = sessionProblems.map((sp: any) => ({
      sessionProblemId: sp.id,
      orderIndex: sp.order_index,
      problemId: sp.problems.id,
      sentence: sp.problems.sentence,
      choices: sp.problems.choices,
      difficulty: sp.problems.difficulty,
      topic: sp.problems.topic,
      word: sp.problems.words?.word ?? '',
    }))

    return NextResponse.json({ sessionId, status: session.status, problems })
  } catch {
    return NextResponse.json({ sessionId: params.sessionId, status: 'in_progress', problems: MOCK_PROBLEMS })
  }
}
