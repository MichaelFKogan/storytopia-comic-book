insert into storage.buckets (id, name, public)
values ('storytopia-media', 'storytopia-media', false)
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

create table if not exists public.entry_reference_photos (
    id uuid primary key,
    user_id uuid not null references auth.users(id) on delete cascade,
    entry_id uuid not null references public.entries(id) on delete cascade,
    client_entry_id uuid not null,
    storage_path text not null,
    mime_type text not null,
    byte_size bigint not null,
    width integer not null,
    height integer not null,
    sort_order integer not null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint entry_reference_photos_storage_path_key unique (user_id, storage_path)
);

create index if not exists entry_reference_photos_user_entry_sort_order_idx
    on public.entry_reference_photos (user_id, entry_id, sort_order);

create index if not exists entry_reference_photos_user_client_entry_sort_order_idx
    on public.entry_reference_photos (user_id, client_entry_id, sort_order);

drop trigger if exists set_entry_reference_photos_updated_at on public.entry_reference_photos;
create trigger set_entry_reference_photos_updated_at
    before update on public.entry_reference_photos
    for each row
    execute function public.set_updated_at();

alter table public.entry_reference_photos enable row level security;

drop policy if exists "Users can read their own reference photos" on public.entry_reference_photos;
create policy "Users can read their own reference photos"
    on public.entry_reference_photos
    for select
    to authenticated
    using (auth.uid() = user_id);

drop policy if exists "Users can insert their own reference photos" on public.entry_reference_photos;
create policy "Users can insert their own reference photos"
    on public.entry_reference_photos
    for insert
    to authenticated
    with check (auth.uid() = user_id);

drop policy if exists "Users can update their own reference photos" on public.entry_reference_photos;
create policy "Users can update their own reference photos"
    on public.entry_reference_photos
    for update
    to authenticated
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

drop policy if exists "Users can delete their own reference photos" on public.entry_reference_photos;
create policy "Users can delete their own reference photos"
    on public.entry_reference_photos
    for delete
    to authenticated
    using (auth.uid() = user_id);

drop policy if exists "Users can read their own storytopia media" on storage.objects;
create policy "Users can read their own storytopia media"
    on storage.objects
    for select
    to authenticated
    using (
        bucket_id = 'storytopia-media'
        and (storage.foldername(name))[1] = auth.uid()::text
    );

drop policy if exists "Users can insert their own storytopia media" on storage.objects;
create policy "Users can insert their own storytopia media"
    on storage.objects
    for insert
    to authenticated
    with check (
        bucket_id = 'storytopia-media'
        and (storage.foldername(name))[1] = auth.uid()::text
    );

drop policy if exists "Users can update their own storytopia media" on storage.objects;
create policy "Users can update their own storytopia media"
    on storage.objects
    for update
    to authenticated
    using (
        bucket_id = 'storytopia-media'
        and (storage.foldername(name))[1] = auth.uid()::text
    )
    with check (
        bucket_id = 'storytopia-media'
        and (storage.foldername(name))[1] = auth.uid()::text
    );

drop policy if exists "Users can delete their own storytopia media" on storage.objects;
create policy "Users can delete their own storytopia media"
    on storage.objects
    for delete
    to authenticated
    using (
        bucket_id = 'storytopia-media'
        and (storage.foldername(name))[1] = auth.uid()::text
    );
