-- Security scan results (service-role only — not user-facing)
create table if not exists public.security_scan_results (
  id uuid primary key default gen_random_uuid(),
  template_id text not null,
  score integer not null default 0,
  passed boolean not null default false,
  findings jsonb not null default '[]'::jsonb,
  passed_checks text[] not null default '{}',
  scanned_at timestamptz not null default now()
);

-- Index for lookups
create index idx_security_scans_template on public.security_scan_results(template_id);
create index idx_security_scans_date on public.security_scan_results(scanned_at desc);

-- RLS: service role only
alter table public.security_scan_results enable row level security;

create policy "Service role can manage scan results"
  on public.security_scan_results for all
  using (auth.role() = 'service_role');
