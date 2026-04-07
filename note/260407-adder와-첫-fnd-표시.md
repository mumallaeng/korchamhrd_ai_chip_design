# 26-04-07 - Adder와 첫 FND 표시

## 한눈에 보기

| 항목 | 내용 |
| --- | --- |
| 목표 | half adder와 full adder를 carry chain으로 연결하는 감각을 잡는다 |
| 핵심 | `sum`, `carry`, 구조적 모델링, FND 숫자 표시 |
| 주의 | 현재 저장소의 `adder.v`는 수업 뒤 확장된 버전이라 8bit와 FND 연결까지 같이 들어 있다 |

## 관련 코드 위치

| 파일 | 위치 | 의미 |
| --- | --- | --- |
| `helloHDL/260407_adder/adder.srcs/sources_1/new/adder.v` | `107-145` | `half_adder`, `full_adder` 기본 구조 |
| `helloHDL/260407_adder/adder.srcs/sources_1/new/adder.v` | `64-105` | `full_adder_4bit` carry chain |
| `helloHDL/260407_adder/adder.srcs/sim_1/new/tb_adder_fnd.v` | `19-29` | 반복문으로 입력을 바꿔보는 testbench |
| `helloHDL/260407_adder/adder.srcs/sources_1/new/fnd_controller.v` | `165-193` | 4bit 값을 7-segment 코드로 변환 |

## 핵심 구조

| 항목 | 정리 |
| --- | --- |
| `half_adder` | `sum = a ^ b`, `carry = a & b` |
| `full_adder` | `half_adder` 두 개와 carry OR로 만들 수 있다 |
| `full_adder_4bit` | 하위 자리 carry를 다음 자리로 넘기며 연결한다 |
| FND 표시 | 숫자 계산 결과를 사람이 보기 좋은 7-segment 코드로 바꾼다 |

## 구조를 이렇게 읽으면 된다

```text
bit 단위 half/full adder
-> 4bit adder
-> 결과를 FND용 숫자 코드로 변환
-> 보드에서 값 확인
```

## 현재 저장소 기준으로 봐야 할 점

| 위치 | 읽는 포인트 |
| --- | --- |
| `adder.v:117-131` | `full_adder`가 두 개의 `half_adder`로 풀린다 |
| `adder.v:98-104` | `carry`가 다음 자리 `carry_in`으로 전달된다 |
| `tb_adder_fnd.v:22-27` | 이중 `for`문으로 여러 입력 조합을 순회한다 |

## 주의점

| 실수 | 정리 |
| --- | --- |
| `carry`를 overflow로만 본다 | adder 체인에서는 다음 자리 입력이다 |
| FND를 숫자 저장소로 본다 | FND는 표시 장치이고 내부 값은 따로 있다 |
| 현재 `adder.v`를 Day2 원본 그대로라고 본다 | 지금 파일은 나중 내용까지 합쳐진 확장본이다 |

## 다음 연결

- [[260408-8bit-adder와-fnd-controller]]
