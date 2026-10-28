-- BrandFlux database. Supabase > SQL Editor > New query > paste ALL > Run.
create table public.profiles(id uuid primary key references auth.users on delete cascade, full_name text, is_admin boolean not null default false);
alter table public.profiles enable row level security;
create policy "read own profile" on public.profiles for select to authenticated using (id = auth.uid());
create function public.is_admin() returns boolean language sql security definer stable set search_path='' as $$ select coalesce((select is_admin from public.profiles where id=auth.uid()),false) $$;
create function public.handle_new_user() returns trigger language plpgsql security definer set search_path='' as $$ begin insert into public.profiles(id,full_name) values(new.id,new.raw_user_meta_data->>'full_name'); return new; end $$;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();

create table public.orders(
 id uuid primary key default gen_random_uuid(),
 ref text not null unique default 'BF-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,7)),
 user_id uuid not null default auth.uid() references auth.users on delete cascade,
 customer_name text not null check(char_length(customer_name) between 1 and 120),
 email text not null check(char_length(email)<=200),
 whatsapp text check(char_length(whatsapp)<=40),
 product_name text not null check(char_length(product_name) between 1 and 160),
 category text not null check(char_length(category)<=60),
 package_name text not null check(char_length(package_name)<=60),
 package_price text not null check(char_length(package_price)<=60),
 duration text not null check(char_length(duration)<=40),
 description text not null check(char_length(description) between 1 and 4000),
 style text not null check(char_length(style)<=300),
 reference_url text check(char_length(reference_url)<=500),
 image_path text check(char_length(image_path)<=300), logo_path text check(char_length(logo_path)<=300),
 extra_notes text check(char_length(extra_notes)<=2000),
 status text not null default 'Pending' check(status in ('Pending','Accepted','In Progress','Revision Requested','Completed','Cancelled')),
 final_price text check(char_length(final_price)<=60), delivery_link text check(char_length(delivery_link)<=500),
 created_at timestamptz not null default now());
alter table public.orders enable row level security;
create policy "see own or admin" on public.orders for select to authenticated using (user_id=auth.uid() or public.is_admin());
create policy "create own pending" on public.orders for insert to authenticated with check (user_id=auth.uid() and status='Pending' and final_price is null and delivery_link is null);
create policy "admin updates" on public.orders for update to authenticated using (public.is_admin()) with check (public.is_admin());

create table public.order_notes(order_id uuid primary key references public.orders on delete cascade, note text check(char_length(note)<=4000));
alter table public.order_notes enable row level security;
create policy "admin only" on public.order_notes for all to authenticated using (public.is_admin()) with check (public.is_admin());

create table public.messages(id bigint generated always as identity primary key, order_id uuid not null references public.orders on delete cascade, sender_id uuid references auth.users, is_system boolean not null default false, body text not null check(char_length(body) between 1 and 2000), created_at timestamptz not null default now());
alter table public.messages enable row level security;
create policy "read order chat" on public.messages for select to authenticated using (public.is_admin() or exists(select 1 from public.orders o where o.id=order_id and o.user_id=auth.uid()));
create policy "write order chat" on public.messages for insert to authenticated with check (sender_id=auth.uid() and is_system=false and (public.is_admin() or exists(select 1 from public.orders o where o.id=order_id and o.user_id=auth.uid())));

create function public.order_events() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if tg_op='INSERT' then insert into public.messages(order_id,is_system,body) values(new.id,true,'Order submitted. BrandFlux will review it and reply here.');
 else
  if new.status is distinct from old.status then insert into public.messages(order_id,is_system,body) values(new.id,true,'Status updated to '||new.status||'.'); end if;
  if new.final_price is distinct from old.final_price and new.final_price is not null then insert into public.messages(order_id,is_system,body) values(new.id,true,'Final price: '||new.final_price); end if;
  if new.delivery_link is distinct from old.delivery_link and new.delivery_link is not null then insert into public.messages(order_id,is_system,body) values(new.id,true,'Your ad is ready: '||new.delivery_link); end if;
 end if; return new; end $$;
create trigger order_events after insert or update on public.orders for each row execute function public.order_events();

create table public.portfolio_videos(id uuid primary key default gen_random_uuid(), title text not null check(char_length(title)<=160), url text not null check(char_length(url)<=500), created_at timestamptz not null default now());
alter table public.portfolio_videos enable row level security;
create policy "public read" on public.portfolio_videos for select to anon, authenticated using (true);
create policy "admin insert" on public.portfolio_videos for insert to authenticated with check (public.is_admin());
create policy "admin update" on public.portfolio_videos for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "admin delete" on public.portfolio_videos for delete to authenticated using (public.is_admin());

create table public.packages(id int generated always as identity primary key, name text not null, price_label text not null, duration text not null, features text[] not null default '{}', featured boolean not null default false, sort int not null default 0);
alter table public.packages enable row level security;
create policy "public read" on public.packages for select to anon, authenticated using (true);
create policy "admin write" on public.packages for all to authenticated using (public.is_admin()) with check (public.is_admin());
insert into public.packages(name,price_label,duration,features,featured,sort) values
('Starter Ad','PKR 1,000','10–15 seconds',array['10–15 second AI product advertisement','Suitable for a simple product promotion','One agreed visual concept'],false,1),
('Premium Ad','PKR 2,500','20–30 seconds',array['20–30 second AI product advertisement','More detailed cinematic scenes','Suitable for social media product promotion'],true,2),
('Pro Ad','Starting from PKR 5,000','30–45 seconds',array['30–45 second premium product advertisement','More advanced visual storytelling','Custom creative direction'],false,3);

create table public.contact_messages(id bigint generated always as identity primary key, name text not null check(char_length(name) between 1 and 120), email text not null check(char_length(email) between 3 and 200), message text not null check(char_length(message) between 1 and 3000), created_at timestamptz not null default now());
alter table public.contact_messages enable row level security;
create policy "anyone can send" on public.contact_messages for insert to anon, authenticated with check (true);
create policy "admin reads" on public.contact_messages for select to authenticated using (public.is_admin());

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('order-files','order-files',false,5242880,array['image/jpeg','image/png','image/webp']) on conflict (id) do nothing;
create policy "upload to own folder" on storage.objects for insert to authenticated with check (bucket_id='order-files' and (storage.foldername(name))[1]=auth.uid()::text);
create policy "read own or admin files" on storage.objects for select to authenticated using (bucket_id='order-files' and ((storage.foldername(name))[1]=auth.uid()::text or public.is_admin()));

alter publication supabase_realtime add table public.messages, public.orders;
