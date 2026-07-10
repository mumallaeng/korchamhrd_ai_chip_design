# [일지] 코딩 (SystemVerilog 작성)

**Date:** YYYY-MM-DD  
**작업 유형:** 코딩

---

## 1) 작업 내용 (What I Did)

### 구현 범위 (Scope)
- 대상 모듈: `모듈명`
- 구현 목표: (한 줄 요약)
- 의존 모듈: `상위 모듈명`, `하위 모듈명`

### 구현 내용 요약
- 작성/수정 파일: `파일명.sv`
- 구현한 로직/블록:
  - FSM 상태: `IDLE → FETCH → EXEC → WRITE` *(해당 시)*
  - 주요 파라미터/매크로:
- 코딩 스타일 / 규칙 준수 사항:
  - [ ] `always_ff` / `always_comb` 구분 적용
  - [ ] 비동기 리셋 사용 여부: `있음 / 없음`
  - [ ] lint 경고 해소 여부

### 코드 스니펫 (핵심 로직)
```systemverilog
// 핵심 로직 요약 (전체 코드 아님)
always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n) state <= IDLE;
  else        state <= next_state;
end
```

### 미완료 / 다음 단계
- [ ] 항목

---

## 2) 회고 및 개선 사항

### Keep (잘한 점, 유지할 점)
-

### Try (새롭게 시도할 점, 개선할 점)
-

---

## 3) 이슈 및 해결 과정

### Trouble (이슈/장애 및 해결 과정)
| 구분 | 내용 |
|------|------|
| 문제 | 예: 합성 오류 — `latch inferred on signal X` |
| 원인 | |
| 해결 | |
| 참고 | |

---

## 4) 팀 토의 필요 사항
-

**참고자료:**
-
