import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

export async function updateSession(request: NextRequest) {
  let supabaseResponse = NextResponse.next({ request })

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll()
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) =>
            request.cookies.set(name, value)
          )
          supabaseResponse = NextResponse.next({ request })
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options)
          )
        },
      },
    }
  )

  // 목업 모드: placeholder URL이면 인증 체크 건너뜀
  const isMockMode = process.env.NEXT_PUBLIC_SUPABASE_URL?.includes('placeholder')

  if (!isMockMode) {
    try {
      const {
        data: { user },
      } = await supabase.auth.getUser()

      const protectedPaths = ['/home', '/quiz', '/result', '/vocabulary', '/mypage']
      const isProtected = protectedPaths.some((path) =>
        request.nextUrl.pathname.startsWith(path)
      )

      if (isProtected && !user) {
        const url = request.nextUrl.clone()
        url.pathname = '/login'
        return NextResponse.redirect(url)
      }

      if (user && (request.nextUrl.pathname === '/login' || request.nextUrl.pathname === '/signup')) {
        const url = request.nextUrl.clone()
        url.pathname = '/home'
        return NextResponse.redirect(url)
      }
    } catch {
      // Supabase 미연결 시 모든 페이지 접근 허용
    }
  }

  return supabaseResponse
}
