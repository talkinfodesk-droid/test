'use client'

import { useEffect, useState } from 'react'
import { useParams } from 'next/navigation'

interface Problem {
  sessionProblemId: number
  orderIndex: number
  problemId: number
  sentence: string
  choices: string[]
  difficulty: number
  topic: string
  word: string
}

interface SessionData {
  sessionId: string
  status: string
  problems: Problem[]
}

export default function QuizPage() {
  const params = useParams()
  const sessionId = params.sessionId as string
  const [session, setSession] = useState<SessionData | null>(null)
  const [currentIndex, setCurrentIndex] = useState(0)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetch(`/api/learning/sessions/${sessionId}/problems`)
      .then((res) => res.json())
      .then((data) => {
        setSession(data)
        setLoading(false)
      })
  }, [sessionId])

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <p className="text-gray-500">문제를 불러오는 중...</p>
      </div>
    )
  }

  if (!session || !session.problems || session.problems.length === 0) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <p className="text-gray-500">문제를 찾을 수 없습니다.</p>
      </div>
    )
  }

  const problem = session.problems[currentIndex]
  const totalProblems = session.problems.length

  return (
    <div className="min-h-screen bg-white">
      <div className="max-w-lg mx-auto px-4 py-6">
        {/* 진행률 */}
        <div className="mb-6">
          <div className="flex justify-between text-sm text-gray-500 mb-2">
            <span>문제 {currentIndex + 1} / {totalProblems}</span>
            <span>{Math.round(((currentIndex + 1) / totalProblems) * 100)}%</span>
          </div>
          <div className="w-full bg-gray-200 rounded-full h-2">
            <div
              className="bg-blue-600 h-2 rounded-full transition-all"
              style={{ width: `${((currentIndex + 1) / totalProblems) * 100}%` }}
            />
          </div>
        </div>

        {/* 문제 */}
        <div className="mb-8">
          <p className="text-sm text-gray-500 mb-2">{problem.topic}</p>
          <h2 className="text-xl font-bold text-gray-900 mb-1">{problem.word}</h2>
          <p className="text-gray-700">{problem.sentence}</p>
        </div>

        {/* 선택지 - 묶음 B 티켓에서 상세 구현 예정 */}
        <div className="space-y-3">
          {(problem.choices as string[]).map((choice, index) => (
            <button
              key={index}
              className="w-full text-left px-4 py-3 border border-gray-300 rounded-lg hover:border-blue-500 hover:bg-blue-50 transition"
            >
              {index + 1}. {choice}
            </button>
          ))}
        </div>

        {/* 다음 문제 이동 (임시) */}
        <div className="mt-8 flex justify-end">
          <button
            onClick={() => {
              if (currentIndex < totalProblems - 1) {
                setCurrentIndex(currentIndex + 1)
              }
            }}
            disabled={currentIndex >= totalProblems - 1}
            className="px-6 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition disabled:opacity-50"
          >
            다음 문제
          </button>
        </div>
      </div>
    </div>
  )
}
