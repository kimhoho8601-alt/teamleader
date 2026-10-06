# 팀장 인터뷰 · Live Conversation Workspace

아동보호사업부문 팀장 인터뷰를 위한 모바일 우선 상호작용형 워크숍 페이지입니다.

## 핵심 구성

- 레드 기반 풀스크린 히어로와 대형 원형 모티프
- `SCENE → DIFFICULTY → SUPPORT` 3단계 대화 흐름
- 참가자 답변 입력·수정
- 진행자용 실시간 대화 월
- 진행자가 현재 질문 전환 / 응답 접수 열기·닫기
- Q1/Q2/Q3 필터
- 닉네임 선택 또는 익명 참여
- 한국어 `word-break: keep-all`, 반응형 타이포그래피, reduced-motion 지원

## 사용 방법

### 진행자
`index.html?mode=host`로 접속합니다. 세션 코드가 자동 생성됩니다. `참여 링크 복사` 버튼으로 참가자에게 공유할 수 있습니다.

### 참가자
진행자가 공유한 링크로 접속하거나 세션 코드를 직접 입력합니다.

## 실시간 모드

### 기본 데모
`config.js`의 Supabase 설정이 비어 있으면 로컬 데모 모드로 동작합니다. 같은 브라우저의 여러 탭은 `BroadcastChannel`과 `localStorage`로 즉시 동기화됩니다.

### 여러 기기 실시간 연동
전용 Supabase 프로젝트에 `supabase.sql`을 적용한 뒤 `config.js`에 프로젝트 URL과 publishable/anon key를 넣으면 여러 휴대폰과 PC 사이에서 동기화됩니다.

```js
window.TEAMLEADER_CONFIG = {
  supabaseUrl: 'https://YOUR_PROJECT_REF.supabase.co',
  supabaseAnonKey: 'YOUR_PUBLISHABLE_OR_ANON_KEY'
};
```

테이블 직접 접근은 RLS로 막고 필요한 동작만 RPC 함수로 열어 두었습니다.

## GitHub Pages
`.github/workflows/pages.yml`을 사용합니다. 저장소 Settings → Pages에서 Source를 **GitHub Actions**로 지정하면 이후 `main` 브랜치 변경 시 자동 배포됩니다.


## 진행자 인증 보안 설정 (2026-10-06)

진행자 화면은 코드를 직접 입력하고 서버의 `authenticate_workshop_host` 검증이 성공한 뒤에만 대기화면·진행 도구를 불러옵니다. 진행자 코드를 HTML, URL, localStorage에 저장하지 않습니다.

**서버 설정 적용이 반드시 필요합니다.** 현재 teamleader 프로젝트가 일시 중지되어 서버에 아래 설정을 적용하지 못했습니다. GitHub 화면 수정만으로 과거에 공개된 서버 키가 폐기되는 것은 아닙니다.

1. Supabase에서 teamleader 프로젝트를 복원합니다. 활성 무료 프로젝트가 2개라면 요금제/프로젝트 운영 계획을 먼저 결정해야 합니다.
2. 해당 프로젝트 SQL Editor에서 [security_setup.sql](security_setup.sql) 전체를 실행합니다. 기존 진행자 키를 모두 폐기하고 새 임의 코드를 생성합니다. 인터뷰 기록은 삭제하지 않습니다.
3. SQL 실행 결과의 `new_private_host_code`를 비공개로 보관하고 진행자 화면에서 입력합니다. 결과를 GitHub, URL, 공개 문서에 넣지 않습니다.
4. 잘못된 코드가 거부되고 새 코드로 진행자 대기화면에 진입하는지 확인합니다. 기존 코드도 반드시 거부되어야 합니다.

서버가 복원되었더라도 SQL을 실행하기 전에는 기존 키가 남아 있을 수 있습니다. 인증 RPC가 없거나 오류가 발생하면 새 진행자 화면은 진입을 차단합니다.

참가자 화면의 공개 응답 공유는 유지됩니다. 기밀 면담 기록을 수집하는 용도로 사용하려면 별도 참가자 인증과 데이터 공개 범위 설계가 필요합니다.

검증: `node tests/host-security.cjs` (서버 오류/잘못된 코드 차단, 서버 승인 후 진입, 코드 입력값 제거, 실패한 상태 변경 차단).
