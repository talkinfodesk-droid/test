'use client'

import { useEffect, useState } from 'react'

interface DashboardData {
  totalUsers: number
  todayLearners: number
  totalProblems: number
  totalWords: number
  avgAccuracy: number
}

export default function AdminDashboard() {
  const [data, setData] = useState<DashboardData | null>(null)

  useEffect(() => {
    fetch('/api/admin/dashboard')
      .then((res) => res.json())
      .then(setData)
  }, [])

  if (!data) {
    return <p className="text-gray-500">로딩 중...</p>
  }

  const cards = [
    { label: '총 사용자 수', value: data.totalUsers, color: 'text-blue-600' },
    { label: '오늘 학습 사용자', value: data.todayLearners, color: 'text-green-600' },
    { label: '등록 문제 수', value: data.totalProblems, color: 'text-purple-600' },
    { label: '등록 단어 수', value: data.totalWords, color: 'text-orange-500' },
    { label: '평균 정답률', value: `${data.avgAccuracy}%`, color: 'text-red-500' },
  ]

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 mb-6">대시보드</h1>
      <div className="grid grid-cols-2 lg:grid-cols-3 gap-4">
        {cards.map((card) => (
          <div key={card.label} className="bg-white rounded-xl p-5 shadow-sm border">
            <p className="text-sm text-gray-500 mb-1">{card.label}</p>
            <p className={`text-3xl font-bold ${card.color}`}>{card.value}</p>
          </div>
        ))}
      </div>
    </div>
  )
}
