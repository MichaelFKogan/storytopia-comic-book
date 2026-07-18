alter table public.entries
add column if not exists client_entry_id uuid;

update public.entries
set client_entry_id = gen_random_uuid()
where client_entry_id is null;

alter table public.entries
alter column client_entry_id set not null;

alter table public.entries
drop constraint if exists entries_user_client_entry_id_key;

alter table public.entries
add constraint entries_user_client_entry_id_key
unique (user_id, client_entry_id);

alter table public.entries
drop constraint if exists entries_status_check;

alter table public.entries
add constraint entries_status_check
check (status in ('draft', 'completed', 'archived'));
