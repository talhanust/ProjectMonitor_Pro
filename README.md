# Engineering Application Monorepo

A modern, scalable monorepo architecture for engineering applications built with TypeScript, featuring a React frontend and Fastify backend.

## 🏗️ Architecture Overview

This monorepo uses npm workspaces to manage multiple packages and services:

```
engineering-app-monorepo/
├── frontend/                 # React + Vite frontend application
├── backend/
│   └── services/
│       └── api/             # Fastify REST API service
├── packages/                # Shared packages
│   ├── shared/             # Shared utilities and types
│   ├── ui/                 # Shared UI components (future)
│   └── config/             # Shared configuration (future)
├── docs/                    # Documentation
├── scripts/                 # Build and deployment scripts
└── tools/                   # Development tools and utilities
```

## 🚀 Quick Start

### Prerequisites

- Node.js >= 20.0.0
- npm >= 10.0.0

### Installation

1. Clone the repository:

```bash
git clone <repository-url>
cd engineering-app-monorepo
```

2. Set the correct Node version:

```bash
nvm use
```

3. Install dependencies:

```bash
npm install
```

4. Set up environment variables:

```bash
cp .env.example .env
# Edit .env with your configuration
```

5. Initialize the database (if using Prisma):

```bash
npm run migrate -w @backend/api
```

### Development

Run all services in development mode:

```bash
npm run dev
```

Or run individual services:

```bash
# Frontend only
npm run dev:frontend

# Backend only
npm run dev:backend
```

## 📦 Workspace Structure

### Frontend (`/frontend`)

- **Framework**: React 18 with TypeScript
- **Build Tool**: Vite
- **Styling**: Tailwind CSS
- **State Management**: Zustand
- **Routing**: TanStack Router
- **API Client**: TanStack Query + Axios
- **Forms**: React Hook Form + Zod
- **Testing**: Vitest + React Testing Library

### Backend API (`/backend/services/api`)

- **Framework**: Fastify
- **Language**: TypeScript
- **Database**: Prisma ORM
- **Authentication**: JWT
- **Validation**: Zod
- **Documentation**: Swagger/OpenAPI
- **Logging**: Pino
- **Testing**: Vitest

### Shared Packages (`/packages/*`)

- **shared**: Common types, utilities, and constants
- **ui**: Reusable UI components (planned)
- **config**: Shared configuration (planned)

## 🛠️ Available Scripts

### Root Level Commands

| Command             | Description                                |
| ------------------- | ------------------------------------------ |
| `npm run dev`       | Start all services in development mode     |
| `npm run build`     | Build all packages for production          |
| `npm run test`      | Run tests across all workspaces            |
| `npm run lint`      | Lint all workspaces                        |
| `npm run format`    | Format code with Prettier                  |
| `npm run typecheck` | Type check all TypeScript files            |
| `npm run clean`     | Clean all build artifacts and node_modules |

### Workspace-Specific Commands

Run commands in specific workspaces:

```bash
# Frontend commands
npm run dev -w frontend
npm run build -w frontend
npm run test -w frontend

# Backend API commands
npm run dev -w @backend/api
npm run build -w @backend/api
npm run migrate -w @backend/api
```

## 🔧 Configuration

### TypeScript Configuration

The monorepo uses a base TypeScript configuration (`tsconfig.base.json`) that is extended by each workspace. This ensures consistent TypeScript settings across the entire project.

### Path Aliases

Path aliases are configured for cleaner imports:

- Frontend: `@/`, `@components/`, `@hooks/`, etc.
- Backend: `@/`, `@controllers/`, `@services/`, etc.
- Shared: `@shared/`, `@packages/`

### Environment Variables

Create `.env` files for environment-specific configuration:

- `.env` - Default/development environment
- `.env.local` - Local overrides (git ignored)
- `.env.production` - Production environment

## 📝 Development Guidelines

### Code Style

- TypeScript strict mode enabled
- ESLint for code linting
- Prettier for code formatting
- Husky for pre-commit hooks
- Conventional Commits for commit messages

### Git Workflow

1. Create feature branches from `main`
2. Follow conventional commit messages
3. Run tests and linting before committing
4. Create pull requests for code review
5. Merge to `main` after approval

### Testing Strategy

- Unit tests for utilities and services
- Integration tests for API endpoints
- Component tests for UI components
- E2E tests for critical user flows

## 🚢 Deployment

### Building for Production

```bash
# Build all packages
npm run build

# Build specific workspace
npm run build:frontend
npm run build:backend
```

### Docker Support (Coming Soon)

Dockerfiles and docker-compose configuration will be added for containerized deployment.

## 📚 Additional Resources

- [Frontend Documentation](./frontend/README.md)
- [Backend API Documentation](./backend/services/api/README.md)
- [Contributing Guidelines](./CONTRIBUTING.md)
- [Architecture Decision Records](./docs/adr/)

## 🤝 Contributing

Please read our [Contributing Guidelines](./CONTRIBUTING.md) before submitting PRs.

## 📄 License

[MIT License](./LICENSE)

## 🆘 Support

For issues and questions:

- Create an issue in the repository
- Check existing documentation
- Contact the development team

---

**Note**: This is a living document. As the project evolves, please keep this README updated with relevant information.
