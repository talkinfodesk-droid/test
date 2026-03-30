import { requireAdmin } from '@/lib/supabase/admin'
import { NextRequest, NextResponse } from 'next/server'

export async function GET(
  _request: NextRequest,
  { params }: { params: { problemId: string } }
) {
  const { supabase, isAdmin } = await requireAdmin()
  if (!isAdmin) return NextResponse.json({ error: 'Forbidden' }, { status: 403 })

  const { data, error } = await supabase
    .from('problems')
    .select('*, words(word, meaning_ko)')
    .eq('id', Number(params.problemId))
    .single()

  if (error) return NextResponse.json({ error: error.message }, { status: 404 })
  return NextResponse.json(data)
}

export async function PUT(
  request: NextRequest,
  { params }: { params: { problemId: string } }
) {
  const { supabase, isAdmin } = await requireAdmin()
  if (!isAdmin) return NextResponse.json({ error: 'Forbidden' }, { status: 403 })

  const body = await request.json()
  const { sentence, choices, correct_choice, difficulty, topic, is_active } = body

  const { data, error } = await supabase
    .from('problems')
    .update({ sentence, choices, correct_choice, difficulty, topic, is_active })
    .eq('id', Number(params.problemId))
    .select()
    .single()

  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json(data)
}
