import { createClient } from '@supabase/supabase-js'
import axios from 'axios'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!

export const supabase = createClient(supabaseUrl, supabaseAnonKey)

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080'

export interface User {
  id: string
  email: string
  name: string
  role: string
  avatar?: string
}

export interface AuthResponse {
  user: User
  accessToken: string
  refreshToken: string
  supabaseSession?: any
}

class AuthService {
  private accessToken: string | null = null
  
  // Register user
  async register(email: string, password: string, name: string): Promise<AuthResponse> {
    const response = await axios.post(`${API_URL}/auth/register`, {
      email,
      password,
      name,
    })
    
    this.accessToken = response.data.accessToken
    localStorage.setItem('accessToken', response.data.accessToken)
    localStorage.setItem('refreshToken', response.data.refreshToken)
    
    return response.data
  }
  
  // Login user
  async login(email: string, password: string): Promise<AuthResponse> {
    const response = await axios.post(`${API_URL}/auth/login`, {
      email,
      password,
    })
    
    this.accessToken = response.data.accessToken
    localStorage.setItem('accessToken', response.data.accessToken)
    localStorage.setItem('refreshToken', response.data.refreshToken)
    
    return response.data
  }
  
  // Logout user
  async logout(): Promise<void> {
    try {
      await axios.post(
        `${API_URL}/auth/logout`,
        {},
        {
          headers: {
            Authorization: `Bearer ${this.accessToken}`,
          },
        }
      )
    } catch (error) {
      // Continue with logout even if API call fails
    }
    
    this.accessToken = null
    localStorage.removeItem('accessToken')
    localStorage.removeItem('refreshToken')
    
    await supabase.auth.signOut()
  }
  
  // Get current user
  async getCurrentUser(): Promise<User | null> {
    const token = localStorage.getItem('accessToken')
    if (!token) {
      return null
    }
    
    try {
      const response = await axios.get(`${API_URL}/auth/me`, {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      })
      
      return response.data
    } catch (error) {
      // Token might be expired, try to refresh
      const refreshToken = localStorage.getItem('refreshToken')
      if (refreshToken) {
        try {
          const refreshResponse = await axios.post(`${API_URL}/auth/refresh`, {
            refreshToken,
          })
          
          this.accessToken = refreshResponse.data.accessToken
          localStorage.setItem('accessToken', refreshResponse.data.accessToken)
          
          // Retry getting user
          const userResponse = await axios.get(`${API_URL}/auth/me`, {
            headers: {
              Authorization: `Bearer ${refreshResponse.data.accessToken}`,
            },
          })
          
          return userResponse.data
        } catch (refreshError) {
          // Refresh failed, user needs to login again
          this.logout()
          return null
        }
      }
      
      return null
    }
  }
  
  // Get access token
  getAccessToken(): string | null {
    return this.accessToken || localStorage.getItem('accessToken')
  }
  
  // Setup axios interceptor for auth
  setupAxiosInterceptor() {
    axios.interceptors.request.use(
      (config) => {
        const token = this.getAccessToken()
        if (token) {
          config.headers.Authorization = `Bearer ${token}`
        }
        return config
      },
      (error) => {
        return Promise.reject(error)
      }
    )
  }
}

export const authService = new AuthService()
