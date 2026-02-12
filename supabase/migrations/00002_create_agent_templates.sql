-- Agent Templates: the marketplace catalog
create table public.agent_templates (
  id uuid primary key default gen_random_uuid(),
  template_id text unique not null,
  name text not null,
  description text not null,
  category text not null,
  icon_name text not null default 'cpu',
  system_prompt text not null,
  input_schema jsonb not null default '[]'::jsonb,
  output_format text not null default 'markdown',
  default_model_tier text not null default 'fast',
  requires_vision boolean not null default false,
  max_tokens integer not null default 1024,
  temperature numeric(3,2) not null default 0.7,
  is_featured boolean not null default false,
  is_public boolean not null default true,
  version text not null default '1.0.0',
  author text not null default 'AgentHub',
  scan_sha text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Full-text search
create index idx_agent_templates_search on public.agent_templates
  using gin(to_tsvector('english', name || ' ' || description));

-- Category + featured filtering
create index idx_agent_templates_category on public.agent_templates(category);
create index idx_agent_templates_featured on public.agent_templates(is_featured) where is_featured = true;

-- Enable RLS
alter table public.agent_templates enable row level security;

-- Anyone can read public templates
create policy "Public templates are readable by all"
  on public.agent_templates for select
  using (is_public = true);

-- Service role can manage templates
create policy "Service role manages templates"
  on public.agent_templates for all
  using (auth.role() = 'service_role');

-- Updated_at trigger
create trigger agent_templates_updated_at
  before update on public.agent_templates
  for each row execute function public.update_updated_at();
