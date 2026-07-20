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

-- 3) 관리자 조회 권한 (admin.html은 Authentication 관리자 계정 로그인 방식)
--    ※ 새 Supabase의 Secret 키는 브라우저에서 401을 반환하도록 설계되어 있어
--       관리자 페이지는 이메일 로그인(authenticated 역할)으로 조회한다.
create policy "admin read entries" on entries
  for select to authenticated using (true);

create policy "admin read captures" on storage.objects
  for select to authenticated using (bucket_id = 'captures');

-- 4) 팔로우 사후 검증 (관리자가 인스타 팔로워 목록과 대조해 ✓/✗ 판정)
--    verified: null=미검증, true=팔로우 확인됨, false=허위 체크
alter table entries add column if not exists verified boolean;

create policy "admin update entries" on entries
  for update to authenticated using (true) with check (true);
