'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import BottomNav from '@/components/BottomNav'
import { DIFFICULTY_LABELS } from '@/lib/learning/difficulty'

interface HomeData {
  nickname: string
  monthNumber: number
  difficulty: number
  todayCompleted: boolean
  todaySessionId: string | null
  lastSessionSummary: {
    date: string
    totalProblems: number
    correctCount: number
    wrongCount: number
  } | null
  savedWordCount: number
}

export default function HomePage() {
  const [data, setData] = useState<HomeData | null>(null)
  const [loading, setLoading] = useState(true)
  const [starting, setStarting] = useState(false)
  const router = useRouter()

  useEffect(() => {
    fetch('/api/learning/home')
      .then((res) => res.json())
      .then((d) => {
        setData(d)
        setLoading(false)
      })
  }, [])

  async function handleStartLearning() {
    setStarting(true)
    const res = await fetch('/api/learning/sessions', { method: 'POST' })
    const result = await res.json()

    if (result.sessionId) {
      router.push(`/quiz/${result.sessionId}`)
    } else {
      alert(result.error || '학습을 시작할 수 없습니다.')
      setStarting(false)
    }
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
    <div className="min-h-screen pb-20">
      <div className="max-w-lg mx-auto px-4 py-6">
        <h1 className="text-xl font-bold text-gray-900 mb-6">
          안녕하세요, {data.nickname}님!
        </h1>

        {/* 월차 & 난이도 카드 */}
        <div className="grid grid-cols-2 gap-4 mb-6">
          <div className="bg-white rounded-xl p-4 shadow-sm border">
            <p className="text-sm text-gray-500">현재 월차</p>
            <p className="text-2xl font-bold text-blue-600">
              {data.monthNumber}개월차
            </p>
          </div>
          <div className="bg-white rounded-xl p-4 shadow-sm border">
            <p className="text-sm text-gray-500">현재 난이도</p>
            <p className="text-2xl font-bold text-green-600">
              {DIFFICULTY_LABELS[data.difficulty]}
            </p>
          </div>
        </div>

        {/* 학습 시작 버튼 */}
        <button
          onClick={handleStartLearning}
          disabled={starting || data.todayCompleted}
          className="w-full py-4 bg-blue-600 text-white rounded-xl font-bold text-lg hover:bg-blue-700 transition disabled:opacity-50 mb-6"
        >
          {data.todayCompleted
            ? '오늘 학습 완료!'
            : starting
            ? '준비 중...'
            : '오늘의 학습 시작'}
        </button>

        {/* 최근 학습 요약 */}
        {data.lastSessionSummary && (
          <div className="bg-white rounded-xl p-4 shadow-sm border mb-4">
            <h2 className="text-sm font-medium text-gray-500 mb-3">
              최근 학습 요약
            </h2>
            <div className="grid grid-cols-3 gap-2 text-center">
              <div>
                <p className="text-lg font-bold">{data.lastSessionSummary.totalProblems}</p>
                <p className="text-xs text-gray-500">총 문제</p>
              </div>
              <div>
                <p className="text-lg font-bold text-green-600">
                  {data.lastSessionSummary.correctCount}
                </p>
                <p className="text-xs text-gray-500">정답</p>
              </div>
              <div>
                <p className="text-lg font-bold text-red-500">
                  {data.lastSessionSummary.wrongCount}
                </p>
                <p className="text-xs text-gray-500">오답</p>
              </div>
            </div>
          </div>
        )}

        {/* 저장 단어 수 */}
        <div className="bg-white rounded-xl p-4 shadow-sm border">
          <div className="flex justify-between items-center">
            <div>
              <p className="text-sm text-gray-500">저장된 단어</p>
              <p className="text-2xl font-bold text-orange-500">
                {data.savedWordCount}개
              </p>
            </div>
            <button
              onClick={() => router.push('/vocabulary')}
              className="text-sm text-blue-600 hover:underline"
            >
              단어장 보기 &rarr;
            </button>
          </div>
        </div>
      </div>

      <BottomNav />
    </div>
  )
}
