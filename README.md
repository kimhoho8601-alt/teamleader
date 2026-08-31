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
