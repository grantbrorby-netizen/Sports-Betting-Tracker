-- Automation run history: each execution of an automation
create table if not exists public.automation_runs (
  id uuid primary key default gen_random_uuid(),
  automation_id uuid references public.automations(id) on delete cascade not null,
  user_id uuid references auth.users(id) on delete cascade not null,

  -- Timing
  started_at timestamptz not null default now(),
  completed_at timestamptz,

  -- Status
  status text not null default 'running' check (status in ('running', 'completed', 'failed')),
  error_message text,

  -- Step results: array of {step_name, output, tokens_used, duration_ms}
  step_results jsonb not null default '[]'::jsonb,

  -- Final output (last step output)
  final_output text,

  -- Usage tracking
  total_tokens_used integer not null default 0,
  total_duration_ms integer,
  model_tier text not null default 'fast',
  provider text,
  is_byok boolean not null default false,

  -- Push notification status
  push_sent boolean not null default false,
  push_sent_at timestamptz,

  -- Links to execution record
  execution_id uuid references public.agent_executions(id)
);

-- Indexes
create index idx_automation_runs_automation_id on public.automation_runs(automation_id);
create index idx_automation_runs_user_id on public.automation_runs(user_id);
create index idx_automation_runs_status on public.automation_runs(status);
create index idx_automation_runs_started_at on public.automation_runs(started_at desc);

-- RLS
alter table public.automation_runs enable row level security;

create policy "Users can view own automation runs"
  on public.automation_runs for select
  using (auth.uid() = user_id);

-- Service role manages runs (VPS worker creates/updates them)
create policy "Service role can manage automation runs"
  on public.automation_runs for all
  using (auth.role() = 'service_role');

-- Add device_token to profiles if not present
do $$
begin
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
    and table_name = 'profiles'
    and column_name = 'device_token'
  ) then
    alter table public.profiles add column device_token text;
  end if;
end $$;
