#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}    Setting Up Supabase Authentication         ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "package.json" ] || [ ! -d "backend" ]; then
    echo -e "${RED}Error: Not in project root directory!${NC}"
    exit 1
fi

# PART 1: Install Supabase dependencies
echo -e "${GREEN}Installing Supabase dependencies...${NC}"

# Frontend dependencies
cd frontend
npm install @supabase/supabase-js @supabase/auth-helpers-nextjs @supabase/auth-helpers-react
cd ..

# Backend dependencies
cd backend/services/api-gateway
npm install @supabase/supabase-js jsonwebtoken
npm install -D @types/jsonwebtoken
cd ../../..

cd backend/services/shared
npm install @supabase/supabase-js jsonwebtoken
npm install -D @types/jsonwebtoken
cd ../../..

# PART 2: Create auth directory structure
echo -e "${GREEN}Creating auth directory structure...${NC}"
mkdir -p frontend/src/features/auth/services
mkdir -p frontend/src/features/auth/store
mkdir -p frontend/src/features/auth/hooks
mkdir -p frontend/src/features/auth/components
mkdir -p frontend/app/\(auth\)/login
mkdir -p frontend/app/\(auth\)/register
mkdir -p frontend/app/\(auth\)/forgot-password
mkdir -p backend/services/api-gateway/src/controllers
mkdir -p backend/services/shared/auth

# PART 3: Create Supabase client for backend
echo -e "${GREEN}Creating Supabase client for backend...${NC}"
cat > backend/services/shared/auth/supabase.ts << 'SUPABASE'
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || process.env.SUPABASE_URL
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY

if (!supabaseUrl || !supabaseServiceKey) {
  throw new Error('Missing Supabase environment variables')
}

// Admin client with service role key for backend operations
export const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false,
  },
})

// Verify Supabase JWT token
export async function verifySupabaseToken(token: string) {
  try {
    const { data: { user }, error } = await supabaseAdmin.auth.getUser(token)
    
    if (error || !user) {
      return null
    }
    
    return user
  } catch (error) {
    console.error('Token verification error:', error)
    return null
  }
}

// Get user by ID
export async function getUserById(userId: string) {
  try {
    const { data: { user }, error } = await supabaseAdmin.auth.admin.getUserById(userId)
    
    if (error || !user) {
      return null
    }
    
    return user
  } catch (error) {
    console.error('Error fetching user:', error)
    return null
  }
}

// Create user (for admin operations)
export async function createUser(email: string, password: string, metadata?: any) {
  try {
    const { data, error } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: metadata,
    })
    
    if (error) {
      throw error
    }
    
    return data.user
  } catch (error) {
    console.error('Error creating user:', error)
    throw error
  }
}
SUPABASE

# PART 4: Create JWT utilities
echo -e "${GREEN}Creating JWT utilities...${NC}"
cat > backend/services/shared/auth/jwt.ts << 'JWT'
import jwt from 'jsonwebtoken'

const JWT_SECRET = process.env.JWT_SECRET || 'your-jwt-secret-change-in-production'

export interface JWTPayload {
  userId: string
  email: string
  role: string
  sessionId?: string
}

// Generate JWT token
export function generateToken(payload: JWTPayload, expiresIn: string = '7d'): string {
  return jwt.sign(payload, JWT_SECRET, { expiresIn })
}

// Verify JWT token
export function verifyToken(token: string): JWTPayload | null {
  try {
    const decoded = jwt.verify(token, JWT_SECRET) as JWTPayload
    return decoded
  } catch (error) {
    return null
  }
}

// Generate refresh token
export function generateRefreshToken(userId: string): string {
  return jwt.sign({ userId, type: 'refresh' }, JWT_SECRET, { expiresIn: '30d' })
}

// Verify refresh token
export function verifyRefreshToken(token: string): { userId: string } | null {
  try {
    const decoded = jwt.verify(token, JWT_SECRET) as any
    if (decoded.type !== 'refresh') {
      return null
    }
    return { userId: decoded.userId }
  } catch (error) {
    return null
  }
}
JWT

