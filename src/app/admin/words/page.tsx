'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import { DIFFICULTY_LABELS } from '@/lib/learning/difficulty'

export default function AdminWordsPage() {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const [words, setWords] = useState<any[]>([])
  const [search, setSearch] = useState('')
  const [difficulty, setDifficulty] = useState('')
  const [loading, setLoading] = useState(true)

  function fetchWords() {
    setLoading(true)
    const params = new URLSearchParams()
    if (search) params.set('search', search)
    if (difficulty) params.set('difficulty', difficulty)

    fetch(`/api/admin/words?${params}`)
      .then((res) => res.json())
      .then((data) => {
        setWords(data.words ?? [])
        setLoading(false)
      })
  }

  useEffect(() => { fetchWords() }, [])

  return (
    <div>
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold text-gray-900">단어 관리</h1>
        <Link
          href="/admin/words/new"
          className="px-4 py-2 bg-blue-600 text-white rounded-lg text-sm hover:bg-blue-700"
        >
          단어 등록
        </Link>
      </div>

      <div className="flex gap-3 mb-4">
        <input
          type="text"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="단어 검색..."
          className="flex-1 px-3 py-2 border rounded-lg text-sm"
        />
        <select
          value={difficulty}
          onChange={(e) => setDifficulty(e.target.value)}
          className="px-3 py-2 border rounded-lg text-sm"
        >
          <option value="">전체 난이도</option>
          <option value="1">초급</option>
          <option value="2">중급</option>
          <option value="3">중상급</option>
          <option value="4">상급</option>
        </select>
        <button onClick={fetchWords} className="px-4 py-2 bg-gray-200 rounded-lg text-sm hover:bg-gray-300">
          검색
        </button>
      </div>

      {loading ? (
        <p className="text-gray-500">로딩 중...</p>
      ) : (
        <div className="bg-white rounded-xl border overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b">
              <tr>
                <th className="text-left px-4 py-3 font-medium text-gray-500">ID</th>
                <th className="text-left px-4 py-3 font-medium text-gray-500">단어</th>
                <th className="text-left px-4 py-3 font-medium text-gray-500">뜻</th>
                <th className="text-left px-4 py-3 font-medium text-gray-500">난이도</th>
                <th className="text-left px-4 py-3 font-medium text-gray-500">주제</th>
                <th className="text-left px-4 py-3 font-medium text-gray-500">상태</th>
                <th className="text-left px-4 py-3 font-medium text-gray-500">관리</th>
              </tr>
            </thead>
            <tbody className="divide-y">
              {words.map((w) => (
                <tr key={w.id} className="hover:bg-gray-50">
                  <td className="px-4 py-3 text-gray-500">{w.id}</td>
                  <td className="px-4 py-3 font-medium">{w.word}</td>
                  <td className="px-4 py-3 text-gray-700">{w.meaning_ko}</td>
                  <td className="px-4 py-3">{DIFFICULTY_LABELS[w.difficulty]}</td>
                  <td className="px-4 py-3 text-gray-500">{w.topic}</td>
                  <td className="px-4 py-3">
                    <span className={`px-2 py-0.5 rounded text-xs ${
                      w.is_active ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'
                    }`}>
                      {w.is_active ? '활성' : '비활성'}
                    </span>
                  </td>
                  <td className="px-4 py-3">
                    <Link href={`/admin/words/${w.id}/edit`} className="text-blue-600 hover:underline text-xs">
                      수정
                    </Link>
                  </td>
                </tr>
              ))}
              {words.length === 0 && (
                <tr>
                  <td colSpan={7} className="px-4 py-8 text-center text-gray-400">등록된 단어가 없습니다.</td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
