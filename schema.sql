-- IT Arena: Supabase (Postgres) sxemasi. SQL Editor'ga qo'yib ishga tushiring.
create table teams(id serial primary key, name text unique not null);
create table profiles(
  id uuid primary key references auth.users on delete cascade,
  name text, avatar text, xp int default 0, score int default 0, streak int default 0,
  last_played date, team_id int references teams, premium bool default false,
  cards int default 0, free_used int default 0, free_date date, role text default 'student');
create table questions(
  id serial primary key, category text not null, level text check (level in ('e','m','h')),
  question text not null, options jsonb not null, correct int not null, author uuid references profiles);
create table results(id serial primary key, user_id uuid references profiles, category text, correct int, total int, played_at timestamptz default now());
create table mistakes(user_id uuid references profiles, question_id int references questions, primary key(user_id, question_id));
create table friendships(user_id uuid references profiles, friend_id uuid references profiles, status text default 'pending', primary key(user_id, friend_id));
create table matches(id serial primary key, mode text, category text, level text, created_at timestamptz default now());
create table match_players(match_id int references matches, user_id uuid references profiles, team int, score int default 0, primary key(match_id, user_id));
create table purchases(id serial primary key, user_id uuid references profiles, item text, amount_uzs int, status text default 'pending', created_at timestamptz default now());
create table quests(user_id uuid references profiles, day date, key text, progress int default 0, claimed bool default false, primary key(user_id, day, key));
create table achievements(user_id uuid references profiles, badge text, primary key(user_id, badge));
create table contests(id serial primary key, title text, prize text, ends_at timestamptz);
create table contest_entries(contest_id int references contests, user_id uuid references profiles, primary key(contest_id, user_id));
create table certificates(user_id uuid references profiles, category text, issued_at date default current_date, primary key(user_id, category));

create view weekly_leaderboard as
  select p.id, p.name, coalesce(sum(r.correct*10),0) as week_score
  from profiles p left join results r on r.user_id=p.id and r.played_at > now()-interval '7 days'
  group by p.id order by week_score desc;

alter table profiles enable row level security;
create policy "reyting hamma uchun" on profiles for select using (true);
create policy "o'zini yangilash" on profiles for update using (auth.uid()=id);
create policy "o'zini yaratish" on profiles for insert with check (auth.uid()=id);
alter table mistakes enable row level security;
create policy "o'z xatolari" on mistakes for all using (auth.uid()=user_id);
-- Eslatma: purchases, premium va cards ni faqat server (Edge Function) o'zgartirsin, klient emas.
