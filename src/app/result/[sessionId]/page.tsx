'use client'

import { useEffect, useState } from 'react'
import { useParams, useRouter } from 'next/navigation'

interface ResultData {
  totalProblems: number
  correctCount: number
  wrongCount: number
  savedWordCount: number
}

export default function ResultPage() {
  const params = useParams()
  const router = useRouter()
  const sessionId = params.sessionId as string

  const [result, setResult] = useState<ResultData | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetch(`/api/learning/sessions/${sessionId}/result`)
      .then((res) => res.json())
      .then((data) => {
        setResult(data)
        setLoading(false)
      })
  }, [sessionId])

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <p className="text-gray-500">결과를 불러오는 중...</p>
      </div>
    )
  }

  if (!result) return null

  const accuracy = result.totalProblems > 0
    ? Math.round((result.correctCount / result.totalProblems) * 100)
    : 0

  return (
    <div className="min-h-screen bg-white flex flex-col items-center justify-center px-4">
      <div className="w-full max-w-sm">
        <h1 className="text-2xl font-bold text-center text-gray-900 mb-2">
          학습 완료!
        </h1>
        <p className="text-center text-gray-500 mb-8">
          오늘의 학습 결과입니다
        </p>

        {/* 정답률 원형 표시 */}
        <div className="flex justify-center mb-8">
          <div className="w-32 h-32 rounded-full border-8 border-blue-500 flex items-center justify-center">
            <div className="text-center">
              <p className="text-3xl font-bold text-blue-600">{accuracy}%</p>
              <p className="text-xs text-gray-500">정답률</p>
            </div>
          </div>
        </div>

        {/* 결과 카드들 */}
        <div className="grid grid-cols-2 gap-4 mb-8">
          <div className="bg-gray-50 rounded-xl p-4 text-center">
            <p className="text-2xl font-bold text-gray-900">{result.totalProblems}</p>
            <p className="text-sm text-gray-500">총 문제</p>
          </div>
          <div className="bg-green-50 rounded-xl p-4 text-center">
            <p className="text-2xl font-bold text-green-600">{result.correctCount}</p>
            <p className="text-sm text-gray-500">정답</p>
          </div>
          <div className="bg-red-50 rounded-xl p-4 text-center">
            <p className="text-2xl font-bold text-red-500">{result.wrongCount}</p>
            <p className="text-sm text-gray-500">오답</p>
          </div>
          <div className="bg-orange-50 rounded-xl p-4 text-center">
            <p className="text-2xl font-bold text-orange-500">{result.savedWordCount}</p>
            <p className="text-sm text-gray-500">저장 단어</p>
          </div>
        </div>

        {/* 이동 버튼 */}
        <div className="space-y-3">
          <button
            onClick={() => router.push('/home')}
            className="w-full py-3 bg-blue-600 text-white rounded-xl font-bold hover:bg-blue-700 transition"
          >
            학습 홈으로
          </button>
          <button
            onClick={() => router.push('/vocabulary')}
            className="w-full py-3 bg-white text-blue-600 border border-blue-600 rounded-xl font-bold hover:bg-blue-50 transition"
          >
            내 단어장으로
          </button>
        </div>
      </div>
    </div>
  )
}
