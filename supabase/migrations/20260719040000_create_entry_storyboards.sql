insert into storage.buckets (id, name, public)
values ('generated-storyboards', 'generated-storyboards', false)
on conflict (id) do update
set public = false;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

create table if not exists public.entry_storyboards (
    id uuid primary key,
    user_id uuid not null references auth.users(id) on delete cascade,
    client_entry_id uuid not null,
    storage_path text not null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    art_style text,
    panel_layout text,
    prompt text,
    is_primary boolean not null default true,
    generation_status text not null default 'completed',
    constraint entry_storyboards_storage_path_key unique (user_id, storage_path),
    constraint entry_storyboards_generation_status_check
        check (generation_status in ('completed', 'failed', 'pending'))
);

do $$
begin
    if not exists (
        select 1
        from pg_constraint
        where conname = 'entry_storyboards_user_client_entry_id_fkey'
    ) then
        alter table public.entry_storyboards
        add constraint entry_storyboards_user_client_entry_id_fkey
        foreign key (user_id, client_entry_id)
        references public.entries (user_id, client_entry_id)
        on delete cascade;
    end if;
end $$;

create index if not exists entry_storyboards_user_client_entry_created_at_idx
    on public.entry_storyboards (user_id, client_entry_id, created_at desc);

create index if not exists entry_storyboards_user_client_entry_primary_idx
    on public.entry_storyboards (user_id, client_entry_id, is_primary);

drop trigger if exists set_entry_storyboards_updated_at on public.entry_storyboards;
create trigger set_entry_storyboards_updated_at
    before update on public.entry_storyboards
    for each row
    execute function public.set_updated_at();

alter table public.entry_storyboards enable row level security;

drop policy if exists "Users can read their own storyboards" on public.entry_storyboards;
create policy "Users can read their own storyboards"
    on public.entry_storyboards
    for select
    to authenticated
    using (auth.uid() = user_id);

drop policy if exists "Users can insert their own storyboards" on public.entry_storyboards;
create policy "Users can insert their own storyboards"
    on public.entry_storyboards
    for insert
    to authenticated
    with check (auth.uid() = user_id);

drop policy if exists "Users can update their own storyboards" on public.entry_storyboards;
create policy "Users can update their own storyboards"
    on public.entry_storyboards
    for update
    to authenticated
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

drop policy if exists "Users can delete their own storyboards" on public.entry_storyboards;
create policy "Users can delete their own storyboards"
    on public.entry_storyboards
    for delete
    to authenticated
    using (auth.uid() = user_id);

drop policy if exists "Users can read their own generated storyboards" on storage.objects;
create policy "Users can read their own generated storyboards"
    on storage.objects
    for select
    to authenticated
    using (
        bucket_id = 'generated-storyboards'
        and (storage.foldername(name))[1] = auth.uid()::text
    );

drop policy if exists "Users can insert their own generated storyboards" on storage.objects;
create policy "Users can insert their own generated storyboards"
    on storage.objects
    for insert
    to authenticated
    with check (
        bucket_id = 'generated-storyboards'
        and (storage.foldername(name))[1] = auth.uid()::text
    );

drop policy if exists "Users can update their own generated storyboards" on storage.objects;
create policy "Users can update their own generated storyboards"
    on storage.objects
    for update
    to authenticated
    using (
        bucket_id = 'generated-storyboards'
        and (storage.foldername(name))[1] = auth.uid()::text
    )
    with check (
        bucket_id = 'generated-storyboards'
        and (storage.foldername(name))[1] = auth.uid()::text
    );

drop policy if exists "Users can delete their own generated storyboards" on storage.objects;
create policy "Users can delete their own generated storyboards"
    on storage.objects
    for delete
    to authenticated
    using (
        bucket_id = 'generated-storyboards'
        and (storage.foldername(name))[1] = auth.uid()::text
    );