# PART 5: Create auth controller for backend
echo -e "${GREEN}Creating auth controller...${NC}"
cat > backend/services/api-gateway/src/controllers/authController.ts << 'AUTHCONTROLLER'
import { FastifyRequest, FastifyReply } from 'fastify'
import { z } from 'zod'
import bcrypt from 'bcryptjs'
import { supabaseAdmin, verifySupabaseToken } from '../../../shared/auth/supabase'
import { generateToken, generateRefreshToken, verifyRefreshToken } from '../../../shared/auth/jwt'
import { prisma } from '../../../shared/database'
import { UnauthorizedError, ConflictError, ValidationError } from '../middleware/errorHandler'

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6),
})

const registerSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8).regex(
    /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/,
    'Password must contain uppercase, lowercase, and number'
  ),
  name: z.string().min(2).max(100),
})

export class AuthController {
  // Register with Supabase
  async register(request: FastifyRequest, reply: FastifyReply) {
    const body = registerSchema.parse(request.body)
    
    try {
      // Check if user exists in database
      const existingUser = await prisma.user.findUnique({
        where: { email: body.email },
      })
      
      if (existingUser) {
        throw new ConflictError('User already exists')
      }
      
      // Create user in Supabase
      const { data: supabaseUser, error: supabaseError } = await supabaseAdmin.auth.signUp({
        email: body.email,
        password: body.password,
        options: {
          data: {
            name: body.name,
          },
        },
      })
      
      if (supabaseError) {
        throw new Error(supabaseError.message)
      }
      
      // Create user in database
      const hashedPassword = await bcrypt.hash(body.password, 10)
      const user = await prisma.user.create({
        data: {
          id: supabaseUser.user!.id,
          email: body.email,
          password: hashedPassword,
          name: body.name,
          emailVerified: new Date(),
        },
      })
      
      // Generate tokens
      const accessToken = generateToken({
        userId: user.id,
        email: user.email,
        role: user.role,
      })
      const refreshToken = generateRefreshToken(user.id)
      
      return {
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role,
        },
        accessToken,
        refreshToken,
        supabaseSession: supabaseUser.session,
      }
    } catch (error: any) {
      throw new ValidationError(error.message || 'Registration failed')
    }
  }
  
  // Login with Supabase
  async login(request: FastifyRequest, reply: FastifyReply) {
    const body = loginSchema.parse(request.body)
    
    try {
      // Sign in with Supabase
      const { data: supabaseData, error: supabaseError } = await supabaseAdmin.auth.signInWithPassword({
        email: body.email,
        password: body.password,
      })
      
      if (supabaseError) {
        throw new UnauthorizedError('Invalid credentials')
      }
      
      // Get user from database
      const user = await prisma.user.findUnique({
        where: { email: body.email },
      })
      
      if (!user) {
        // Create user in database if not exists (for users created directly in Supabase)
        const hashedPassword = await bcrypt.hash(body.password, 10)
        const newUser = await prisma.user.create({
          data: {
            id: supabaseData.user!.id,
            email: body.email,
            password: hashedPassword,
            name: supabaseData.user!.user_metadata?.name || body.email.split('@')[0],
          },
        })
        
        // Generate tokens
        const accessToken = generateToken({
          userId: newUser.id,
          email: newUser.email,
          role: newUser.role,
        })
        const refreshToken = generateRefreshToken(newUser.id)
        
        // Update last login
        await prisma.user.update({
          where: { id: newUser.id },
          data: { lastLogin: new Date() },
        })
        
        return {
          user: {
            id: newUser.id,
            email: newUser.email,
            name: newUser.name,
            role: newUser.role,
          },
          accessToken,
          refreshToken,
          supabaseSession: supabaseData.session,
        }
      }
      
      // Generate tokens
      const accessToken = generateToken({
        userId: user.id,
        email: user.email,
        role: user.role,
      })
      const refreshToken = generateRefreshToken(user.id)
      
      // Update last login
      await prisma.user.update({
        where: { id: user.id },
        data: { lastLogin: new Date() },
      })
      
      return {
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role,
        },
        accessToken,
        refreshToken,
        supabaseSession: supabaseData.session,
      }
    } catch (error: any) {
      throw new UnauthorizedError(error.message || 'Login failed')
    }
  }
  
  // Logout
  async logout(request: FastifyRequest, reply: FastifyReply) {
    const token = request.headers.authorization?.replace('Bearer ', '')
    
    if (!token) {
      return { message: 'Logged out' }
    }
    
    try {
      // Sign out from Supabase
      await supabaseAdmin.auth.signOut()
      return { message: 'Logged out successfully' }
    } catch (error) {
      return { message: 'Logged out' }
    }
  }
  
  // Refresh token
  async refreshToken(request: FastifyRequest, reply: FastifyReply) {
    const { refreshToken } = request.body as { refreshToken: string }
    
    if (!refreshToken) {
      throw new UnauthorizedError('Refresh token required')
    }
    
    const payload = verifyRefreshToken(refreshToken)
    if (!payload) {
      throw new UnauthorizedError('Invalid refresh token')
    }
    
    const user = await prisma.user.findUnique({
      where: { id: payload.userId },
    })
    
    if (!user) {
      throw new UnauthorizedError('User not found')
    }
    
    const accessToken = generateToken({
      userId: user.id,
      email: user.email,
      role: user.role,
    })
    
    return { accessToken }
  }
  
  // Get current user
  async getCurrentUser(request: FastifyRequest, reply: FastifyReply) {
    const userId = (request.user as any)?.id
    
    if (!userId) {
      throw new UnauthorizedError('Not authenticated')
    }
    
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        name: true,
        role: true,
        avatar: true,
        createdAt: true,
        emailVerified: true,
      },
    })
    
    if (!user) {
      throw new UnauthorizedError('User not found')
    }
    
    return user
  }
}

