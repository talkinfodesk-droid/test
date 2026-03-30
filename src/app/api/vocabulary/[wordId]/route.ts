import { createServerSupabaseClient } from '@/lib/supabase/server'
import { NextResponse } from 'next/server'
import { MOCK_VOCABULARY } from '@/lib/mock-data'

export async function GET(
  _request: Request,
  { params }: { params: { wordId: string } }
) {
  try {
    const supabase = await createServerSupabaseClient()
    const { wordId } = params

    const { data: { user } } = await supabase.auth.getUser()
    if (!user) {
      const mockWord = MOCK_VOCABULARY.find(w => w.wordId === Number(params.wordId)) || MOCK_VOCABULARY[0]
      return NextResponse.json({ id: mockWord.wordId, word: mockWord.word, meaning_ko: mockWord.meaningKo, example_en: mockWord.exampleEn, example_ko: mockWord.exampleKo, difficulty: mockWord.difficulty, topic: mockWord.topic, wrongCount: mockWord.wrongCount, saveCount: mockWord.saveCount, lastWrongAt: mockWord.lastSavedAt, lastSavedAt: mockWord.lastSavedAt })
    }

    // 본인 단어장의 단어인지 확인
    const { data: userWord } = await supabase
      .from('user_words')
      .select('id, wrong_count, save_count, last_wrong_at, last_saved_at')
      .eq('user_id', user.id)
      .eq('word_id', Number(wordId))
      .single()

    if (!userWord) {
      return NextResponse.json({ error: '단어장에 없는 단어입니다.' }, { status: 404 })
    }

    // 단어 상세 데이터
    const { data: word } = await supabase
      .from('words')
      .select('id, word, meaning_ko, example_en, example_ko, difficulty, topic')
      .eq('id', Number(wordId))
      .single()

    if (!word) {
      return NextResponse.json({ error: 'Word not found' }, { status: 404 })
    }

    return NextResponse.json({
      ...word,
      wrongCount: userWord.wrong_count,
      saveCount: userWord.save_count,
      lastWrongAt: userWord.last_wrong_at,
      lastSavedAt: userWord.last_saved_at,
    })
  } catch {
    const mockWord = MOCK_VOCABULARY.find(w => w.wordId === Number(params.wordId)) || MOCK_VOCABULARY[0]
    return NextResponse.json({ id: mockWord.wordId, word: mockWord.word, meaning_ko: mockWord.meaningKo, example_en: mockWord.exampleEn, example_ko: mockWord.exampleKo, difficulty: mockWord.difficulty, topic: mockWord.topic, wrongCount: mockWord.wrongCount, saveCount: mockWord.saveCount, lastWrongAt: mockWord.lastSavedAt, lastSavedAt: mockWord.lastSavedAt })
  }
}
