import { createServerSupabaseClient } from '@/lib/supabase/server'
import { NextResponse } from 'next/server'
import { MOCK_ANSWERS } from '@/lib/mock-data'

// 목업 시도 상태 추적 (메모리)
const mockAttemptState: Record<number, number> = {}

export async function POST(
  request: Request,
  { params }: { params: { sessionId: string } }
) {
  const body = await request.json()
  const { sessionProblemId, selectedChoice } = body

  try {
    const supabase = await createServerSupabaseClient()
    const { sessionId } = params

    const { data: { user } } = await supabase.auth.getUser()

    if (!user) {
      return mockResponse(sessionProblemId, selectedChoice)
    }

    const { data: session } = await supabase
      .from('learning_sessions')
      .select('id, user_id, status')
      .eq('id', sessionId)
      .single()

    if (!session || session.user_id !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    const { data: sessionProblem } = await supabase
      .from('session_problems')
      .select('id, problem_id, session_id')
      .eq('id', sessionProblemId)
      .eq('session_id', sessionId)
      .single()

    if (!sessionProblem) {
      return NextResponse.json({ error: 'Problem not found' }, { status: 404 })
    }

    const { data: existingAttempts } = await supabase
      .from('attempts')
      .select('id, attempt_number, is_correct')
      .eq('session_problem_id', sessionProblemId)
      .order('attempt_number', { ascending: true })

    const attemptCount = existingAttempts?.length ?? 0
    if (attemptCount >= 2) {
      return NextResponse.json({ error: '이 문제는 더 이상 제출할 수 없습니다.' }, { status: 400 })
    }
    if (attemptCount === 1 && existingAttempts![0].is_correct) {
      return NextResponse.json({ error: '이미 정답 처리된 문제입니다.' }, { status: 400 })
    }

    const attemptNumber = attemptCount + 1

    const { data: problem } = await supabase
      .from('problems')
      .select('correct_choice, word_id')
      .eq('id', sessionProblem.problem_id)
      .single()

    if (!problem) {
      return NextResponse.json({ error: 'Problem data not found' }, { status: 500 })
    }

    const isCorrect = selectedChoice === problem.correct_choice
    const meaningShown = attemptNumber === 1 && !isCorrect

    await supabase.from('attempts').insert({
      session_problem_id: sessionProblemId,
      attempt_number: attemptNumber,
      selected_choice: selectedChoice,
      is_correct: isCorrect,
      meaning_shown: meaningShown,
    })

    if (meaningShown) {
      const { data: existingWord } = await supabase
        .from('user_words')
        .select('id, wrong_count, save_count')
        .eq('user_id', user.id)
        .eq('word_id', problem.word_id)
        .single()

      if (existingWord) {
        await supabase.from('user_words').update({
          wrong_count: existingWord.wrong_count + 1,
          save_count: existingWord.save_count + 1,
          last_wrong_at: new Date().toISOString(),
          last_saved_at: new Date().toISOString(),
        }).eq('id', existingWord.id)
      } else {
        await supabase.from('user_words').insert({ user_id: user.id, word_id: problem.word_id })
      }
    }

    let meaningData = null
    if (meaningShown) {
      const { data: word } = await supabase.from('words').select('meaning_ko').eq('id', problem.word_id).single()
      meaningData = word?.meaning_ko ?? null
    }

    return NextResponse.json({ attemptNumber, isCorrect, meaningShown, meaningKo: meaningData, canRetry: attemptNumber === 1 && !isCorrect })
  } catch {
    return mockResponse(sessionProblemId, selectedChoice)
  }
}

function mockResponse(sessionProblemId: number, selectedChoice: number) {
  const answer = MOCK_ANSWERS[sessionProblemId]
  const attemptCount = mockAttemptState[sessionProblemId] || 0

  if (attemptCount >= 2) {
    return NextResponse.json({ error: '이 문제는 더 이상 제출할 수 없습니다.' }, { status: 400 })
  }

  const attemptNumber = attemptCount + 1
  const isCorrect = answer ? selectedChoice === answer.correctChoice : false
  const meaningShown = attemptNumber === 1 && !isCorrect

  mockAttemptState[sessionProblemId] = attemptNumber

  return NextResponse.json({
    attemptNumber,
    isCorrect,
    meaningShown,
    meaningKo: meaningShown ? (answer?.meaningKo ?? null) : null,
    canRetry: attemptNumber === 1 && !isCorrect,
  })
}
