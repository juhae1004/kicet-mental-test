-- KICET 멘탈 내열 테스트 — Supabase 세팅 (SQL Editor에 붙여넣고 Run)
-- 구조: 익명 사용자는 응모 INSERT만 가능, 조회는 관리자(service_role)만 가능

-- 1) 응모 테이블
create table if not exists entries (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  name text not null,
  phone text not null unique,          -- 연락처 중복 응모 방지 (재응모 시 409)
  follow boolean not null default false,
  type text,                           -- uju | phone | jubang | momsok
  temp text,                           -- 1,600℃ 등
  capture_path text                    -- captures 버킷 내 파일 경로
);

alter table entries enable row level security;

-- 익명(랜딩페이지)은 쓰기만 허용, 읽기 정책 없음 → 외부에서 응모 내역 조회 불가
create policy "anon insert only" on entries
  for insert to anon with check (true);

-- 2) 캡쳐 이미지 버킷 (비공개 — 관리자 페이지가 서명 URL로만 열람)
insert into storage.buckets (id, name, public)
  values ('captures', 'captures', false)
  on conflict (id) do nothing;

create policy "anon upload captures" on storage.objects
  for insert to anon with check (bucket_id = 'captures');
