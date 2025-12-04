-- Enable Realtime for availability_blocks and staff_tasks tables

-- Enable Realtime for availability_blocks
do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'availability_blocks' and schemaname = 'public') then
    alter publication supabase_realtime add table public.availability_blocks;
  end if;
end;
$$;

-- Enable Realtime for staff_tasks
do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'staff_tasks' and schemaname = 'public') then
    alter publication supabase_realtime add table public.staff_tasks;
  end if;
end;
$$;


