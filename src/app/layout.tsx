import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: '영어 단어 학습',
  description: '매일 영어 단어를 학습하고 복습하세요',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="ko">
      <body className="bg-gray-50 min-h-screen">
        {children}
      </body>
    </html>
  )
}
