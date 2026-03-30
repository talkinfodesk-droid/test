'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'

interface WordFormProps {
  wordId?: number
}

export default function WordForm({ wordId }: WordFormProps) {
  const router = useRouter()
  const isEdit = !!wordId

  const [word, setWord] = useState('')
  const [meaningKo, setMeaningKo] = useState('')
  const [exampleEn, setExampleEn] = useState('')
  const [exampleKo, setExampleKo] = useState('')
  const [difficulty, setDifficulty] = useState(1)
  const [topic, setTopic] = useState('')
  const [isActive, setIsActive] = useState(true)
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    if (isEdit) {
      fetch(`/api/admin/words/${wordId}`)
        .then((res) => res.json())
        .then((data) => {
          setWord(data.word)
          setMeaningKo(data.meaning_ko)
          setExampleEn(data.example_en)
          setExampleKo(data.example_ko)
          setDifficulty(data.difficulty)
          setTopic(data.topic)
          setIsActive(data.is_active)
        })
    }
  }, [isEdit, wordId])

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError('')
    setLoading(true)

    const body = {
      word,
      meaning_ko: meaningKo,
      example_en: exampleEn,
      example_ko: exampleKo,
      difficulty,
      topic,
      is_active: isActive,
    }

    const url = isEdit ? `/api/admin/words/${wordId}` : '/api/admin/words'
    const method = isEdit ? 'PUT' : 'POST'

    const res = await fetch(url, {
      method,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    })

    if (!res.ok) {
      const data = await res.json()
      setError(data.error || '저장에 실패했습니다.')
      setLoading(false)
      return
    }

    router.push('/admin/words')
  }

  return (
    <form onSubmit={handleSubmit} className="max-w-2xl space-y-4">
      <div className="grid grid-cols-2 gap-4">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">영어 단어</label>
          <input
            type="text"
            value={word}
            onChange={(e) => setWord(e.target.value)}
            required
            className="w-full px-3 py-2 border rounded-lg text-sm"
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">뜻 (한국어)</label>
          <input
            type="text"
            value={meaningKo}
            onChange={(e) => setMeaningKo(e.target.value)}
            required
            className="w-full px-3 py-2 border rounded-lg text-sm"
          />
        </div>
      </div>
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">예문 (영어)</label>
        <input
          type="text"
          value={exampleEn}
          onChange={(e) => setExampleEn(e.target.value)}
          required
          className="w-full px-3 py-2 border rounded-lg text-sm"
        />
      </div>
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">예문 뜻 (한국어)</label>
        <input
          type="text"
          value={exampleKo}
          onChange={(e) => setExampleKo(e.target.value)}
          required
          className="w-full px-3 py-2 border rounded-lg text-sm"
        />
      </div>
      <div className="grid grid-cols-2 gap-4">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">난이도</label>
          <select
            value={difficulty}
            onChange={(e) => setDifficulty(Number(e.target.value))}
            className="w-full px-3 py-2 border rounded-lg text-sm"
          >
            <option value={1}>초급</option>
            <option value={2}>중급</option>
            <option value={3}>중상급</option>
            <option value={4}>상급</option>
          </select>
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">주제</label>
          <input
            type="text"
            value={topic}
            onChange={(e) => setTopic(e.target.value)}
            required
            className="w-full px-3 py-2 border rounded-lg text-sm"
          />
        </div>
      </div>
      {isEdit && (
        <div className="flex items-center gap-2">
          <input type="checkbox" checked={isActive} onChange={(e) => setIsActive(e.target.checked)} />
          <label className="text-sm text-gray-700">활성 상태</label>
        </div>
      )}
      {error && <p className="text-red-500 text-sm">{error}</p>}
      <div className="flex gap-3">
        <button
          type="submit"
          disabled={loading}
          className="px-6 py-2 bg-blue-600 text-white rounded-lg text-sm hover:bg-blue-700 disabled:opacity-50"
        >
          {loading ? '저장 중...' : isEdit ? '수정' : '등록'}
        </button>
        <button
          type="button"
          onClick={() => router.push('/admin/words')}
          className="px-6 py-2 bg-gray-200 rounded-lg text-sm hover:bg-gray-300"
        >
          취소
        </button>
      </div>
    </form>
  )
}
