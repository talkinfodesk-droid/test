import Link from 'next/link'

export default function MainPage() {
  return (
    <div className="min-h-screen flex flex-col items-center justify-center px-4">
      <h1 className="text-3xl font-bold text-gray-900 mb-4">
        영어 단어 학습
      </h1>
      <p className="text-gray-600 text-center mb-8 max-w-md">
        매일 10문제씩 풀며 영어 단어를 익히세요.
        틀린 단어는 자동으로 단어장에 저장됩니다.
      </p>
      <div className="flex gap-4">
        <Link
          href="/login"
          className="px-6 py-3 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 transition"
        >
          로그인
        </Link>
        <Link
          href="/signup"
          className="px-6 py-3 bg-white text-blue-600 border border-blue-600 rounded-lg font-medium hover:bg-blue-50 transition"
        >
          회원가입
        </Link>
      </div>
    </div>
  )
}
