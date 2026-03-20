# Votio

Voice journaling with AI analysis and visual clip generation.

## Overview

Votio transforms voice journals into visual insights:

1. **Record** — User records a voice journal entry
2. **Transcribe** — Audio is converted to text
3. **Analyze** — AI extracts emotional insights and themes
4. **Generate** — A short visual clip is composed based on mood and themes
5. **Display** — User sees the clip with insights and summary

## Architecture

This is a **monorepo** with two primary applications:

- **Mobile (`apps/mobile`)** — Flutter cross-platform app (iOS, Android)
- **Backend (`apps/backend`)** — NestJS API with async processing pipeline

## Stack

| Concern      | Choice                       |
| ------------ | ---------------------------- |
| Backend      | NestJS (TypeScript)          |
| Database     | PostgreSQL + Prisma ORM      |
| Queue / Jobs | Bull + Redis                 |
| Mobile       | Flutter + Riverpod           |
| State        | Riverpod v2 (code-generated) |
| Navigation   | GoRouter                     |
| HTTP         | Dio + Retrofit               |
| Storage      | S3-compatible abstraction    |

## Getting Started

### Prerequisites

- **Node.js** ≥ 18
- **Flutter** ≥ 3.3 with Dart
- **Docker** and **Docker Compose** (for local services: PostgreSQL, Redis)
- **Git**

### 1. Install Dependencies

```bash
# Install root-level npm packages (linting, formatting, commit hooks)
npm install

# Install Flutter dependencies
cd apps/mobile
flutter pub get

# Install backend dependencies
cd ../backend
npm install
```

### 2. Start Local Services

```bash
# From repo root, start Postgres + Redis in containers
docker-compose up -d

# Verify services are healthy
docker-compose ps
```

### 3. Initialize Backend Database

```bash
cd apps/backend

# Copy environment file
cp .env.example .env

# Run database migrations
npm run prisma:migrate

# (Optional) Seed with test data
npm run prisma:seed
```

### 4. Start Backend

```bash
cd apps/backend
npm run dev

# Backend runs on http://localhost:3000
# Swagger docs at http://localhost:3000/api/docs
```

### 5. Start Mobile App

```bash
cd apps/mobile

# Run on development flavor (recommended for development)
flutter run --flavor development --dart-define=FLAVOR=development

# Or build APK for testing
flutter build apk --debug --flavor development
```

## Project Structure

```
votio/
├── apps/
│   ├── mobile/          # Flutter app
│   └── backend/         # NestJS API
├── packages/            # Shared packages (future)
├── docs/                # Architecture & development docs
├── scripts/             # Utility scripts
├── environments/        # Environment config templates
└── docker-compose.yml   # Local services
```

## Development Workflows

### Code Quality

**Lint TypeScript:**

```bash
npm run lint
```

**Format all files:**

```bash
npm run format
```

**Type check backend:**

```bash
npm run type-check
```

**Lint Flutter:**

```bash
cd apps/mobile
melos run analyze
```

### Testing

**Backend unit tests:**

```bash
cd apps/backend
npm run test
```

**Flutter tests:**

```bash
cd apps/mobile
melos run test
```

### Database

**Create a new migration:**

```bash
cd apps/backend
npm run prisma:migrate -- --name your_migration_name
```

**Open Prisma Studio:**

```bash
cd apps/backend
npm run prisma:studio
```

## Commit Convention

This repo enforces **Conventional Commits** via `commitlint`:

```
type(scope): short description

Optional longer description here.

Closes #123
```

**Types:** `feat`, `fix`, `refactor`, `docs`, `test`, `chore`

**Scopes:** `mobile`, `backend`, `auth`, `audio`, `transcription`, `analysis`, `clips`, `history`, `subscriptions`, `notifications`, `infra`, `docs`, `ci`, `deps`, `config`

Example:

```bash
git commit -m "feat(recording): add waveform visualization widget"
git commit -m "fix(backend): handle malformed audio uploads gracefully"
```

## Environment Configuration

Sensitive configuration is managed via `.env` files (gitignored):

**Backend (apps/backend/.env):**

```bash
DATABASE_URL=postgresql://votio:votio_local@localhost:5432/votio_dev
REDIS_URL=redis://localhost:6379
JWT_SECRET=your-secret-key
NODE_ENV=development
```

**Mobile (apps/mobile/.env.development):**

```bash
API_BASE_URL=http://localhost:3000
API_TIMEOUT_MS=30000
```

See `.env.example` files for the full list of required variables.

## Architecture Decisions

Detailed rationale for technology and pattern choices:

- **[ADR-001: Backend Framework](docs/decisions/ADR-001-backend-framework.md)** — Why NestJS over FastAPI
- **[ADR-002: State Management](docs/decisions/ADR-002-state-management.md)** — Why Riverpod over Bloc
- **[ADR-003: Audio Pipeline](docs/decisions/ADR-003-audio-pipeline.md)** — State machine for async processing

## Documentation

- **[Architecture Overview](docs/architecture/overview.md)** — System design and components
- **[Backend Architecture](docs/architecture/backend.md)** — NestJS module structure
- **[Mobile Architecture](docs/architecture/mobile.md)** — Flutter feature structure
- **[Data Flow](docs/architecture/data-flow.md)** — Audio pipeline state machine
- **[Environment Setup](docs/development/environment-setup.md)** — Detailed setup guide
- **[Contributing](docs/development/contributing.md)** — Development guidelines

## Troubleshooting

### `docker-compose up` fails

**Check Docker is running:**

```bash
docker ps
```

**View logs:**

```bash
docker-compose logs postgres
docker-compose logs redis
```

### Backend won't start

**Verify Postgres is running and healthy:**

```bash
docker-compose ps postgres
```

**Check DATABASE_URL in .env:**

```bash
cd apps/backend
cat .env | grep DATABASE_URL
```

**Verify migrations applied:**

```bash
npm run prisma:generate
npm run prisma:migrate
```

### Flutter build fails

**Clean build cache:**

```bash
cd apps/mobile
flutter clean
flutter pub get
melos run build_runner
```

**Verify analyze passes:**

```bash
melos run analyze
```

## Next Steps

This setup is infrastructure-only. To begin feature development:

1. **Implement authentication** — Backend auth endpoints + Flutter auth flow
2. **Implement audio upload** — Multipart upload + local storage
3. **Wire the recording flow** — Flutter recording screen + backend pipeline
4. **Add third-party integrations** — Whisper, OpenAI, clip generation service

See [What's Left After Setup](docs/development/getting-started.md#whats-left) for the full roadmap.

## License

TBD

## Support

For issues or questions, file a GitHub issue or reach out to the team.
