import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import { authService, User } from '../services/authService'

interface AuthState {
  user: User | null
  isAuthenticated: boolean
  isLoading: boolean
  error: string | null
  
  // Actions
  login: (email: string, password: string) => Promise<void>
  register: (email: string, password: string, name: string) => Promise<void>
  logout: () => Promise<void>
  checkAuth: () => Promise<void>
  clearError: () => void
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set, get) => ({
      user: null,
      isAuthenticated: false,
      isLoading: false,
      error: null,
      
      login: async (email: string, password: string) => {
        set({ isLoading: true, error: null })
        try {
          const response = await authService.login(email, password)
          set({
            user: response.user,
            isAuthenticated: true,
            isLoading: false,
            error: null,
          })
        } catch (error: any) {
          set({
            user: null,
            isAuthenticated: false,
            isLoading: false,
            error: error.response?.data?.message || 'Login failed',
          })
          throw error
        }
      },
      
      register: async (email: string, password: string, name: string) => {
        set({ isLoading: true, error: null })
        try {
          const response = await authService.register(email, password, name)
          set({
            user: response.user,
            isAuthenticated: true,
            isLoading: false,
            error: null,
          })
        } catch (error: any) {
          set({
            user: null,
            isAuthenticated: false,
            isLoading: false,
            error: error.response?.data?.message || 'Registration failed',
          })
          throw error
        }
      },
      
      logout: async () => {
        set({ isLoading: true })
        try {
          await authService.logout()
          set({
            user: null,
            isAuthenticated: false,
            isLoading: false,
            error: null,
          })
        } catch (error) {
          // Even if logout fails, clear local state
          set({
            user: null,
            isAuthenticated: false,
            isLoading: false,
            error: null,
          })
        }
      },
      
      checkAuth: async () => {
        set({ isLoading: true })
        try {
          const user = await authService.getCurrentUser()
          if (user) {
            set({
              user,
              isAuthenticated: true,
              isLoading: false,
              error: null,
            })
          } else {
            set({
              user: null,
              isAuthenticated: false,
              isLoading: false,
              error: null,
            })
          }
        } catch (error) {
          set({
            user: null,
            isAuthenticated: false,
            isLoading: false,
            error: null,
          })
        }
      },
      
      clearError: () => {
        set({ error: null })
      },
    }),
    {
      name: 'auth-storage',
      partialize: (state) => ({
        user: state.user,
        isAuthenticated: state.isAuthenticated,
      }),
    }
  )
)
