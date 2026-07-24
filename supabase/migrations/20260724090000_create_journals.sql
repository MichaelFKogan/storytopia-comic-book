insert into storage.buckets (id, name, public)
values ('journal-covers', 'journal-covers', false)
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

create or replace function public.touch_journal_updated_at()
returns trigger
language plpgsql
as $$
begin
    if tg_op = 'DELETE' then
        update public.journals
        set updated_at = now()
        where user_id = old.user_id
          and id = old.journal_id;

        return old;
    end if;

    update public.journals
    set updated_at = now()
    where user_id = new.user_id
      and id = new.journal_id;

    return new;
end;
$$;

create table if not exists public.journals (
    id uuid not null,
    user_id uuid not null references auth.users(id) on delete cascade,
    title text not null,
    subtitle text,
    color_hex text,
    symbol text,
    cover_storage_path text,
    kind text not null default 'journal',
    is_favorite boolean not null default false,
    display_order integer not null default 0,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    primary key (user_id, id),
    constraint journals_kind_check check (kind in ('journal', 'storyboard')),
    constraint journals_title_check check (nullif(btrim(title), '') is not null)
);

create table if not exists public.journal_entries (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    journal_id uuid not null,
    client_entry_id uuid not null,
    position integer not null default 0,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint journal_entries_journal_fkey
        foreign key (user_id, journal_id)
        references public.journals (user_id, id)
        on delete cascade,
    constraint journal_entries_entry_fkey
        foreign key (user_id, client_entry_id)
        references public.entries (user_id, client_entry_id)
        on delete cascade,
    constraint journal_entries_user_journal_entry_key unique (user_id, journal_id, client_entry_id)
);

create index if not exists journals_user_display_order_idx
    on public.journals (user_id, display_order, created_at desc);

create index if not exists journal_entries_user_journal_position_idx
    on public.journal_entries (user_id, journal_id, position);

create index if not exists journal_entries_user_entry_idx
    on public.journal_entries (user_id, client_entry_id);

drop trigger if exists set_journals_updated_at on public.journals;
create trigger set_journals_updated_at
    before update on public.journals
    for each row
    execute function public.set_updated_at();

drop trigger if exists set_journal_entries_updated_at on public.journal_entries;
create trigger set_journal_entries_updated_at
    before update on public.journal_entries
    for each row
    execute function public.set_updated_at();

drop trigger if exists touch_journal_updated_at_from_entries on public.journal_entries;
create trigger touch_journal_updated_at_from_entries
    after insert or update or delete on public.journal_entries
    for each row
    execute function public.touch_journal_updated_at();

alter table public.journals enable row level security;
alter table public.journal_entries enable row level security;

drop policy if exists "Users can read their own journals" on public.journals;
create policy "Users can read their own journals"
    on public.journals
    for select
    to authenticated
    using (auth.uid() = user_id);

drop policy if exists "Users can insert their own journals" on public.journals;
create policy "Users can insert their own journals"
    on public.journals
    for insert
    to authenticated
    with check (auth.uid() = user_id);

drop policy if exists "Users can update their own journals" on public.journals;
create policy "Users can update their own journals"
    on public.journals
    for update
    to authenticated
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

drop policy if exists "Users can delete their own journals" on public.journals;
create policy "Users can delete their own journals"
    on public.journals
    for delete
    to authenticated
    using (auth.uid() = user_id);

drop policy if exists "Users can read their own journal entries" on public.journal_entries;
create policy "Users can read their own journal entries"
    on public.journal_entries
    for select
    to authenticated
    using (auth.uid() = user_id);

drop policy if exists "Users can insert their own journal entries" on public.journal_entries;
create policy "Users can insert their own journal entries"
    on public.journal_entries
    for insert
    to authenticated
    with check (auth.uid() = user_id);

drop policy if exists "Users can update their own journal entries" on public.journal_entries;
create policy "Users can update their own journal entries"
    on public.journal_entries
    for update
    to authenticated
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

drop policy if exists "Users can delete their own journal entries" on public.journal_entries;
create policy "Users can delete their own journal entries"
    on public.journal_entries
    for delete
    to authenticated
    using (auth.uid() = user_id);

drop policy if exists "Users can read their own journal covers" on storage.objects;
create policy "Users can read their own journal covers"
    on storage.objects
    for select
    to authenticated
    using (
        bucket_id = 'journal-covers'
        and (storage.foldername(name))[1] = auth.uid()::text
    );

drop policy if exists "Users can insert their own journal covers" on storage.objects;
create policy "Users can insert their own journal covers"
    on storage.objects
    for insert
    to authenticated
    with check (
        bucket_id = 'journal-covers'
        and (storage.foldername(name))[1] = auth.uid()::text
    );

drop policy if exists "Users can update their own journal covers" on storage.objects;
create policy "Users can update their own journal covers"
    on storage.objects
    for update
    to authenticated
    using (
        bucket_id = 'journal-covers'
        and (storage.foldername(name))[1] = auth.uid()::text
    )
    with check (
        bucket_id = 'journal-covers'
        and (storage.foldername(name))[1] = auth.uid()::text
    );

drop policy if exists "Users can delete their own journal covers" on storage.objects;
create policy "Users can delete their own journal covers"
    on storage.objects
    for delete
    to authenticated
    using (
        bucket_id = 'journal-covers'
        and (storage.foldername(name))[1] = auth.uid()::text
    );
