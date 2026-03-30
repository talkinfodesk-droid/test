import { createServerSupabaseClient } from '@/lib/supabase/server'
import { getMonthNumber, getDifficultyByMonth } from '@/lib/learning/difficulty'
import { NextResponse } from 'next/server'

export async function GET() {
  const supabase = await createServerSupabaseClient()

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  // 프로필 조회
  const { data: profile } = await supabase
    .from('users')
    .select('nickname, created_at, learning_started_at')
    .eq('id', user.id)
    .single()

  if (!profile) {
    return NextResponse.json({ error: 'Profile not found' }, { status: 404 })
  }

  const monthNumber = getMonthNumber(profile.learning_started_at)
  const difficulty = getDifficultyByMonth(monthNumber)

  // 누적 학습 수 (완료된 세션)
  const { count: totalSessions } = await supabase
    .from('learning_sessions')
    .select('*', { count: 'exact', head: true })
    .eq('user_id', user.id)
    .eq('status', 'completed')

  // 저장 단어 수
  const { count: savedWordCount } = await supabase
    .from('user_words')
    .select('*', { count: 'exact', head: true })
    .eq('user_id', user.id)

  return NextResponse.json({
    nickname: profile.nickname,
    email: user.email,
    createdAt: profile.created_at,
    learningStartedAt: profile.learning_started_at,
    monthNumber,
    difficulty,
    totalSessions: totalSessions ?? 0,
    savedWordCount: savedWordCount ?? 0,
  })
}
