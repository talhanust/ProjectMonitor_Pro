import { useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { useAuthStore } from '../store/authStore'

export function useAuth(requireAuth: boolean = false) {
  const router = useRouter()
  const { user, isAuthenticated, isLoading, checkAuth } = useAuthStore()
  
  useEffect(() => {
    checkAuth()
  }, [])
  
  useEffect(() => {
    if (!isLoading && requireAuth && !isAuthenticated) {
      router.push('/login')
    }
  }, [isLoading, requireAuth, isAuthenticated, router])
  
  return {
    user,
    isAuthenticated,
    isLoading,
  }
}

export function useRequireAuth() {
  return useAuth(true)
}

export function useOptionalAuth() {
  return useAuth(false)
}
