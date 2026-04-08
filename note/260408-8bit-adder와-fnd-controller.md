# 26-04-08 - 8bit Adder와 FND Controller

## 한눈에 보기

| 항목 | 내용 |
| --- | --- |
| 목표 | adder 결과를 4자리 FND에 동적으로 스캔해서 표시하는 구조를 이해한다 |
| 핵심 | `adder_fnd`, `full_adder_8bit`, `digit_splitter`, `mux`, `decoder`, `bcd` |
| 실습 구조 | `adder`는 계산, `fnd_controller`는 표시 담당이다 |

## 관련 코드 위치

| 파일 | 위치 | 의미 |
| --- | --- | --- |
| `helloHDL/260407_adder/adder.srcs/sources_1/new/adder.v` | `3-35` | `adder_fnd` top, carry 포함 9bit 값 구성 |
| `helloHDL/260407_adder/adder.srcs/sources_1/new/adder.v` | `37-60` | `full_adder_8bit` |
| `helloHDL/260407_adder/adder.srcs/sources_1/new/fnd_controller.v` | `13-64` | `digit_splitter -> mux -> bcd -> decoder` 연결 |
| `helloHDL/260407_adder/adder.srcs/sources_1/new/fnd_controller.v` | `67-88` | 1kHz 분주 |
| `helloHDL/260407_adder/adder.srcs/sources_1/new/fnd_controller.v` | `110-123` | active-low FND enable |

## 전체 구조

```text
a, b
-> 8bit adder
-> carry 포함 결과값
-> digit_splitter
-> mux_4x1
-> bcd
-> decoder_2x4
-> FND
```

## 블록별 역할

| 블록 | 역할 |
| --- | --- |
| `full_adder_8bit` | 4bit adder 두 개를 이어 8bit 덧셈 수행 |
| `digit_splitter` | 값을 1, 10, 100, 1000의 자리로 분리 |
| `mux_4x1` | 지금 표시할 자리 하나만 선택 |
| `decoder_2x4` | 어떤 FND digit를 켤지 결정 |
| `bcd` | 선택된 4bit 값을 7-segment 코드로 변환 |

## 코드에서 꼭 읽을 줄

| 위치 | 읽는 포인트 |
| --- | --- |
| `adder.v:17-24` | carry를 포함한 `w_sum_value`를 만들어 FND로 넘긴다 |
| `fnd_controller.v:48-63` | 분주기와 2bit 카운터로 자리를 순환 선택한다 |
| `fnd_controller.v:115-123` | `1110, 1101, 1011, 0111`은 active-low 자리 선택이다 |
| `fnd_controller.v:172-193` | `bcd_data`는 숫자 자체가 아니라 segment 패턴이다 |

## 주의점

| 실수 | 정리 |
| --- | --- |
| FND 네 자리를 동시에 다 켠다고 본다 | 실제로는 빠르게 번갈아 켠다 |
| `digit_splitter`를 그냥 수학식으로만 본다 | 합성 뒤에는 실제 하드웨어 구조가 된다 |
| `bcd`를 decimal 저장소로 본다 | `bcd_data`는 표시 패턴이다 |

## 다음 연결

- [[260409-합성-구조-확장-fnd-시스템]]
