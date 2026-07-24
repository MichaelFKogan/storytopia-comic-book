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

drop trigger if exists touch_journal_updated_at_from_entries on public.journal_entries;
create trigger touch_journal_updated_at_from_entries
    after insert or update or delete on public.journal_entries
    for each row
    execute function public.touch_journal_updated_at();
