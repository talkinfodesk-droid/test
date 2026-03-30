'use client'

import { useParams } from 'next/navigation'
import WordForm from '@/components/admin/WordForm'

export default function EditWordPage() {
  const params = useParams()
  const wordId = Number(params.wordId)

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 mb-6">단어 수정</h1>
      <WordForm wordId={wordId} />
    </div>
  )
}
