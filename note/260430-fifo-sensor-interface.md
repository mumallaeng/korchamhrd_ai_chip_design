# 26-04-30 - FIFO 제어, 시뮬레이션 스케줄, 센서 인터페이스

## 한눈에 보기

| 항목 | 내용 |
| --- | --- |
| 주제 | FIFO 제어, blocking/nonblocking, SR04, DHT11 |
| 목표 | 저장 구조와 시간 기반 센서 인터페이스를 함께 이해 |
| 핵심 | `fifo`, `tb_practice_1`, `sr04`, `dht11` |

## 관련 코드 위치

| 파일 | 위치 | 의미 |
| --- | --- | --- |
| `helloHDL/260506_remip/remip.srcs/sources_1/new/fifo.v` | `43-63` | `register_file`, 주소 기반 저장 구조 |
| `helloHDL/260506_remip/remip.srcs/sources_1/new/fifo.v` | `67-149` | `wptr`, `rptr`, `full`, `empty` 제어 |
| `helloHDL/260415_practice_misc/practice.srcs/sim_1/new/tb_practice_1.v` | `10-24` | blocking vs nonblocking 차이 실험 |
| `helloHDL/260506_SR04/SR04.srcs/sources_1/new/sr04.v` | `13-48` | 버튼, 초음파 제어기, FND, `tick_us` 연결 |
| `helloHDL/260506_SR04/SR04.srcs/sources_1/new/sr04.v` | `61-69` | SR04 타이밍 관련 `localparam` |
| `helloHDL/260506_SR04/SR04.srcs/sources_1/new/sr04.v` | `117-166` | `IDLE -> START -> WAIT -> RESPONSE` FSM |
| `helloHDL/260506_SR04/SR04.srcs/sim_1/new/tb_SR04.v` | `22-50` | `tick_us`가 1us 주기로 나오는지 확인 |
| `helloHDL/260506_DHT11/DHT11.srcs/sources_1/new/dth11.v` | `34-49` | DHT11 상태와 시간 기준 상수 |
| `helloHDL/260506_DHT11/DHT11.srcs/sources_1/new/dth11.v` | `113-267` | 40비트 수신 FSM과 checksum 판정 |
| `helloHDL/260506_DHT11/DHT11.srcs/sim_1/new/tb_dht11.v` | `48-69` | 센서 응답 파형을 TB에서 직접 흉내냄 |

## 코드에서 정리할 핵심

| 주제 | 정리 |
| --- | --- |
| random access | 주소를 직접 골라 읽고 쓰는 뜻이지 값이 랜덤이라는 뜻이 아니다 |
| FIFO | 메모리만이 아니라 pointer와 `full/empty` 판정까지 포함한 구조다 |
| blocking / nonblocking | `tb_practice_1.v:12-24`처럼 같은 절차 안에서도 결과가 달라진다 |
| SR04 | `echo` high 폭을 세고 `distance = echo_high_cnt_reg / 58`로 거리화한다 |
| DHT11 | `inout` 라인을 잠깐 끌어내렸다가 놓고, high 폭 길이로 `0/1`을 구분한다 |

## 코드에서 꼭 볼 줄

| 위치 | 포인트 |
| --- | --- |
| `fifo.v:57-63` | `register_file`은 배열 기반 저장 구조다 |
| `fifo.v:113-145` | push/pop 조합에 따라 pointer를 다르게 움직인다 |
| `tb_practice_1.v:21-24` | nonblocking은 바로 안 바뀌고 다음 시점에 반영된다 |
| `sr04.v:152-159` | `echo` high 구간을 세다가 끝나면 거리로 바꾼다 |
| `dth11.v:221-239` | high 폭이 기준보다 길면 `1`, 짧으면 `0`으로 저장한다 |

## 주의점

| 오해 | 정리 |
| --- | --- |
| FIFO는 단순 RAM이다 | 순서를 지키는 제어가 더 중요하다 |
| blocking과 nonblocking은 문법만 다르다 | 시뮬레이션 타이밍과 실제 레지스터 모델링에 직접 영향이 있다 |
| DHT11은 그냥 입력선이다 | `inout`이라서 주도권을 놓는 시점이 핵심이다 |

## 연결 노트

- [[260415-ila와-시뮬레이션]]
- [[260416-stopwatch-datapath-tick-counter]]
