'use client'

import { useEffect, useState } from 'react'
import { DIFFICULTY_LABELS } from '@/lib/learning/difficulty'

interface UserInfo {
  id: string
  nickname: string
  isAdmin: boolean
  createdAt: string
  monthNumber: number
  difficulty: number
  lastLearningAt: string | null
}

export default function AdminUsersPage() {
  const [users, setUsers] = useState<UserInfo[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetch('/api/admin/users')
      .then((res) => res.json())
      .then((data) => {
        setUsers(data.users ?? [])
        setLoading(false)
      })
  }, [])

  function formatDate(d: string | null) {
    if (!d) return '-'
    return new Date(d).toLocaleDateString('ko-KR')
  }

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 mb-6">사용자 관리</h1>

      {loading ? (
        <p className="text-gray-500">로딩 중...</p>
      ) : (
        <div className="bg-white rounded-xl border overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b">
              <tr>
                <th className="text-left px-4 py-3 font-medium text-gray-500">닉네임</th>
                <th className="text-left px-4 py-3 font-medium text-gray-500">가입일</th>
                <th className="text-left px-4 py-3 font-medium text-gray-500">월차</th>
                <th className="text-left px-4 py-3 font-medium text-gray-500">난이도</th>
                <th className="text-left px-4 py-3 font-medium text-gray-500">마지막 학습일</th>
                <th className="text-left px-4 py-3 font-medium text-gray-500">역할</th>
              </tr>
            </thead>
            <tbody className="divide-y">
              {users.map((u) => (
                <tr key={u.id} className="hover:bg-gray-50">
                  <td className="px-4 py-3 font-medium">{u.nickname}</td>
                  <td className="px-4 py-3 text-gray-500">{formatDate(u.createdAt)}</td>
                  <td className="px-4 py-3">{u.monthNumber}개월차</td>
                  <td className="px-4 py-3">{DIFFICULTY_LABELS[u.difficulty]}</td>
                  <td className="px-4 py-3 text-gray-500">{formatDate(u.lastLearningAt)}</td>
                  <td className="px-4 py-3">
                    <span className={`px-2 py-0.5 rounded text-xs ${
                      u.isAdmin ? 'bg-purple-100 text-purple-700' : 'bg-gray-100 text-gray-500'
                    }`}>
                      {u.isAdmin ? '관리자' : '사용자'}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
