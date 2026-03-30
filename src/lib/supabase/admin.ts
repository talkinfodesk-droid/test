import { createServerSupabaseClient } from './server'

export async function requireAdmin() {
  const supabase = await createServerSupabaseClient()

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return { supabase, user: null, isAdmin: false }

  const { data: profile } = await supabase
    .from('users')
    .select('is_admin')
    .eq('id', user.id)
    .single()

  return {
    supabase,
    user,
    isAdmin: profile?.is_admin === true,
  }
}
