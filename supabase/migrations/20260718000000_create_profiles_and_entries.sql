create extension if not exists pgcrypto;

create table if not exists public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    display_name text,
    avatar_url text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists public.entries (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    title text,
    content text,
    status text not null default 'draft',
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint entries_status_check check (status in ('draft', 'ready_for_storyboard', 'archived')),
    constraint entries_has_content_check check (
        nullif(btrim(coalesce(title, '')), '') is not null
        or nullif(btrim(coalesce(content, '')), '') is not null
    )
);

create index if not exists entries_user_created_at_idx
    on public.entries (user_id, created_at desc);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
    before update on public.profiles
    for each row
    execute function public.set_updated_at();

drop trigger if exists set_entries_updated_at on public.entries;
create trigger set_entries_updated_at
    before update on public.entries
    for each row
    execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    insert into public.profiles (id, display_name, avatar_url)
    values (
        new.id,
        coalesce(
            new.raw_user_meta_data ->> 'full_name',
            new.raw_user_meta_data ->> 'name',
            new.email
        ),
        new.raw_user_meta_data ->> 'avatar_url'
    )
    on conflict (id) do update
    set
        display_name = excluded.display_name,
        avatar_url = excluded.avatar_url,
        updated_at = now();

    return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
    after insert on auth.users
    for each row
    execute function public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.entries enable row level security;

drop policy if exists "Users can read their own profile" on public.profiles;
create policy "Users can read their own profile"
    on public.profiles
    for select
    to authenticated
    using (auth.uid() = id);

drop policy if exists "Users can update their own profile" on public.profiles;
create policy "Users can update their own profile"
    on public.profiles
    for update
    to authenticated
    using (auth.uid() = id)
    with check (auth.uid() = id);

drop policy if exists "Users can insert their own entries" on public.entries;
create policy "Users can insert their own entries"
    on public.entries
    for insert
    to authenticated
    with check (auth.uid() = user_id);

drop policy if exists "Users can read their own entries" on public.entries;
create policy "Users can read their own entries"
    on public.entries
    for select
    to authenticated
    using (auth.uid() = user_id);

drop policy if exists "Users can update their own entries" on public.entries;
create policy "Users can update their own entries"
    on public.entries
    for update
    to authenticated
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

drop policy if exists "Users can delete their own entries" on public.entries;
create policy "Users can delete their own entries"
    on public.entries
    for delete
    to authenticated
    using (auth.uid() = user_id);
