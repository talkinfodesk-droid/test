import Link from 'next/link'

export default function ResultPage() {
  return (
    <div className="min-h-screen flex flex-col items-center justify-center px-4">
      <h1 className="text-2xl font-bold mb-4">학습 결과</h1>
      <p className="text-gray-500 mb-8">묶음 C 티켓에서 구현 예정</p>
      <div className="flex gap-4">
        <Link
          href="/home"
          className="px-6 py-3 bg-blue-600 text-white rounded-lg"
        >
          학습 홈으로
        </Link>
        <Link
          href="/vocabulary"
          className="px-6 py-3 bg-white border border-blue-600 text-blue-600 rounded-lg"
        >
          내 단어장
        </Link>
      </div>
    </div>
  )
}
