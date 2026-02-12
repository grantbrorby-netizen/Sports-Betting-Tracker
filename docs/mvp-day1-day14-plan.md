# AgentHub MVP Build Plan (Day 1–Day 14)

This document translates your product vision into a practical two-week implementation plan with concrete tickets, minimal database schema, and a conversion-oriented initial template lineup.

## 1) Day 1–Day 14 Ticket Plan

## Week 1 — Manual agents + billing + usage controls

### Day 1 — Repo foundation and environments
- [ ] Create project scaffolding for `ios/`, `supabase/`, and `agent-templates/`
- [ ] Add `.env.example` with Supabase/Apple/OpenAI/Anthropic placeholders
- [ ] Add root `README.md` with local setup and architecture summary
- [ ] Add CI workflow: lint + tests placeholders

**Definition of done**
- Clean clone can boot all workspaces with documented commands
- Secrets excluded and `.gitignore` covers local artifacts

### Day 2 — Agent template schema v1
- [ ] Implement `agent-template.schema.json` (strict, JSON-only)
- [ ] Include: metadata, inputs, output contract, model tier, `requiresVision`
- [ ] Add CLI validator script to validate template files
- [ ] Add 3 initial templates (email writer, grocery list, bill explainer)

**Definition of done**
- Invalid templates fail validation with actionable error messages
- Schema disallows arbitrary executable/action fields

### Day 3 — Supabase core tables, part 1
- [ ] Create migration: `profiles`
- [ ] Create migration: `agent_templates`
- [ ] Create migration: `installed_agents`
- [ ] Apply RLS policies for user-owned reads/writes

**Definition of done**
- New auth user auto-creates `profiles` row
- Template browse is public/read-only, installs are per-user isolated

### Day 4 — Supabase core tables, part 2
- [ ] Create migration: `subscriptions`
- [ ] Create migration: `subscription_tiers` seed (free/starter/pro/unlimited)
- [ ] Create migration: `usage_tracking`
- [ ] Create migration: `agent_executions`

**Definition of done**
- Can query daily usage counters by model tier
- Can persist execution logs for history and debugging

### Day 5 — AI broker edge function (MVP path)
- [ ] Build `ai-broker` function: auth → tier gate → usage check → provider route
- [ ] Support OpenAI (`gpt-4o-mini`, `gpt-4o`) and Anthropic (`haiku`, `sonnet`, `opus`) model mapping
- [ ] Add BYOK bypass for usage limits
- [ ] Log usage for app-provided keys and BYOK calls (with `is_byok=true`)

**Definition of done**
- Authenticated user can run a template and receive normalized response
- Over-limit users receive deterministic 429

### Day 6 — Registry + scanner baseline
- [ ] Build `agent-registry` list/search endpoint
- [ ] Build schema validation scan step
- [ ] Add lightweight prompt-injection / data-exfil heuristics
- [ ] Store scan results in `security_scan_results`

**Definition of done**
- Unscanned/failed templates cannot be featured or installed
- Registry returns only active + passed templates

### Day 7 — iOS MVP shell + paywall wiring
- [ ] Implement auth gate (Apple + email)
- [ ] Build store list + detail + install
- [ ] Build agent run screen with dynamic form renderer
- [ ] Add StoreKit2 purchase and trial start path

**Definition of done**
- User can sign in, install template, run it, and see output
- Subscription status updates app entitlements

## Week 2 — Automation MVP (time-triggered only)

### Day 8 — Automation schema and DB
- [ ] Add `automations` table (cron trigger, 1–3 steps, action config)
- [ ] Add `automation_runs` table
- [ ] Add profile device token support for APNs
- [ ] Add RLS and tier checks (Pro: 3, Unlimited: 10)

**Definition of done**
- Users can persist enabled/disabled automations with next run time

### Day 9 — Automations edge function
- [ ] Build CRUD endpoints for automations
- [ ] Validate trigger (`cron/time`) and step count
- [ ] Validate template existence + automation capability
- [ ] Enforce action types (`push_notification`, `save_result`)

**Definition of done**
- Invalid automation configs are rejected with clear field-level errors

### Day 10 — VPS worker skeleton
- [ ] Add Node + BullMQ + Redis worker project
- [ ] Implement scheduler worker to enqueue due automations
- [ ] Implement chain executor (sequential steps, pass outputs)
- [ ] Implement Supabase service-role client integration

**Definition of done**
- Due automation produces run record and step execution logs

### Day 11 — Push delivery end-to-end
- [ ] Implement APNs sender worker
- [ ] Add iOS remote notification registration and token upload
- [ ] Safe-format push payloads (no sensitive full outputs)
- [ ] Retry and dead-letter handling for failed push sends

**Definition of done**
- Successful automation run delivers push to test device

### Day 12 — iOS automation UI
- [ ] Build list view (status, last run, next run)
- [ ] Build create flow (time picker → cron conversion)
- [ ] Build enable/disable and history views
- [ ] Add tier gates in UI and API error handling

**Definition of done**
- Pro user can create, toggle, and review automation runs

### Day 13 — Hardening and abuse controls
- [ ] Add per-user/API rate limits on edge functions
- [ ] Add payload size limits and input sanitization
- [ ] Add template version pinning + source SHA tracking
- [ ] Tighten scanner URL/domain allow/deny checks

**Definition of done**
- Excessive or malformed requests are blocked safely
- Template provenance is auditable

### Day 14 — Release readiness sprint
- [ ] Privacy policy + terms + app review notes
- [ ] Test matrix pass: auth, purchase, usage limits, automations, push
- [ ] Crash/error observability basics
- [ ] Release checklist and rollback plan

**Definition of done**
- App Store submission package is complete for MVP scope

---

## 2) Minimal Postgres Schema (MVP-safe)

