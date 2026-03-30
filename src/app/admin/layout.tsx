'use client'

import { usePathname } from 'next/navigation'
import AdminSidebar from '@/components/admin/AdminSidebar'

export default function AdminLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const pathname = usePathname()
  const isLoginPage = pathname === '/admin/login'

  if (isLoginPage) {
    return <>{children}</>
  }

  return (
    <div className="flex">
      <AdminSidebar />
      <main className="ml-56 flex-1 min-h-screen bg-gray-50 p-6">
        {children}
      </main>
    </div>
  )
}
