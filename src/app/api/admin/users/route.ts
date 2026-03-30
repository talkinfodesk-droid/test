import { requireAdmin } from '@/lib/supabase/admin'
import { NextResponse } from 'next/server'
import { getMonthNumber, getDifficultyByMonth } from '@/lib/learning/difficulty'

export async function GET() {
  const { supabase, isAdmin } = await requireAdmin()
  if (!isAdmin) return NextResponse.json({ error: 'Forbidden' }, { status: 403 })

  const { data: users, error } = await supabase
    .from('users')
    .select('id, nickname, created_at, learning_started_at, is_admin')
    .order('created_at', { ascending: false })

  if (error) return NextResponse.json({ error: error.message }, { status: 500 })

  // 각 사용자의 마지막 학습일 조회
  const enriched = await Promise.all(
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    (users ?? []).map(async (u: any) => {
      const { data: lastSession } = await supabase
        .from('learning_sessions')
        .select('started_at')
        .eq('user_id', u.id)
        .order('started_at', { ascending: false })
        .limit(1)
        .single()

      const monthNumber = getMonthNumber(u.learning_started_at)
      return {
        id: u.id,
        nickname: u.nickname,
        isAdmin: u.is_admin,
        createdAt: u.created_at,
        monthNumber,
        difficulty: getDifficultyByMonth(monthNumber),
        lastLearningAt: lastSession?.started_at ?? null,
      }
    })
  )

  return NextResponse.json({ users: enriched })
}
