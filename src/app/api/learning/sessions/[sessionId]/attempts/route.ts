import { createServerSupabaseClient } from '@/lib/supabase/server'
import { NextResponse } from 'next/server'

export async function POST(
  request: Request,
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
  if (session.status === 'completed') {
    return NextResponse.json({ error: '이미 완료된 세션입니다.' }, { status: 400 })
  }

  const body = await request.json()
  const { sessionProblemId, selectedChoice } = body

  if (sessionProblemId == null || selectedChoice == null) {
    return NextResponse.json({ error: 'Missing required fields' }, { status: 400 })
  }

  // session_problem 검증 (이 세션의 문제인지)
  const { data: sessionProblem } = await supabase
    .from('session_problems')
    .select('id, problem_id, session_id')
    .eq('id', sessionProblemId)
    .eq('session_id', sessionId)
    .single()

  if (!sessionProblem) {
    return NextResponse.json({ error: 'Problem not found in session' }, { status: 404 })
  }

  // 기존 시도 조회
  const { data: existingAttempts } = await supabase
    .from('attempts')
    .select('id, attempt_number, is_correct')
    .eq('session_problem_id', sessionProblemId)
    .order('attempt_number', { ascending: true })

  const attemptCount = existingAttempts?.length ?? 0

  // 최대 2회까지만 시도 가능
  if (attemptCount >= 2) {
    return NextResponse.json({ error: '이 문제는 더 이상 제출할 수 없습니다.' }, { status: 400 })
  }

  // 첫 시도에서 정답이면 두 번째 시도 불가
  if (attemptCount === 1 && existingAttempts![0].is_correct) {
    return NextResponse.json({ error: '이미 정답 처리된 문제입니다.' }, { status: 400 })
  }

  const attemptNumber = attemptCount + 1

  // 정답 조회
  const { data: problem } = await supabase
    .from('problems')
    .select('correct_choice, word_id')
    .eq('id', sessionProblem.problem_id)
    .single()

  if (!problem) {
    return NextResponse.json({ error: 'Problem data not found' }, { status: 500 })
  }

  const isCorrect = selectedChoice === problem.correct_choice

  // 첫 오답이면 meaning_shown = true
  const meaningShown = attemptNumber === 1 && !isCorrect

  // 시도 저장
  const { error: insertError } = await supabase
    .from('attempts')
    .insert({
      session_problem_id: sessionProblemId,
      attempt_number: attemptNumber,
      selected_choice: selectedChoice,
      is_correct: isCorrect,
      meaning_shown: meaningShown,
    })

  if (insertError) {
    return NextResponse.json({ error: '답안 저장에 실패했습니다.' }, { status: 500 })
  }

  // 첫 오답이면 단어 자동 저장 (티켓 18)
  if (meaningShown) {
    const { data: existingWord } = await supabase
      .from('user_words')
      .select('id, wrong_count, save_count')
      .eq('user_id', user.id)
      .eq('word_id', problem.word_id)
      .single()

    if (existingWord) {
      await supabase
        .from('user_words')
        .update({
          wrong_count: existingWord.wrong_count + 1,
          save_count: existingWord.save_count + 1,
          last_wrong_at: new Date().toISOString(),
          last_saved_at: new Date().toISOString(),
        })
        .eq('id', existingWord.id)
    } else {
      await supabase
        .from('user_words')
        .insert({
          user_id: user.id,
          word_id: problem.word_id,
        })
    }
  }

  // 뜻 데이터 (첫 오답 시만 반환)
  let meaningData = null
  if (meaningShown) {
    const { data: word } = await supabase
      .from('words')
      .select('meaning_ko')
      .eq('id', problem.word_id)
      .single()

    meaningData = word?.meaning_ko ?? null
  }

  return NextResponse.json({
    attemptNumber,
    isCorrect,
    meaningShown,
    meaningKo: meaningData,
    canRetry: attemptNumber === 1 && !isCorrect,
  })
}
