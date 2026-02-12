-- User API Keys: BYOK (Bring Your Own Key) encrypted storage
create table public.user_api_keys (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  provider text not null,
  encrypted_key text not null,
  key_hint text not null,
  is_active boolean not null default true,
  last_used_at timestamptz,
  created_at timestamptz not null default now(),

  -- One key per provider per user
  unique(user_id, provider)
);

create index idx_user_api_keys_user on public.user_api_keys(user_id);

-- Enable RLS
alter table public.user_api_keys enable row level security;

-- Users can manage their own keys
create policy "Users can view own API keys"
  on public.user_api_keys for select
  using (auth.uid() = user_id);

create policy "Users can add API keys"
  on public.user_api_keys for insert
  with check (auth.uid() = user_id);

create policy "Users can update own API keys"
  on public.user_api_keys for update
  using (auth.uid() = user_id);

create policy "Users can delete own API keys"
  on public.user_api_keys for delete
  using (auth.uid() = user_id);

-- Service role full access (for AI Broker to decrypt)
create policy "Service role manages API keys"
  on public.user_api_keys for all
  using (auth.role() = 'service_role');
