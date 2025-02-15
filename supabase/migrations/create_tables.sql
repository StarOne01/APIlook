create table requests (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references auth.users,
  name text,
  url text,
  method text,
  headers jsonb,
  body jsonb,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

create table collections (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references auth.users,
  name text,
  created_at timestamp with time zone default timezone('utc'::text, now())
);
