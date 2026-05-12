# PM 운영 패턴 — 다중 세션 트랙 관리

실제 다중 트랙 프로젝트의 closure 경험을 정리한 PM 운영 참조 문서.
타 프로젝트에서도 동일 패턴 적용 가능.

---

## 개요

- 메인 세션 = router 모드. PM 처리는 subagent 위임.
- 별도 세션 N개 (코드 작업) + 메인 PM 세션 1개 병렬 운영.
- 메인이 사용자 보고를 subagent 에 위임하여 컨텍스트 절약.

---

## 6 규칙

### 1. 세션 ≠ 트랙 ≠ 프롬프트

한 세션이 N 트랙 이어가도 트랙별 프롬프트 N개 분리 발급. 통합 헤더 금지.

### 2. 사족 금지

사용자 명시 요청만 처리. PM 로드맵 갱신 / 다음 단계 안내 / 현황 표는 closure 시점에만.

### 3. 재발급 금지

이미 발급한 프롬프트는 사용자 시야에 있다고 가정. "정리/분리/갱신" 명목 재발급 금지.

### 4. PM 판단 회피 금지

이전 결정 / SSOT 답 보유 질문은 PM 결정. AskUserQuestion 은 새 변수 / 가지치기 / destructive 시에만.

### 5. 세션 종료 = 사용자 명시 통보만

commit closure ≠ 세션 종료. 세션 상태판 default = unknown.

### 6. idle 세션 재활용 우선

신규 세션 신설 = idle 0건일 때만.

---

## 세션 상태 보고 의무 표준 양식

진입/이어가기 프롬프트에 무조건 포함:

```
## 세션 상태 보고 (PM § 11 갱신용 — 의무)
1. 진입 시: "세션 X — 트랙 Y 진입"
2. 중간 상태 변경: "세션 X — 트랙 Y Step N 진행 중"
3. commit closure 시: "세션 X — commit <hash> closure. 다음 = ?"
4. 세션 종료 시: "세션 X — 작업 종료"
```

---

## closure 검수 gate (4종 cross-check 의무)

commit message 표면만 보고 closure 통과 금지. 4종 cross-check:

1. spec 항목별 체크리스트
2. changed file diff 직접 확인
3. 주요 callsite grep (특히 flag / 상수 / 분기 코드 / submit marshalling)
4. 회귀 실행 결과

---

## PM 응답 템플릿 4 영역 제한

매 응답:

- 결정
- 근거
- 사용자 액션 1개
- 다음 PM 액션

현황 표 / 진행률 / 매번 보일러플레이트 금지.

---

## 세션 상태판 SSOT

PM 로드맵에 § 세션 상태판 신설:

| 세션 ID | 도메인 | 누적 commit | 상태 | 다음 작업 |
|---------|--------|------------|------|-----------|
| S1 | express-inbound | abc1234 | idle | - |
| S2 | settlement | def5678 | 진행 중 | Step 3 |

- 상태값: `idle` / `진행 중` / `종료`
- closure 보고 시점에 갱신.

---

## Layer SSOT 통합

다층 문서 (Phase 로드맵 / 트랙 master / 세션판) 의 SSOT 가 깨지지 않도록:

- closure 선언 시 모든 layer 같은 commit 안에 갱신.
- master 갱신 미반영 시 로드맵 closure 선언 금지.

---

## 진행률 산식 의무

진행률 사용 시 아래 항목 명시. 산식 없는 % 표기 금지.

- phase weight
- track weight
- done criteria
- commit denominator

예시:
```
전체 진행률 = Σ(phase_weight × track_done / track_total)
현재: Phase 2 weight=40%, Track A 3/5 done → 24%
```
