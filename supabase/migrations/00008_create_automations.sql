-- Automations: user-configured scheduled agent runs
create table if not exists public.automations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  name text not null,
  template_id text not null,

  -- Trigger config (cron-only for now)
  trigger_type text not null default 'cron' check (trigger_type in ('cron')),
  cron_expression text not null,
  timezone text not null default 'America/New_York',

  -- Steps: array of {name, systemPrompt, maxTokens}
  -- If empty/null, uses the template's main systemPrompt as a single step
  steps jsonb default '[]'::jsonb,

  -- Static input values to use when automation fires
  input_values jsonb not null default '{}'::jsonb,

  -- Action config
  action_type text not null default 'push_notification' check (action_type in ('push_notification', 'save_result')),
  push_title text,

  -- Model tier to use
  model_tier text not null default 'fast' check (model_tier in ('fast', 'smart', 'deep', 'max')),

  -- State
  is_enabled boolean not null default true,
  last_run_at timestamptz,
  next_run_at timestamptz,
  status text not null default 'active' check (status in ('active', 'paused', 'error')),
  error_message text,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Indexes
create index idx_automations_user_id on public.automations(user_id);
create index idx_automations_next_run on public.automations(next_run_at) where is_enabled = true;
create index idx_automations_status on public.automations(status);

-- RLS
alter table public.automations enable row level security;

create policy "Users can view own automations"
  on public.automations for select
  using (auth.uid() = user_id);

create policy "Users can create own automations"
  on public.automations for insert
  with check (auth.uid() = user_id);

create policy "Users can update own automations"
  on public.automations for update
  using (auth.uid() = user_id);

create policy "Users can delete own automations"
  on public.automations for delete
  using (auth.uid() = user_id);

-- Service role can read all (for VPS worker)
create policy "Service role can read all automations"
  on public.automations for select
  using (auth.role() = 'service_role');

create policy "Service role can update all automations"
  on public.automations for update
  using (auth.role() = 'service_role');

-- Updated_at trigger
create or replace function update_automations_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger automations_updated_at
  before update on public.automations
  for each row execute function update_automations_updated_at();
