alter table public.entries
add column if not exists rich_text jsonb,
add column if not exists art_style text,
add column if not exists location text,
add column if not exists entry_date timestamptz,
add column if not exists date_precision text,
add column if not exists saves_draft boolean,
add column if not exists is_private boolean,
add column if not exists font_choice_raw_value text,
add column if not exists text_color_index integer,
add column if not exists text_size double precision,
add column if not exists paper_style_raw_value text,
add column if not exists paper_color_index integer,
add column if not exists is_bold boolean,
add column if not exists is_italic boolean,
add column if not exists is_underlined boolean,
add column if not exists is_strikethrough boolean,
add column if not exists is_highlighted boolean,
add column if not exists text_alignment_raw_value text;

alter table public.entries
drop constraint if exists entries_date_precision_check;

alter table public.entries
add constraint entries_date_precision_check
check (
    date_precision is null
    or date_precision in ('noDate', 'exact', 'dateOnly', 'monthAndYear', 'yearOnly')
);
