-- Installed Agents: user's personal agent library
create table public.installed_agents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  template_id uuid not null references public.agent_templates(id) on delete cascade,
  custom_name text,
  is_pinned boolean not null default false,
  sort_order integer not null default 0,
  last_used_at timestamptz,
  installed_at timestamptz not null default now(),

  -- One install per user per template
  unique(user_id, template_id)
);

-- Fast lookups by user
create index idx_installed_agents_user on public.installed_agents(user_id);
create index idx_installed_agents_pinned on public.installed_agents(user_id, is_pinned) where is_pinned = true;

-- Enable RLS
alter table public.installed_agents enable row level security;

-- Users see only their own installed agents
create policy "Users can view own installed agents"
  on public.installed_agents for select
  using (auth.uid() = user_id);

create policy "Users can install agents"
  on public.installed_agents for insert
  with check (auth.uid() = user_id);

create policy "Users can update own installed agents"
  on public.installed_agents for update
  using (auth.uid() = user_id);

create policy "Users can uninstall own agents"
  on public.installed_agents for delete
  using (auth.uid() = user_id);

-- Service role full access
create policy "Service role manages installed agents"
  on public.installed_agents for all
  using (auth.role() = 'service_role');
