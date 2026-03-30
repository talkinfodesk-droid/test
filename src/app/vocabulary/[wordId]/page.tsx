'use client'

import { useEffect, useState } from 'react'
import { useParams, useRouter } from 'next/navigation'
import { DIFFICULTY_LABELS } from '@/lib/learning/difficulty'

interface WordDetail {
  id: number
  word: string
  meaning_ko: string
  example_en: string
  example_ko: string
  difficulty: number
  topic: string
  wrongCount: number
  saveCount: number
  lastWrongAt: string
  lastSavedAt: string
}

export default function WordDetailPage() {
  const params = useParams()
  const router = useRouter()
  const wordId = params.wordId as string

  const [word, setWord] = useState<WordDetail | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetch(`/api/vocabulary/${wordId}`)
      .then((res) => res.json())
      .then((data) => {
        if (data.error) {
          setWord(null)
        } else {
          setWord(data)
        }
        setLoading(false)
      })
  }, [wordId])

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <p className="text-gray-500">로딩 중...</p>
      </div>
    )
  }

  if (!word) {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center px-4">
        <p className="text-gray-500 mb-4">단어를 찾을 수 없습니다.</p>
        <button
          onClick={() => router.push('/vocabulary')}
          className="text-blue-600 hover:underline"
        >
          단어장으로 돌아가기
        </button>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-white">
      <div className="max-w-lg mx-auto px-4 py-6">
        {/* 뒤로가기 */}
        <button
          onClick={() => router.push('/vocabulary')}
          className="text-sm text-gray-500 hover:text-gray-700 mb-6 flex items-center gap-1"
        >
          &larr; 단어장으로
        </button>

        {/* 단어 */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">{word.word}</h1>
          <div className="flex gap-2">
            <span className="text-xs bg-blue-100 text-blue-700 px-2 py-0.5 rounded">
              {DIFFICULTY_LABELS[word.difficulty] ?? `Lv.${word.difficulty}`}
            </span>
            <span className="text-xs bg-gray-100 text-gray-600 px-2 py-0.5 rounded">
              {word.topic}
            </span>
          </div>
        </div>

        {/* 뜻 */}
        <div className="mb-6">
          <h2 className="text-sm font-medium text-gray-500 mb-2">뜻</h2>
          <p className="text-lg text-gray-900 font-medium">{word.meaning_ko}</p>
        </div>

        {/* 예문 */}
        <div className="mb-6 bg-gray-50 rounded-xl p-4">
          <h2 className="text-sm font-medium text-gray-500 mb-2">예문</h2>
          <p className="text-gray-900 mb-2">{word.example_en}</p>
          <p className="text-gray-500 text-sm">{word.example_ko}</p>
        </div>

        {/* 학습 통계 */}
        <div className="grid grid-cols-2 gap-4">
          <div className="bg-red-50 rounded-xl p-4 text-center">
            <p className="text-2xl font-bold text-red-500">{word.wrongCount}</p>
            <p className="text-sm text-gray-500">틀린 횟수</p>
          </div>
          <div className="bg-blue-50 rounded-xl p-4 text-center">
            <p className="text-2xl font-bold text-blue-500">{word.saveCount}</p>
            <p className="text-sm text-gray-500">저장 횟수</p>
          </div>
        </div>
      </div>
    </div>
  )
}
