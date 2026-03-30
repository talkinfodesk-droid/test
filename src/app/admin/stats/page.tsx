'use client'

import { useEffect, useState } from 'react'

interface StatsData {
  avgAccuracy: number
  frequentlyWrongProblems: { problemId: number; sentence: string; word: string; wrongCount: number }[]
  frequentlyWrongWords: { wordId: number; word: string; meaningKo: string; wrongCount: number }[]
  recentLearningTrend: { date: string; count: number }[]
}

export default function AdminStatsPage() {
  const [data, setData] = useState<StatsData | null>(null)

  useEffect(() => {
    fetch('/api/admin/stats')
      .then((res) => res.json())
      .then(setData)
  }, [])

  if (!data) return <p className="text-gray-500">로딩 중...</p>

  const maxTrend = Math.max(...data.recentLearningTrend.map((d) => d.count), 1)

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 mb-6">통계</h1>

      {/* 평균 정답률 */}
      <div className="bg-white rounded-xl p-5 shadow-sm border mb-6">
        <p className="text-sm text-gray-500 mb-1">전체 평균 정답률</p>
        <p className="text-4xl font-bold text-blue-600">{data.avgAccuracy}%</p>
      </div>

      {/* 최근 7일 학습 추이 */}
      <div className="bg-white rounded-xl p-5 shadow-sm border mb-6">
        <h2 className="text-sm font-medium text-gray-500 mb-4">최근 7일 학습 추이</h2>
        <div className="flex items-end gap-2 h-32">
          {data.recentLearningTrend.map((d) => (
            <div key={d.date} className="flex-1 flex flex-col items-center">
              <span className="text-xs text-gray-500 mb-1">{d.count}</span>
              <div
                className="w-full bg-blue-500 rounded-t"
                style={{ height: `${(d.count / maxTrend) * 100}%`, minHeight: d.count > 0 ? '4px' : '0' }}
              />
              <span className="text-xs text-gray-400 mt-1">
                {d.date.slice(5)}
              </span>
            </div>
          ))}
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* 자주 틀린 문제 */}
        <div className="bg-white rounded-xl p-5 shadow-sm border">
          <h2 className="text-sm font-medium text-gray-500 mb-4">자주 틀린 문제 TOP 10</h2>
          {data.frequentlyWrongProblems.length === 0 ? (
            <p className="text-gray-400 text-sm">데이터 없음</p>
          ) : (
            <div className="space-y-2">
              {data.frequentlyWrongProblems.map((p, i) => (
                <div key={p.problemId} className="flex justify-between items-center text-sm">
                  <div className="flex items-center gap-2">
                    <span className="text-gray-400 w-5">{i + 1}.</span>
                    <span className="font-medium">{p.word}</span>
                    <span className="text-gray-500 truncate max-w-[200px]">{p.sentence}</span>
                  </div>
                  <span className="text-red-500 font-medium">{p.wrongCount}회</span>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* 자주 틀린 단어 */}
        <div className="bg-white rounded-xl p-5 shadow-sm border">
          <h2 className="text-sm font-medium text-gray-500 mb-4">자주 틀린 단어 TOP 10</h2>
          {data.frequentlyWrongWords.length === 0 ? (
            <p className="text-gray-400 text-sm">데이터 없음</p>
          ) : (
            <div className="space-y-2">
              {data.frequentlyWrongWords.map((w, i) => (
                <div key={w.wordId} className="flex justify-between items-center text-sm">
                  <div className="flex items-center gap-2">
                    <span className="text-gray-400 w-5">{i + 1}.</span>
                    <span className="font-medium">{w.word}</span>
                    <span className="text-gray-500">{w.meaningKo}</span>
                  </div>
                  <span className="text-red-500 font-medium">{w.wrongCount}회</span>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
