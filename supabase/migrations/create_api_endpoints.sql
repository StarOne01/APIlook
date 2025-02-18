create table api_endpoints (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  url text not null,
  method text not null,
  headers jsonb default '{}'::jsonb,
  parameters jsonb default '{}'::jsonb,
  created_at timestamp with time zone default timezone('utc'::text, now()),
  updated_at timestamp with time zone default timezone('utc'::text, now())
);
