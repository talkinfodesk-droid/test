import { createServerSupabaseClient } from '@/lib/supabase/server'
import { NextRequest, NextResponse } from 'next/server'
import { MOCK_VOCABULARY } from '@/lib/mock-data'

export async function GET(request: NextRequest) {
  try {
    const supabase = await createServerSupabaseClient()

    const { data: { user } } = await supabase.auth.getUser()
    if (!user) {
      return NextResponse.json({ words: MOCK_VOCABULARY })
    }

    // 정렬 옵션
    const { searchParams } = new URL(request.url)
    const sort = searchParams.get('sort') || 'recent' // recent | wrong_count | difficulty | topic

    let query = supabase
      .from('user_words')
      .select(`
        id,
        word_id,
        wrong_count,
        save_count,
        last_wrong_at,
        last_saved_at,
        words (
          id,
          word,
          meaning_ko,
          example_en,
          example_ko,
          difficulty,
          topic
        )
      `)
      .eq('user_id', user.id)

    switch (sort) {
      case 'wrong_count':
        query = query.order('wrong_count', { ascending: false })
        break
      case 'difficulty':
        // user_words 테이블 기준 정렬 후 클라이언트에서 재정렬
        query = query.order('last_saved_at', { ascending: false })
        break
      case 'topic':
        query = query.order('last_saved_at', { ascending: false })
        break
      default: // recent
        query = query.order('last_saved_at', { ascending: false })
    }

    const { data: userWords, error } = await query

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    let words = (userWords ?? []).map((uw: any) => ({
      userWordId: uw.id,
      wordId: uw.word_id,
      wrongCount: uw.wrong_count,
      saveCount: uw.save_count,
      lastWrongAt: uw.last_wrong_at,
      lastSavedAt: uw.last_saved_at,
      word: uw.words?.word,
      meaningKo: uw.words?.meaning_ko,
      exampleEn: uw.words?.example_en,
      exampleKo: uw.words?.example_ko,
      difficulty: uw.words?.difficulty,
      topic: uw.words?.topic,
    }))

    // difficulty, topic 정렬은 클라이언트 사이드
    if (sort === 'difficulty') {
      words = words.sort((a: { difficulty: number }, b: { difficulty: number }) => b.difficulty - a.difficulty)
    } else if (sort === 'topic') {
      words = words.sort((a: { topic: string }, b: { topic: string }) => a.topic.localeCompare(b.topic))
    }

    return NextResponse.json({ words })
  } catch {
    return NextResponse.json({ words: MOCK_VOCABULARY })
  }
}
