-- Agent Executions: history of every agent run
create table public.agent_executions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  installed_agent_id uuid references public.installed_agents(id) on delete set null,
  template_id uuid not null references public.agent_templates(id),
  input jsonb not null default '{}'::jsonb,
  output text,
  provider text,
  model_tier text not null default 'fast',
  tokens_used integer not null default 0,
  duration_ms integer,
  is_byok boolean not null default false,
  triggered_by text not null default 'manual',
  status text not null default 'pending',
  error_message text,
  created_at timestamptz not null default now()
);

-- Fast lookups
create index idx_agent_executions_user on public.agent_executions(user_id, created_at desc);
create index idx_agent_executions_agent on public.agent_executions(installed_agent_id, created_at desc);
create index idx_agent_executions_status on public.agent_executions(status) where status = 'pending';

-- Enable RLS
alter table public.agent_executions enable row level security;

-- Users see only their own executions
create policy "Users can view own executions"
  on public.agent_executions for select
  using (auth.uid() = user_id);

create policy "Users can create own executions"
  on public.agent_executions for insert
  with check (auth.uid() = user_id);

-- Service role full access (for automation engine)
create policy "Service role manages executions"
  on public.agent_executions for all
  using (auth.role() = 'service_role');