Below is the minimum schema that won’t haunt you later while still shipping fast.

### `profiles`
- `id uuid pk references auth.users(id)`
- `display_name text`
- `device_token text null`
- `trial_started_at timestamptz null`
- `trial_expires_at timestamptz null`
- `created_at timestamptz default now()`
- `updated_at timestamptz default now()`

RLS:
- User can select/update own profile only.

### `subscription_tiers` (seeded config)
- `id text pk` (`free`, `starter`, `pro`, `unlimited`)
- `max_installed_agents int`
- `fast_daily_limit int`
- `smart_daily_limit int`
- `deep_daily_limit int`
- `max_daily_limit int`
- `max_automations int`
- `vision_enabled boolean`
- `integration_level text` (`none`, `read`, `full`)

RLS:
- Read-only for authenticated users.

### `subscriptions`
- `id uuid pk`
- `user_id uuid references auth.users(id) unique`
- `tier_id text references subscription_tiers(id)`
- `status text` (`trialing`, `active`, `grace_period`, `canceled`, `expired`)
- `store_product_id text null`
- `store_original_tx_id text null`
- `renewal_at timestamptz null`
- `updated_at timestamptz default now()`

RLS:
- User can read own subscription.
- Service role updates via webhook.

### `agent_templates`
- `id uuid pk`
- `slug text unique`
- `name text`
- `description text`
- `category text`
- `schema_version text`
- `template_json jsonb`
- `default_model_tier text` (`fast`, `smart`, `deep`, `max`)
- `requires_vision boolean default false`
- `supports_automation boolean default false`
- `source_repo text`
- `source_sha text`
- `scan_status text` (`pending`, `passed`, `failed`)
- `is_active boolean default true`
- `created_at timestamptz default now()`

RLS:
- Auth users read active+passed only.
- Writes service-role only.

### `installed_agents`
- `id uuid pk`
- `user_id uuid references auth.users(id)`
- `agent_template_id uuid references agent_templates(id)`
- `custom_name text null`
- `is_pinned boolean default false`
- `created_at timestamptz default now()`

Constraints:
- Unique `(user_id, agent_template_id)`.

RLS:
- User owns all CRUD on own installs.

### `agent_executions`
- `id uuid pk`
- `user_id uuid references auth.users(id)`
- `agent_template_id uuid references agent_templates(id)`
- `triggered_by text` (`manual`, `automation`)
- `model_tier text`
- `provider text`
- `input_json jsonb`
- `output_json jsonb`
- `prompt_tokens int`
- `completion_tokens int`
- `is_byok boolean default false`
- `duration_ms int`
- `created_at timestamptz default now()`

RLS:
- User reads own history.
- Inserts by broker/service role with validated user id.

### `usage_tracking`
- `id uuid pk`
- `user_id uuid references auth.users(id)`
- `date date`
- `model_tier text`
- `calls int default 0`
- `prompt_tokens bigint default 0`
- `completion_tokens bigint default 0`
- `is_byok boolean default false`
- `automation_calls int default 0`

Constraints:
- Unique `(user_id, date, model_tier, is_byok)`.

RLS:
- User can read own usage.
- Upserts by broker/service role.

### `user_api_keys`
- `id uuid pk`
- `user_id uuid references auth.users(id)`
- `provider text` (`openai`, `anthropic`)
- `encrypted_key text`
- `masked_hint text`
- `is_valid boolean default true`
- `created_at timestamptz default now()`

RLS:
- User owns all CRUD on own keys.
- Never return `encrypted_key` in client-facing selects.

### `automations`
- `id uuid pk`
- `user_id uuid references auth.users(id)`
- `name text`
- `trigger_type text` (`cron`)
- `trigger_config jsonb`
- `steps jsonb` (1–3 step chain)
- `action_type text` (`push_notification`, `save_result`)
- `action_config jsonb`
- `is_enabled boolean default true`
- `status text` (`active`, `paused`, `error`)
- `last_run_at timestamptz null`
- `next_run_at timestamptz null`
- `error_message text null`
- `created_at timestamptz default now()`

RLS:
- User owns all CRUD on own automations.

### `automation_runs`
- `id uuid pk`
- `automation_id uuid references automations(id)`
- `user_id uuid references auth.users(id)`
- `status text` (`queued`, `running`, `success`, `failed`)
- `step_results jsonb`
- `push_sent boolean default false`
- `started_at timestamptz default now()`
- `completed_at timestamptz null`

RLS:
- User reads own runs.
- Worker/service role inserts + updates.

---

## 3) First 12 Template Lineup (conversion-first)

These 12 templates maximize immediate value while supporting your Week 2 automation upsell.

1. **Email Writer** (manual)
2. **Bill Explainer** (manual; vision-ready tier gate)
3. **Appointment Prep** (manual)
4. **Letter Writer** (manual)
5. **Thank-You Note Writer** (manual)
6. **Complaint Drafter** (manual)
7. **Recipe Helper** (manual)
8. **Grocery List Builder** (manual)
9. **Daily Plan Builder** (automation-ready)
10. **Evening Reset** (automation-ready)
11. **Weekly Money Check-in** (automation-ready)
12. **Email Summarizer Lite** (manual first, automation-ready later with Gmail read)

Recommended tagging:
- `quick-win`: 1–8
- `automation-ready`: 9–12
- `vision`: 2
- `pro-hook`: 9–12

---

## 4) Implementation Guardrails

- Keep schema strict and backward-compatible via `schema_version`.
- Keep automations time-based first; defer Gmail/Calendar writes until post-launch verification runway.
- Track token/call usage from day one for pricing truth.
- Treat push notifications as eventually delivered summaries (not guaranteed instant).
- Keep BYOK unlimited but separately metered for product analytics.

