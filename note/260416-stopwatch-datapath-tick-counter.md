# 26-04-16 - Stopwatch Datapath와 Tick Counter

## 한눈에 보기

| 항목 | 내용 |
| --- | --- |
| 목표 | 스톱워치의 카운터 체인과 tick 생성 구조를 이해한다 |
| 핵심 | `stopwatch_datapath`, `tick_counter`, `tick_gen_100hz`, carry tick |
| 주의 | 현재 저장소의 `stopwatch_datapath.v`는 이미 연결이 채워진 버전이다 |

## 관련 코드 위치

| 파일 | 위치 | 의미 |
| --- | --- | --- |
| `helloHDL/260416_stopwatch_watch/stopwatch_watch.srcs/sources_1/new/stopwatch_datapath.v` | `3-85` | 상위 datapath와 카운터 체인 |
| `helloHDL/260416_stopwatch_watch/stopwatch_watch.srcs/sources_1/new/stopwatch_datapath.v` | `88-138` | `tick_counter` |
| `helloHDL/260416_stopwatch_watch/stopwatch_watch.srcs/sources_1/new/stopwatch_datapath.v` | `140-173` | `tick_gen_100hz` |
| `helloHDL/260416_stopwatch_watch/stopwatch_watch.srcs/sim_1/new/tb_stopwatch_datapath.v` | `35-38`, `65-77`, `89-108` | 빠른 TB용 `force`, preload, 검증 시나리오 |

## 카운터 체인

```text
tick_gen_100hz
-> msec counter
-> sec counter
-> min counter
-> hour counter
```

## 비트폭과 범위

| 대상 | 범위 | 위치 |
| --- | --- | --- |
| `msec` | `0 ~ 99` | `stopwatch_datapath.v:4-12` |
| `sec` | `0 ~ 59` | `stopwatch_datapath.v:4-12` |
| `min` | `0 ~ 59` | `stopwatch_datapath.v:4-12` |
| `hour` | `0 ~ 23` | `stopwatch_datapath.v:4-12` |

## 코드에서 꼭 읽을 것

| 위치 | 읽는 포인트 |
| --- | --- |
| `stopwatch_datapath.v:27-38` | msec 카운터가 가장 아래 자리다 |
| `stopwatch_datapath.v:40-77` | `o_tick`이 다음 자리 `i_tick`으로 이어진다 |
| `stopwatch_datapath.v:116-137` | `count_next`와 `o_tick`를 조합적으로 만든다 |
| `stopwatch_datapath.v:161-171` | `i_run_stop`가 켜져 있을 때만 100Hz tick을 만든다 |

## testbench에서 볼 점

| 위치 | 의미 |
| --- | --- |
| `tb_stopwatch_datapath.v:35-38` | 느린 분주기를 `force`로 우회해서 빨리 검증 |
| `tb_stopwatch_datapath.v:65-77` | 내부 카운터 preload |
| `tb_stopwatch_datapath.v:89-108` | up, clear, down wrap 시나리오 |

## 주의점

| 실수 | 정리 |
| --- | --- |
| `o_tick`을 별도 clock처럼 본다 | 이 설계에서는 1클럭 pulse enable이다 |
| 비트폭을 감으로 잡는다 | 최대 상태 수 기준으로 정해야 한다 |
| 상위 모듈이 비어 있다고 본다 | 현재 저장소 버전은 이미 연결이 채워져 있다 |

## 다음 연결

- [[260416-parameter-localparam]]