export const authController = new AuthController()
AUTHCONTROLLER

# PART 6: Create frontend auth service
echo -e "${GREEN}Creating frontend auth service...${NC}"
cat > frontend/src/features/auth/services/authService.ts << 'AUTHSERVICE'
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
AUTHSERVICE

# PART 7: Create Zustand auth store
echo -e "${GREEN}Creating Zustand auth store...${NC}"
cat > frontend/src/features/auth/store/authStore.ts << 'AUTHSTORE'
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
AUTHSTORE

# PART 8: Create auth hook
echo -e "${GREEN}Creating auth hook...${NC}"
cat > frontend/src/features/auth/hooks/useAuth.ts << 'USEAUTH'
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
USEAUTH

# PART 9: Create login page
echo -e "${GREEN}Creating login page...${NC}"
cat > frontend/app/\(auth\)/login/page.tsx << 'LOGINPAGE'
'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { useAuthStore } from '@/features/auth/store/authStore'

export default function LoginPage() {
  const router = useRouter()
  const { login, isLoading, error, clearError } = useAuthStore()
  
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    clearError()
    
    try {
      await login(email, password)
      router.push('/dashboard')
    } catch (error) {
      // Error is handled in the store
    }
  }
  
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="max-w-md w-full space-y-8">
        <div>
          <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900">
            Sign in to your account
          </h2>
          <p className="mt-2 text-center text-sm text-gray-600">
            Or{' '}
            <Link href="/register" className="font-medium text-blue-600 hover:text-blue-500">
              create a new account
            </Link>
          </p>
        </div>
        
        <form className="mt-8 space-y-6" onSubmit={handleSubmit}>
          {error && (
            <div className="rounded-md bg-red-50 p-4">
              <div className="text-sm text-red-800">{error}</div>
            </div>
          )}
          
          <div className="rounded-md shadow-sm -space-y-px">
            <div>
              <label htmlFor="email" className="sr-only">
                Email address
              </label>
              <input
                id="email"
                name="email"
                type="email"
                autoComplete="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-t-md focus:outline-none focus:ring-blue-500 focus:border-blue-500 focus:z-10 sm:text-sm"
                placeholder="Email address"
              />
            </div>
            <div>
              <label htmlFor="password" className="sr-only">
                Password
              </label>
              <input
                id="password"
                name="password"
                type="password"
                autoComplete="current-password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-b-md focus:outline-none focus:ring-blue-500 focus:border-blue-500 focus:z-10 sm:text-sm"
                placeholder="Password"
              />
            </div>
          </div>
          
          <div className="flex items-center justify-between">
            <div className="flex items-center">
              <input
                id="remember-me"
                name="remember-me"
                type="checkbox"
                className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
              />
              <label htmlFor="remember-me" className="ml-2 block text-sm text-gray-900">
                Remember me
              </label>
            </div>
            
            <div className="text-sm">
              <Link href="/forgot-password" className="font-medium text-blue-600 hover:text-blue-500">
                Forgot your password?
              </Link>
            </div>
          </div>
          
          <div>
            <button
              type="submit"
              disabled={isLoading}
              className="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50"
            >
              {isLoading ? 'Signing in...' : 'Sign in'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
LOGINPAGE

# PART 10: Create auth layout
echo -e "${GREEN}Creating auth layout...${NC}"
cat > frontend/app/\(auth\)/layout.tsx << 'AUTHLAYOUT'
'use client'

import { useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { useAuthStore } from '@/features/auth/store/authStore'

export default function AuthLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const router = useRouter()
  const { isAuthenticated, checkAuth } = useAuthStore()
  
  useEffect(() => {
    checkAuth()
  }, [])
  
  useEffect(() => {
    if (isAuthenticated) {
      router.push('/dashboard')
    }
  }, [isAuthenticated, router])
  
  return <>{children}</>
}
AUTHLAYOUT

# PART 11: Create Next.js middleware
echo -e "${GREEN}Creating Next.js middleware...${NC}"
cat > frontend/src/middleware.ts << 'MIDDLEWARE'
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

// Paths that require authentication
const protectedPaths = [
  '/dashboard',
  '/projects',
  '/tasks',
  '/profile',
  '/settings',
]

// Paths that should redirect to dashboard if authenticated
const authPaths = [
  '/login',
  '/register',
  '/forgot-password',
]

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl
  
  // Check if the path requires authentication
  const isProtectedPath = protectedPaths.some(path => pathname.startsWith(path))
  const isAuthPath = authPaths.some(path => pathname.startsWith(path))
  
  // Get the auth token from cookies
  const token = request.cookies.get('accessToken')
  
  if (isProtectedPath && !token) {
    // Redirect to login if accessing protected route without auth
    const loginUrl = new URL('/login', request.url)
    loginUrl.searchParams.set('from', pathname)
    return NextResponse.redirect(loginUrl)
  }
  
  if (isAuthPath && token) {
    // Redirect to dashboard if accessing auth pages while authenticated
    return NextResponse.redirect(new URL('/dashboard', request.url))
  }
  
  return NextResponse.next()
}

