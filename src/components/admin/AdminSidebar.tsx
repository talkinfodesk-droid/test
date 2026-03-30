'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'

const menuItems = [
  { href: '/admin/dashboard', label: '대시보드' },
  { href: '/admin/problems', label: '문제 관리' },
  { href: '/admin/words', label: '단어 관리' },
  { href: '/admin/users', label: '사용자 관리' },
  { href: '/admin/stats', label: '통계' },
]

export default function AdminSidebar() {
  const pathname = usePathname()

  return (
    <aside className="w-56 bg-gray-900 text-white min-h-screen fixed left-0 top-0">
      <div className="p-4 border-b border-gray-700">
        <h1 className="text-lg font-bold">관리자</h1>
      </div>
      <nav className="py-2">
        {menuItems.map((item) => {
          const isActive = pathname.startsWith(item.href)
          return (
            <Link
              key={item.href}
              href={item.href}
              className={`block px-4 py-3 text-sm transition ${
                isActive
                  ? 'bg-gray-700 text-white font-medium'
                  : 'text-gray-300 hover:bg-gray-800 hover:text-white'
              }`}
            >
              {item.label}
            </Link>
          )
        })}
      </nav>
      <div className="absolute bottom-0 w-full p-4 border-t border-gray-700">
        <Link href="/" className="text-sm text-gray-400 hover:text-white transition">
          사용자 사이트로
        </Link>
      </div>
    </aside>
  )
}
