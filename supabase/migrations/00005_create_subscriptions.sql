-- Subscription Tiers: config table (not per-user)
create table public.subscription_tiers (
  id text primary key,
  name text not null,
  price_monthly numeric(6,2) not null default 0,
  price_annual numeric(7,2) not null default 0,
  max_installed_agents integer not null default 3,
  fast_calls_per_day integer not null default 10,
  smart_calls_per_day integer not null default 0,
  deep_calls_per_day integer not null default 0,
  max_calls_per_day integer not null default 0,
  max_automations integer not null default 0,
  vision_enabled boolean not null default false,
  byok_enabled boolean not null default true,
  history_retention_days integer not null default 3,
  allowed_models text[] not null default array['gpt-4o-mini'],
  features jsonb not null default '{}'::jsonb
);

-- Seed tier configs
insert into public.subscription_tiers (id, name, price_monthly, price_annual, max_installed_agents, fast_calls_per_day, smart_calls_per_day, deep_calls_per_day, max_calls_per_day, max_automations, vision_enabled, history_retention_days, allowed_models, features) values
  ('free', 'Free', 0, 0, 3, 10, 0, 0, 0, 0, false, 3,
    array['gpt-4o-mini'],
    '{"agent_chaining": false, "push_notifications": false, "integrations": false}'::jsonb),
  ('starter', 'Starter', 9.99, 99.99, 15, 75, 0, 0, 0, 0, false, 30,
    array['gpt-4o-mini', 'claude-haiku-4.5'],
    '{"agent_chaining": false, "push_notifications": "local", "integrations": false}'::jsonb),
  ('pro', 'Pro', 29.99, 299.99, 50, 200, 30, 5, 0, 3, true, 90,
    array['gpt-4o-mini', 'claude-haiku-4.5', 'gpt-4o', 'claude-sonnet-4.5', 'claude-opus-4.6'],
    '{"agent_chaining": true, "max_chain_steps": 3, "push_notifications": "server", "integrations": ["gmail_read", "calendar"]}'::jsonb),
  ('unlimited', 'Unlimited', 99.99, 999.99, -1, 500, 100, 15, 5, 10, true, -1,
    array['gpt-4o-mini', 'claude-haiku-4.5', 'gpt-4o', 'claude-sonnet-4.5', 'claude-opus-4.6', 'claude-opus-4.6-max'],
    '{"agent_chaining": true, "max_chain_steps": -1, "push_notifications": "server", "integrations": ["gmail_read", "gmail_write", "calendar"], "batch_operations": true, "priority_processing": true, "api_access": true, "1m_context": true}'::jsonb);

-- RLS: tiers are publicly readable
alter table public.subscription_tiers enable row level security;

create policy "Tiers are publicly readable"
  on public.subscription_tiers for select
  using (true);

-- User Subscriptions
create table public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid unique not null references public.profiles(id) on delete cascade,
  tier text not null default 'free' references public.subscription_tiers(id),
  storekit_product_id text,
  storekit_transaction_id text,
  storekit_original_transaction_id text,
  status text not null default 'active',
  trial_active boolean not null default false,
  current_period_start timestamptz,
  current_period_end timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_subscriptions_user on public.subscriptions(user_id);

-- Enable RLS
alter table public.subscriptions enable row level security;

-- Users can read their own subscription
create policy "Users can view own subscription"
  on public.subscriptions for select
  using (auth.uid() = user_id);

-- Only service role can create/update subscriptions (StoreKit webhook)
create policy "Service role manages subscriptions"
  on public.subscriptions for all
  using (auth.role() = 'service_role');

-- Auto-create subscription on profile creation
create or replace function public.handle_new_profile()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.subscriptions (user_id, tier, trial_active, current_period_end)
  values (new.id, 'free', true, new.trial_expires_at);
  return new;
end;
$$;

create trigger on_profile_created
  after insert on public.profiles
  for each row execute function public.handle_new_profile();

-- Updated_at trigger
create trigger subscriptions_updated_at
  before update on public.subscriptions
  for each row execute function public.update_updated_at();