export const config = {
  matcher: [
    /*
     * Match all request paths except for the ones starting with:
     * - api (API routes)
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     * - public files
     */
    '/((?!api|_next/static|_next/image|favicon.ico|.*\\..*|_next).*)',
  ],
}
MIDDLEWARE

# PART 12: Update .env.example
echo -e "${GREEN}Updating .env files...${NC}"
cat >> .env.example << 'ENV'

# Supabase
NEXT_PUBLIC_SUPABASE_URL=your-supabase-project-url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-supabase-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-supabase-service-role-key
SUPABASE_URL=your-supabase-project-url

# API
NEXT_PUBLIC_API_URL=http://localhost:8080
ENV

echo ""
echo -e "${BLUE}================================================${NC}"
echo -e "${GREEN}    Authentication System Setup Complete!      ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo ""
echo "1. Set up Supabase project:"
echo "   - Go to https://supabase.com and create a new project"
echo "   - Copy your project URL and keys"
echo ""
echo "2. Update environment variables:"
echo "   Add to ${BLUE}.env${NC}:"
echo "   NEXT_PUBLIC_SUPABASE_URL=your-project-url"
echo "   NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key"
echo "   SUPABASE_SERVICE_ROLE_KEY=your-service-role-key"
echo ""
echo "3. Update auth routes in API Gateway:"
echo "   Add the auth controller routes to your API Gateway"
echo ""
echo "4. Test the authentication flow:"
echo "   - Start backend: ${BLUE}cd backend/services/api-gateway && npm run dev${NC}"
echo "   - Start frontend: ${BLUE}cd frontend && npm run dev${NC}"
echo "   - Visit: ${BLUE}http://localhost:3000/login${NC}"
echo ""
echo -e "${YELLOW}Files created:${NC}"
echo "  ✓ Backend Supabase client and JWT utilities"
echo "  ✓ Auth controller with register/login/logout"
echo "  ✓ Frontend auth service with Supabase integration"
echo "  ✓ Zustand auth store for state management"
echo "  ✓ Auth hooks for protected routes"
echo "  ✓ Login page with form handling"
echo "  ✓ Auth layout for redirect logic"
echo "  ✓ Next.js middleware for route protection"
echo ""
echo -e "${YELLOW}Protected routes configured:${NC}"
echo "  • /dashboard"
echo "  • /projects"
echo "  • /tasks"
echo "  • /profile"
echo "  • /settings"
echo ""
echo -e "${GREEN}Your authentication system is ready!${NC}"
