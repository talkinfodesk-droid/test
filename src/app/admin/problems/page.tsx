'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import { DIFFICULTY_LABELS } from '@/lib/learning/difficulty'

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export default function AdminProblemsPage() {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const [problems, setProblems] = useState<any[]>([])
  const [search, setSearch] = useState('')
  const [difficulty, setDifficulty] = useState('')
  const [loading, setLoading] = useState(true)

  function fetchProblems() {
    setLoading(true)
    const params = new URLSearchParams()
    if (search) params.set('search', search)
    if (difficulty) params.set('difficulty', difficulty)

    fetch(`/api/admin/problems?${params}`)
      .then((res) => res.json())
      .then((data) => {
        setProblems(data.problems ?? [])
        setLoading(false)
      })
  }

  useEffect(() => { fetchProblems() }, [])

  async function toggleActive(id: number, currentActive: boolean) {
    await fetch(`/api/admin/problems/${id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ is_active: !currentActive }),
    })
    fetchProblems()
  }

  return (
    <div>
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold text-gray-900">문제 관리</h1>
        <Link
          href="/admin/problems/new"
          className="px-4 py-2 bg-blue-600 text-white rounded-lg text-sm hover:bg-blue-700"
        >
          문제 등록
        </Link>
      </div>

      {/* 검색 + 필터 */}
      <div className="flex gap-3 mb-4">
        <input
          type="text"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="문제 검색..."
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
        <button
          onClick={fetchProblems}
          className="px-4 py-2 bg-gray-200 rounded-lg text-sm hover:bg-gray-300"
        >
          검색
        </button>
      </div>

      {/* 문제 목록 테이블 */}
      {loading ? (
        <p className="text-gray-500">로딩 중...</p>
      ) : (
        <div className="bg-white rounded-xl border overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b">
              <tr>
                <th className="text-left px-4 py-3 font-medium text-gray-500">ID</th>
                <th className="text-left px-4 py-3 font-medium text-gray-500">단어</th>
                <th className="text-left px-4 py-3 font-medium text-gray-500">문제</th>
                <th className="text-left px-4 py-3 font-medium text-gray-500">난이도</th>
                <th className="text-left px-4 py-3 font-medium text-gray-500">주제</th>
                <th className="text-left px-4 py-3 font-medium text-gray-500">상태</th>
                <th className="text-left px-4 py-3 font-medium text-gray-500">관리</th>
              </tr>
            </thead>
            <tbody className="divide-y">
              {problems.map((p) => (
                <tr key={p.id} className="hover:bg-gray-50">
                  <td className="px-4 py-3 text-gray-500">{p.id}</td>
                  <td className="px-4 py-3 font-medium">{p.words?.word}</td>
                  <td className="px-4 py-3 text-gray-700 max-w-xs truncate">{p.sentence}</td>
                  <td className="px-4 py-3">{DIFFICULTY_LABELS[p.difficulty]}</td>
                  <td className="px-4 py-3 text-gray-500">{p.topic}</td>
                  <td className="px-4 py-3">
                    <span className={`px-2 py-0.5 rounded text-xs ${
                      p.is_active ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'
                    }`}>
                      {p.is_active ? '활성' : '비활성'}
                    </span>
                  </td>
                  <td className="px-4 py-3 space-x-2">
                    <Link
                      href={`/admin/problems/${p.id}/edit`}
                      className="text-blue-600 hover:underline text-xs"
                    >
                      수정
                    </Link>
                    <button
                      onClick={() => toggleActive(p.id, p.is_active)}
                      className="text-gray-500 hover:underline text-xs"
                    >
                      {p.is_active ? '비활성화' : '활성화'}
                    </button>
                  </td>
                </tr>
              ))}
              {problems.length === 0 && (
                <tr>
                  <td colSpan={7} className="px-4 py-8 text-center text-gray-400">
                    등록된 문제가 없습니다.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
