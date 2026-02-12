# AgentHub

**An AI agent marketplace for iOS — install agents, run them with a form, automate your day.**

AgentHub lets users browse a curated store of AI-powered agents, each designed for a specific task. No prompt engineering needed — fill in a structured form, tap Run, and get a focused result. Pro users can schedule automations that run agents on a timer and deliver results via push notification.

---

## Architecture

```
┌──────────────┐     ┌───────────────────────┐     ┌─────────────────┐
│  SwiftUI     │────▶│  Supabase Backend     │────▶│  AI Providers   │
│  iOS App     │◀────│  (Edge Functions +    │◀────│  (Claude, GPT)  │
│  (StoreKit2) │     │   Postgres + Auth)    │     └─────────────────┘
└──────────────┘     └───────────┬───────────┘
                                 │
                     ┌───────────▼───────────┐
                     │  VPS Worker           │
                     │  BullMQ + Redis       │
                     │  Scheduler → Executor │
                     │  → Push via APNs      │
                     └───────────────────────┘
```

- **iOS App** — Native SwiftUI with MVVM, StoreKit 2 subscriptions, Keychain auth
- **Supabase** — PostgreSQL with RLS, Edge Functions (Deno/TypeScript), Auth (Apple + email)
- **AI Broker** — Multi-provider routing (OpenAI + Anthropic) with BYOK support
- **VPS Worker** — Node.js automation engine with BullMQ job queue, Redis, APNs push

---

## Tech Stack

| Layer | Technology |
|---|---|
| iOS | SwiftUI, MVVM, StoreKit 2, Keychain |
| Backend | Supabase Edge Functions (Deno + TypeScript) |
| Database | PostgreSQL with Row Level Security |
| Auth | Supabase Auth (Apple Sign-In, email/password) |
| AI | OpenAI (GPT-4o, GPT-4o-mini), Anthropic (Claude Haiku/Sonnet/Opus) |
| Automation | Node.js, BullMQ, Redis, APNs HTTP/2 |
| Security | AES-256-GCM encryption, per-user rate limiting, security scanner |

---

## Project Structure

```
├── ios/AgentHub/                    # iOS application
│   └── AgentHub/
│       ├── App/                     # App entry point, ContentView
│       ├── Configuration/           # Environment config
│       ├── Models/                  # Data models (15 files)
│       ├── Services/                # Networking, Auth, Agents, Subscriptions, etc.
│       ├── ViewModels/              # MVVM view models (9 files)
│       ├── Views/                   # SwiftUI views organized by feature
│       │   ├── Auth/                # Login, SignUp, ForgotPassword
│       │   ├── Onboarding/          # 3-page onboarding
│       │   ├── Home/                # Home screen, agent cards, usage bar
│       │   ├── Store/               # Agent store, detail, featured
│       │   ├── Agent/               # Agent execution, results, history
│       │   ├── Automations/         # Automation CRUD, chain builder, run history
│       │   ├── Settings/            # Profile, subscription, API keys
│       │   └── Common/              # Shared UI components
│       ├── Utilities/               # Extensions, constants, haptics
│       └── Resources/               # StoreKit config
│
├── supabase/                        # Supabase backend
│   ├── config.toml                  # Supabase project config
│   ├── seed.sql                     # Seed data (11 templates, 4 tiers)
│   ├── migrations/                  # 10 SQL migrations
│   │   ├── 00001_create_profiles.sql
│   │   ├── 00002_create_agent_templates.sql
│   │   ├── 00003_create_installed_agents.sql
│   │   ├── 00004_create_agent_executions.sql
│   │   ├── 00005_create_subscriptions.sql
│   │   ├── 00006_create_usage_tracking.sql
│   │   ├── 00007_create_user_api_keys.sql
│   │   ├── 00008_create_automations.sql
│   │   ├── 00009_create_automation_runs.sql
│   │   └── 00010_create_security_scan_results.sql
│   └── functions/                   # Edge Functions
│       ├── _shared/                 # Shared utilities (auth, CORS, encryption, errors, rate limiter, usage)
│       ├── ai-broker/               # AI execution with multi-provider routing
│       ├── agent-registry/          # Template listing and search
│       ├── user-api-keys/           # BYOK key management
│       ├── automations/             # Automation CRUD
│       ├── security-scanner/        # Template security scanning (5 checks)
│       ├── subscription-webhook/    # App Store Server Notifications V2
│       └── tests/                   # Edge function tests
│
├── vps/                             # Automation worker (Node.js)
│   ├── src/
│   │   ├── workers/                 # Scheduler, executor, chain executor, push sender
│   │   └── services/                # Supabase client, APNs service
│   ├── Dockerfile
│   └── docker-compose.yml           # Node + Redis
│
├── agent-templates/                 # Agent template definitions
│   ├── schema/                      # JSON Schema for templates
│   └── templates/                   # 11 agent templates (8 manual + 3 automation)
│
├── scripts/                         # CLI tools
│   ├── validate-template.ts         # Template schema validator
│   └── scan-template.ts             # Security scanner CLI
│
└── docs/                            # Documentation
    ├── legal/                       # Privacy policy, Terms of Service
    └── app-store/                   # Review notes, App Store description
```

