'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import BottomNav from '@/components/BottomNav'
import { DIFFICULTY_LABELS } from '@/lib/learning/difficulty'

interface WordItem {
  userWordId: number
  wordId: number
  wrongCount: number
  saveCount: number
  lastSavedAt: string
  word: string
  meaningKo: string
  exampleEn: string
  exampleKo: string
  difficulty: number
  topic: string
}

const SORT_OPTIONS = [
  { value: 'recent', label: '최근 저장순' },
  { value: 'wrong_count', label: '많이 틀린 단어' },
  { value: 'difficulty', label: '난이도별' },
  { value: 'topic', label: '주제별' },
]

export default function VocabularyPage() {
  const [words, setWords] = useState<WordItem[]>([])
  const [loading, setLoading] = useState(true)
  const [sort, setSort] = useState('recent')
  const router = useRouter()

  useEffect(() => {
    setLoading(true)
    fetch(`/api/vocabulary?sort=${sort}`)
      .then((res) => res.json())
      .then((data) => {
        setWords(data.words ?? [])
        setLoading(false)
      })
  }, [sort])

  return (
    <div className="min-h-screen pb-20 bg-gray-50">
      <div className="max-w-lg mx-auto px-4 py-6">
        <h1 className="text-xl font-bold text-gray-900 mb-4">내 단어장</h1>

        {/* 정렬 옵션 */}
        <div className="flex gap-2 mb-6 overflow-x-auto">
          {SORT_OPTIONS.map((opt) => (
            <button
              key={opt.value}
              onClick={() => setSort(opt.value)}
              className={`px-3 py-1.5 rounded-full text-sm whitespace-nowrap transition ${
                sort === opt.value
                  ? 'bg-blue-600 text-white'
                  : 'bg-white text-gray-600 border border-gray-300'
              }`}
            >
              {opt.label}
            </button>
          ))}
        </div>

        {loading ? (
          <p className="text-gray-500 text-center py-8">로딩 중...</p>
        ) : words.length === 0 ? (
          <div className="text-center py-12">
            <p className="text-gray-400 text-lg mb-2">저장된 단어가 없습니다</p>
            <p className="text-gray-400 text-sm">학습 중 틀린 단어가 자동으로 저장됩니다</p>
          </div>
        ) : (
          <div className="space-y-3">
            {words.map((w) => (
              <button
                key={w.userWordId}
                onClick={() => router.push(`/vocabulary/${w.wordId}`)}
                className="w-full text-left bg-white rounded-xl p-4 shadow-sm border hover:border-blue-300 transition"
              >
                <div className="flex justify-between items-start mb-2">
                  <h3 className="font-bold text-gray-900 text-lg">{w.word}</h3>
                  <span className="text-xs text-gray-400 bg-gray-100 px-2 py-0.5 rounded">
                    {DIFFICULTY_LABELS[w.difficulty] ?? `Lv.${w.difficulty}`}
                  </span>
                </div>
                <p className="text-gray-600 text-sm mb-2">{w.meaningKo}</p>
                <div className="flex justify-between items-center text-xs text-gray-400">
                  <span>{w.topic}</span>
                  <span>틀린 횟수: {w.wrongCount}</span>
                </div>
              </button>
            ))}
          </div>
        )}
      </div>

      <BottomNav />
    </div>
  )
}
