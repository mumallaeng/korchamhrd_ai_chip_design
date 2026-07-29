# 논리회로 시험 대비 03 - 조합논리에서 순차논리로

> 분류: 2026-04-06부터 2026-05-29까지의 Korcham 수업·시험 범위에 종속된 activity note

목적:
- `gate -> 조합논리 -> flip-flop -> clock -> register -> counter -> FSM` 흐름만 짧게 연결
- 지금 막히기 쉬운 `기억` 개념을 한 번에 고정

연결 노트:
- [[activities/korcham/notes/260406-260529-논리회로-시험대비/study-exam-01-prerequisite-logic-gates-and-symbols]]
- [[activities/korcham/notes/260406-260529-논리회로-시험대비/study-exam-02-gate-to-combinational-logic-bridge]]
- [[activities/korcham/notes/260406-260529-논리회로-시험대비/study-exam-05-counter-timer-counter-register]]

## 현재 단계 체크

- `gate`: 이해 시작
- `flip-flop / clock / register / counter`: 아직 연결 전
- 이 상태는 정상이다. 다음 핵심은 `기억`이다.

## 전체 구분

| 분야 | 핵심 |
| --- | --- |
| `조합논리` | 기억 없음, 현재 입력만 사용 |
| `순차논리` | 기억 있음, 이전 상태를 함께 사용 |

## 조합논리

- 현재 입력만 사용
- 입력이 바뀌면 출력도 바로 바뀜
- 예: `AND`, `OR`, `XOR`, `adder`, `MUX`

```text
현재 입력
-> 계산
-> 현재 출력
```

## 순차논리

- 이전 값을 저장해 두고 다음 동작을 결정
- 여기서 `flip-flop`, `clock`, `register`, `counter`가 등장

```text
현재 입력 + 이전 상태
-> 다음 값 계산
-> 저장
```

## 기억은 어디에 저장하나

| 개념 | 역할 |
| --- | --- |
| `flip-flop` | `1bit` 저장 |
| `register` | `flip-flop` 여러 개를 묶은 저장 블록 |
| `state` | register에 저장된 현재 값 |

## clock

- `clock`은 저장 시점을 정하는 기준 신호
- 보통 `0 -> 1 -> 0 -> 1` 반복
- `tick`은 상태가 한 번 업데이트되는 순간으로 보면 된다

## counter

`counter`는 `tick`마다 값이 바뀌는 `register`다.

```text
현재값 저장(register)
-> +1 또는 -1 계산
-> 다음 tick에서 저장
-> 반복
```

## 한 줄 연결

| 개념 | 역할 |
| --- | --- |
| `gate` | 논리연산 |
| `조합논리` | 기억 없는 계산 |
| `flip-flop` | `1bit` 기억 |
| `clock` | 저장 시점 결정 |
| `register` | 여러 bit 기억 |
| `counter` | tick마다 값 변화 |
| `FSM` | 상태에 따라 동작 결정 |

## 지금 할 일

1. `gate`
2. `조합논리`
3. `기억`
4. `flip-flop -> clock -> register -> counter`

`gate`와 `조합논리`가 안정되면, 그 다음부터는 `회로가 값을 기억한다`는 생각으로 넘어가면 된다.
