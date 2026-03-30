import { requireAdmin } from '@/lib/supabase/admin'
import { NextResponse } from 'next/server'

export async function GET() {
  const { supabase, isAdmin } = await requireAdmin()
  if (!isAdmin) {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
  }

  const today = new Date()
  today.setHours(0, 0, 0, 0)

  const [
    { count: totalUsers },
    { count: todayLearners },
    { count: totalProblems },
    { count: totalWords },
  ] = await Promise.all([
    supabase.from('users').select('*', { count: 'exact', head: true }),
    supabase.from('learning_sessions').select('*', { count: 'exact', head: true })
      .gte('started_at', today.toISOString()),
    supabase.from('problems').select('*', { count: 'exact', head: true }),
    supabase.from('words').select('*', { count: 'exact', head: true }),
  ])

  // 평균 정답률
  const { data: allFirstAttempts } = await supabase
    .from('attempts')
    .select('is_correct')
    .eq('attempt_number', 1)

  let avgAccuracy = 0
  if (allFirstAttempts && allFirstAttempts.length > 0) {
    const correct = allFirstAttempts.filter((a) => a.is_correct).length
    avgAccuracy = Math.round((correct / allFirstAttempts.length) * 100)
  }

  return NextResponse.json({
    totalUsers: totalUsers ?? 0,
    todayLearners: todayLearners ?? 0,
    totalProblems: totalProblems ?? 0,
    totalWords: totalWords ?? 0,
    avgAccuracy,
  })
}
