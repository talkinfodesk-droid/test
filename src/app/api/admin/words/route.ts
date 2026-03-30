import { requireAdmin } from '@/lib/supabase/admin'
import { NextRequest, NextResponse } from 'next/server'

export async function GET(request: NextRequest) {
  const { supabase, isAdmin } = await requireAdmin()
  if (!isAdmin) return NextResponse.json({ error: 'Forbidden' }, { status: 403 })

  const { searchParams } = new URL(request.url)
  const search = searchParams.get('search') || ''
  const difficulty = searchParams.get('difficulty')
  const topic = searchParams.get('topic')

  let query = supabase
    .from('words')
    .select('*')
    .order('created_at', { ascending: false })

  if (search) {
    query = query.or(`word.ilike.%${search}%,meaning_ko.ilike.%${search}%`)
  }
  if (difficulty) {
    query = query.eq('difficulty', Number(difficulty))
  }
  if (topic) {
    query = query.eq('topic', topic)
  }

  const { data: words, error } = await query
  if (error) return NextResponse.json({ error: error.message }, { status: 500 })

  return NextResponse.json({ words: words ?? [] })
}

export async function POST(request: NextRequest) {
  const { supabase, isAdmin } = await requireAdmin()
  if (!isAdmin) return NextResponse.json({ error: 'Forbidden' }, { status: 403 })

  const body = await request.json()
  const { word, meaning_ko, example_en, example_ko, difficulty, topic } = body

  const { data, error } = await supabase
    .from('words')
    .insert({ word, meaning_ko, example_en, example_ko, difficulty, topic })
    .select()
    .single()

  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json(data, { status: 201 })
}
