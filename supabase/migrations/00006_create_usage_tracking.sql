-- Usage Tracking: daily counters per model tier
create table public.usage_tracking (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  date date not null default current_date,
  fast_calls integer not null default 0,
  smart_calls integer not null default 0,
  deep_calls integer not null default 0,
  max_calls integer not null default 0,
  total_tokens integer not null default 0,
  byok_calls integer not null default 0,
  automation_calls integer not null default 0,

  -- One row per user per day
  unique(user_id, date)
);

create index idx_usage_tracking_user_date on public.usage_tracking(user_id, date desc);

-- Enable RLS
alter table public.usage_tracking enable row level security;

-- Users can read their own usage
create policy "Users can view own usage"
  on public.usage_tracking for select
  using (auth.uid() = user_id);

-- Service role full access
create policy "Service role manages usage"
  on public.usage_tracking for all
  using (auth.role() = 'service_role');

-- Function to get today's usage for a user
create or replace function public.get_daily_usage(p_user_id uuid)
returns table(
  fast_calls integer,
  smart_calls integer,
  deep_calls integer,
  max_calls integer,
  total_tokens integer,
  byok_calls integer,
  automation_calls integer
)
language plpgsql
security definer
as $$
begin
  return query
  select
    coalesce(ut.fast_calls, 0),
    coalesce(ut.smart_calls, 0),
    coalesce(ut.deep_calls, 0),
    coalesce(ut.max_calls, 0),
    coalesce(ut.total_tokens, 0),
    coalesce(ut.byok_calls, 0),
    coalesce(ut.automation_calls, 0)
  from public.usage_tracking ut
  where ut.user_id = p_user_id and ut.date = current_date;

  -- Return zeros if no row exists yet
  if not found then
    return query select 0, 0, 0, 0, 0, 0, 0;
  end if;
end;
$$;

-- Function to increment usage (called by AI Broker)
create or replace function public.increment_usage(
  p_user_id uuid,
  p_model_tier text,
  p_tokens integer,
  p_is_byok boolean default false,
  p_is_automation boolean default false
)
returns void
language plpgsql
security definer
as $$
begin
  insert into public.usage_tracking (user_id, date, fast_calls, smart_calls, deep_calls, max_calls, total_tokens, byok_calls, automation_calls)
  values (
    p_user_id,
    current_date,
    case when p_model_tier = 'fast' then 1 else 0 end,
    case when p_model_tier = 'smart' then 1 else 0 end,
    case when p_model_tier = 'deep' then 1 else 0 end,
    case when p_model_tier = 'max' then 1 else 0 end,
    p_tokens,
    case when p_is_byok then 1 else 0 end,
    case when p_is_automation then 1 else 0 end
  )
  on conflict (user_id, date) do update set
    fast_calls = usage_tracking.fast_calls + case when p_model_tier = 'fast' then 1 else 0 end,
    smart_calls = usage_tracking.smart_calls + case when p_model_tier = 'smart' then 1 else 0 end,
    deep_calls = usage_tracking.deep_calls + case when p_model_tier = 'deep' then 1 else 0 end,
    max_calls = usage_tracking.max_calls + case when p_model_tier = 'max' then 1 else 0 end,
    total_tokens = usage_tracking.total_tokens + p_tokens,
    byok_calls = usage_tracking.byok_calls + case when p_is_byok then 1 else 0 end,
    automation_calls = usage_tracking.automation_calls + case when p_is_automation then 1 else 0 end;
end;
$$;
