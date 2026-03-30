'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'

interface ProblemFormProps {
  problemId?: number
}

export default function ProblemForm({ problemId }: ProblemFormProps) {
  const router = useRouter()
  const isEdit = !!problemId

  const [wordId, setWordId] = useState('')
  const [sentence, setSentence] = useState('')
  const [choices, setChoices] = useState(['', '', '', ''])
  const [correctChoice, setCorrectChoice] = useState(0)
  const [difficulty, setDifficulty] = useState(1)
  const [topic, setTopic] = useState('')
  const [isActive, setIsActive] = useState(true)
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    if (isEdit) {
      fetch(`/api/admin/problems/${problemId}`)
        .then((res) => res.json())
        .then((data) => {
          setWordId(String(data.word_id))
          setSentence(data.sentence)
          setChoices(data.choices)
          setCorrectChoice(data.correct_choice)
          setDifficulty(data.difficulty)
          setTopic(data.topic)
          setIsActive(data.is_active)
        })
    }
  }, [isEdit, problemId])

  function updateChoice(index: number, value: string) {
    const next = [...choices]
    next[index] = value
    setChoices(next)
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError('')
    setLoading(true)

    const body = {
      word_id: Number(wordId),
      sentence,
      choices,
      correct_choice: correctChoice,
      difficulty,
      topic,
      is_active: isActive,
    }

    const url = isEdit ? `/api/admin/problems/${problemId}` : '/api/admin/problems'
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

    router.push('/admin/problems')
  }

  return (
    <form onSubmit={handleSubmit} className="max-w-2xl space-y-4">
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">단어 ID</label>
        <input
          type="number"
          value={wordId}
          onChange={(e) => setWordId(e.target.value)}
          required
          className="w-full px-3 py-2 border rounded-lg text-sm"
        />
      </div>
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">문제 문장</label>
        <input
          type="text"
          value={sentence}
          onChange={(e) => setSentence(e.target.value)}
          required
          className="w-full px-3 py-2 border rounded-lg text-sm"
        />
      </div>
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">선택지 (4개)</label>
        {choices.map((c, i) => (
          <div key={i} className="flex items-center gap-2 mb-2">
            <input
              type="radio"
              name="correct"
              checked={correctChoice === i}
              onChange={() => setCorrectChoice(i)}
            />
            <input
              type="text"
              value={c}
              onChange={(e) => updateChoice(i, e.target.value)}
              required
              placeholder={`선택지 ${i + 1}`}
              className="flex-1 px-3 py-2 border rounded-lg text-sm"
            />
          </div>
        ))}
        <p className="text-xs text-gray-500">정답을 라디오 버튼으로 선택하세요</p>
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
          <input
            type="checkbox"
            checked={isActive}
            onChange={(e) => setIsActive(e.target.checked)}
          />
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
          onClick={() => router.push('/admin/problems')}
          className="px-6 py-2 bg-gray-200 rounded-lg text-sm hover:bg-gray-300"
        >
          취소
        </button>
      </div>
    </form>
  )
}
