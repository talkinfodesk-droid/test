import { SupabaseClient } from '@supabase/supabase-js'
import { PROBLEMS_PER_SESSION } from './difficulty'

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export async function selectProblemsForSession(
  supabase: SupabaseClient<any>,
  userId: string,
  difficulty: number
): Promise<number[]> {
  // 최근 푼 문제 ID 조회 (최근 3세션)
  const { data: recentSessions } = await supabase
    .from('learning_sessions')
    .select('id')
    .eq('user_id', userId)
    .order('started_at', { ascending: false })
    .limit(3)

  let recentProblemIds: number[] = []
  if (recentSessions && recentSessions.length > 0) {
    const sessionIds = recentSessions.map((s) => s.id)
    const { data: recentProblems } = await supabase
      .from('session_problems')
      .select('problem_id')
      .in('session_id', sessionIds)

    recentProblemIds = recentProblems?.map((sp) => sp.problem_id) ?? []
  }

  // 현재 난이도의 활성 문제 조회
  let query = supabase
    .from('problems')
    .select('id')
    .eq('difficulty', difficulty)
    .eq('is_active', true)

  if (recentProblemIds.length > 0) {
    query = query.not('id', 'in', `(${recentProblemIds.join(',')})`)
  }

  const { data: availableProblems } = await query

  if (!availableProblems || availableProblems.length === 0) {
    // 제외할 문제가 없으면 전체에서 선택
    const { data: allProblems } = await supabase
      .from('problems')
      .select('id')
      .eq('difficulty', difficulty)
      .eq('is_active', true)

    if (!allProblems || allProblems.length === 0) return []
    return shuffleAndPick(allProblems.map((p) => p.id), PROBLEMS_PER_SESSION)
  }

  return shuffleAndPick(
    availableProblems.map((p) => p.id),
    PROBLEMS_PER_SESSION
  )
}

function shuffleAndPick(arr: number[], count: number): number[] {
  const shuffled = [...arr]
  for (let i = shuffled.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1))
    ;[shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]]
  }
  return shuffled.slice(0, count)
}
