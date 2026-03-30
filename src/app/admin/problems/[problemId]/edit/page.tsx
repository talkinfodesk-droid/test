'use client'

import { useParams } from 'next/navigation'
import ProblemForm from '@/components/admin/ProblemForm'

export default function EditProblemPage() {
  const params = useParams()
  const problemId = Number(params.problemId)

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 mb-6">문제 수정</h1>
      <ProblemForm problemId={problemId} />
    </div>
  )
}
