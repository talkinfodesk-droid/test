'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import BottomNav from '@/components/BottomNav'
import { DIFFICULTY_LABELS } from '@/lib/learning/difficulty'

interface MyPageData {
  nickname: string
  email: string
  createdAt: string
  learningStartedAt: string | null
  monthNumber: number
  difficulty: number
  totalSessions: number
  savedWordCount: number
}

export default function MyPage() {
  const [data, setData] = useState<MyPageData | null>(null)
  const [loading, setLoading] = useState(true)
  const router = useRouter()
  const supabase = createClient()

  useEffect(() => {
    fetch('/api/mypage')
      .then((res) => res.json())
      .then((d) => {
        setData(d)
        setLoading(false)
      })
  }, [])

  async function handleLogout() {
    await supabase.auth.signOut()
    router.push('/')
  }

  function formatDate(dateStr: string | null) {
    if (!dateStr) return '-'
    return new Date(dateStr).toLocaleDateString('ko-KR', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    })
  }

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <p className="text-gray-500">로딩 중...</p>
      </div>
    )
  }

  if (!data) return null

  return (
    <div className="min-h-screen pb-20 bg-gray-50">
      <div className="max-w-lg mx-auto px-4 py-6">
        <h1 className="text-xl font-bold text-gray-900 mb-6">마이페이지</h1>

        {/* 프로필 카드 */}
        <div className="bg-white rounded-xl p-5 shadow-sm border mb-6">
          <h2 className="text-lg font-bold text-gray-900 mb-1">{data.nickname}</h2>
          <p className="text-sm text-gray-500">{data.email}</p>
        </div>

        {/* 학습 정보 */}
        <div className="bg-white rounded-xl shadow-sm border mb-6">
          <div className="p-4 border-b">
            <h3 className="text-sm font-medium text-gray-500">학습 정보</h3>
          </div>
          <div className="divide-y">
            <div className="flex justify-between px-4 py-3">
              <span className="text-gray-600">가입일</span>
              <span className="text-gray-900 font-medium">{formatDate(data.createdAt)}</span>
            </div>
            <div className="flex justify-between px-4 py-3">
              <span className="text-gray-600">학습 시작일</span>
              <span className="text-gray-900 font-medium">{formatDate(data.learningStartedAt)}</span>
            </div>
            <div className="flex justify-between px-4 py-3">
              <span className="text-gray-600">현재 월차</span>
              <span className="text-gray-900 font-medium">{data.monthNumber}개월차</span>
            </div>
            <div className="flex justify-between px-4 py-3">
              <span className="text-gray-600">현재 난이도</span>
              <span className="text-gray-900 font-medium">{DIFFICULTY_LABELS[data.difficulty]}</span>
            </div>
          </div>
        </div>

        {/* 학습 통계 */}
        <div className="grid grid-cols-2 gap-4 mb-8">
          <div className="bg-white rounded-xl p-4 shadow-sm border text-center">
            <p className="text-2xl font-bold text-blue-600">{data.totalSessions}</p>
            <p className="text-sm text-gray-500">누적 학습 수</p>
          </div>
          <div className="bg-white rounded-xl p-4 shadow-sm border text-center">
            <p className="text-2xl font-bold text-orange-500">{data.savedWordCount}</p>
            <p className="text-sm text-gray-500">저장 단어 수</p>
          </div>
        </div>

        {/* 로그아웃 */}
        <button
          onClick={handleLogout}
          className="w-full py-3 text-red-500 bg-white border border-red-200 rounded-xl font-medium hover:bg-red-50 transition"
        >
          로그아웃
        </button>
      </div>

      <BottomNav />
    </div>
  )
}