---

## Getting Started

### Prerequisites

- **Xcode 15+** with iOS 17 SDK
- **Supabase CLI** (`brew install supabase/tap/supabase`)
- **Deno** (`brew install deno`) — for Edge Functions
- **Node.js 20+** and **pnpm** — for VPS worker
- **Docker** — for local Redis (automation worker)

### 1. Clone and configure

```bash
git clone https://github.com/grantbrorby-netizen/Sports-Betting-Tracker.git
cd Sports-Betting-Tracker
cp .env.example .env
# Fill in your environment variables
```

### 2. Start Supabase locally

```bash
supabase start
supabase db reset  # Runs migrations + seed
```

### 3. Deploy Edge Functions

```bash
supabase functions deploy ai-broker
supabase functions deploy agent-registry
supabase functions deploy user-api-keys
supabase functions deploy automations
supabase functions deploy security-scanner
supabase functions deploy subscription-webhook
```

### 4. Run the iOS app

Open `ios/AgentHub/AgentHub.xcodeproj` in Xcode, select a simulator or device, and run.

### 5. Start the automation worker (optional)

```bash
cd vps
cp .env.example .env  # Configure Supabase URL, service key, APNs certs
docker-compose up -d  # Starts Redis
pnpm install && pnpm start
```

---

## Environment Variables

```bash
# Supabase
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# AI Providers (platform keys — used when users don't have BYOK)
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...

# Encryption (for BYOK key storage)
ENCRYPTION_KEY=your-256-bit-hex-key

# VPS Worker
REDIS_URL=redis://localhost:6379
APNS_KEY_ID=your-key-id
APNS_TEAM_ID=your-team-id
APNS_KEY_PATH=./certs/AuthKey.p8
APNS_BUNDLE_ID=com.agenthub.app
```

---

## Subscription Tiers

| Feature | Free | Starter $9.99/mo | Pro $29.99/mo | Unlimited $99.99/mo |
|---|---|---|---|---|
| Installed Agents | 3 | 15 | 50 | Unlimited |
| Fast AI/day | 10 | 75 | 200 | 500 |
| Smart AI/day | 0 | 0 | 30 | 100 |
| Deep AI/day | 0 | 0 | 5 | 15 |
| Max AI/day | 0 | 0 | 0 | 5 |
| Automations | 0 | 0 | 3 | 10 |
| BYOK | Yes | Yes | Yes | Yes |

BYOK calls are **unlimited** and bypass daily limits on all tiers. New users get a **7-day Pro trial**.

---

## Security

- **Row Level Security** on every table — users can only access their own data
- **AES-256-GCM** encryption for BYOK API keys at rest
- **Per-user sliding window rate limiting** on all endpoints
- **Security scanner** with 5 checks: schema validation, prompt injection detection, data exfiltration patterns, content policy, URL validation
- **Payload size limits** (100KB) on AI Broker
- **JWT auth** with short-lived tokens

---

## Documentation

- [Privacy Policy](docs/legal/privacy-policy.md)
- [Terms of Service](docs/legal/terms-of-service.md)
- [App Store Review Notes](docs/app-store/review-notes.md)
- [App Store Description](docs/app-store/description.md)

---

## License

Proprietary. All rights reserved.
