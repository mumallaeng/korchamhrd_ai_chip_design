# 26-09-10 - AXI4-Stream 영상 구간과 그레이스케일 필터 RTL·블록 삽입

관련 노트:

- [26-09-09 - Zynq/PYNQ-Z2 카메라→DDR→HDMI 영상 파이프라인 블록 디자인](260909-zynq-camera-ddr-hdmi-pipeline-block-design.md)
- [26-08-28 - 카메라 write 모듈과 frame buffer 실습](260828-camera-frame-buffer-write-module.md)
- [26-08-25 - VGA CRT 타이밍과 RGB444 카운터/싱크](260825-vga-crt-timing-rgb444-counter-sync.md)

> 수업일: `2026-09-10`
>
> 현재 상태: 어제 조립한 `카메라 → AXI VDMA → DDR3 → Video Out → rgb2dvi → HDMI` 파이프라인을 다시 열어, 그 사이에 사용자 로직을 끼워 넣는 데까지 진행했다. 오전에는 개념(Video Out단이 요구하는 Dynamic Clock·`VTC`·픽셀 클럭 ×5 직렬 클럭, AXI4-Stream 신호 — 원웨이 `TVALID`/`TREADY` 핸드셰이크, `TLAST`=라인 끝, `TUSER`=프레임 시작 —, 순수 RGB 구간에서 처리하는 이유)을 정리했다. 이어서 `그레이스케일 필터` RTL을 작성해(패킹된 RGB에서 채널 추출 → 가중합, `TREADY`를 상태에 맞춰 구동, `enable`을 `TUSER`(SOF)에서만 래치), 블록 디자인에서 Add Module로 VDMA `MM2S`와 Video Out 사이에 삽입하고, `enable`을 1핀 출력 `GPIO`로 뺀 뒤 Run Connection Automation·Validate Design까지 마쳤다. 이후 bitstream 생성 → `.xsa` export(Include bitstream, 기존과 같은 이름으로 덮어쓰기) → Vitis에서 플랫폼 Update·전체 Clean·재빌드까지 하고, `xparameters.h`에서 `GPIO` 정의 확인 후 `UART` 메뉴로 `gray_toggle`(1=필터 on, 0=off)을 제어하는 코드(`grayfilter.c/.h`, `XGpio_Initialize`)에 착수했다. 다음 시간에 메뉴를 완성해 빌드·실행하고 화면에서 컬러↔흑백 전환을 확인한다.

## 수업 범위

| 구분 | 내용 |
| :--- | :--- |
| `PS`/`PL` 복습 | `PS`에 CPU·FPU·DDR 컨트롤러와 `SPI`/`I2C`/`CAN`/`UART`/`GPIO`/`SD`/`USB` 주변장치가 하드코어로 내장. 설계 대상은 `PL`이지만 `PS` C 코드로 제어 |
| `UART` 위치 | `PS` `UART`는 다운로드용 USB 케이블에 이미 연결됨. 별도 `UART`가 필요하면 다른 핀으로 빼야 함 |
| Video Out단 요구사항 | Dynamic Clock(픽셀 클럭), `VTC`(비디오 타이밍), 픽셀 클럭 ×5 직렬 클럭(TMDS 직렬화용) |
| AXI4-Stream 신호 | 원웨이(master→slave), `TDATA`, `TVALID`/`TREADY` 핸드셰이크, `TLAST`, `TUSER` |
| `TLAST` / `TUSER` 용도 | 이 설계에서 `TLAST`=한 라인의 마지막 픽셀(EOL), `TUSER`=프레임 첫 픽셀(SOF, Start of Frame) |
| 순수 RGB 구간 | VDMA `MM2S` ~ Video Out 사이는 porch·sync 없는 순수 RGB 스트림. porch/sync는 아날로그 디스플레이 잔재 |
| 삽입 설계 | VDMA `MM2S`와 Video Out 사이 스트림을 잘라 `그레이스케일 필터` IP 삽입, `PS` `GPIO`로 enable 제어 |

## 전체 흐름

```text
Pcam (MIPI CSI-2)  ── 외부 ──
  → PHY 수신 (하드웨어 계층, 데이터 입력 / 전원·SCCB 제어 신호 출력)
  → Raw 데이터
  → Bayer → RGB 변환
  → Gamma
  → AXI4-Stream (RGB, 순수 데이터)
  → AXI VDMA S2MM        (스트림 → 메모리)
  → DDR3                 (PS HP0 경유, 프레임 버퍼)  ← 원본 데이터는 여기 그대로 보존
  → AXI VDMA MM2S        (메모리 → 스트림)
  ┌─────────────── 여기(순수 RGB 스트림 구간)에 그레이스케일 필터 삽입 ───────────────┐
  │   … VDMA MM2S ──[AXI4-Stream cut]──▶ Gray Filter ──[AXI4-Stream]──▶ Video Out …    │
  │        Gray Filter enable ◀── PS GPIO (1=grayscale, 0=원본 통과)                    │
  └───────────────────────────────────────────────────────────────────────────────────┘
  → AXI4-Stream to Video Out  (스트림 → 비디오 포맷: RGB + V-Sync/H-Sync)
        + Dynamic Clock (픽셀 클럭 기준)
        + VTC           (비디오 타이밍)
        + 픽셀 클럭 ×5   (직렬 전송용)
  → rgb2dvi              (RGB → DVI/TMDS 출력 형태)
  → HDMI 케이블 → 모니터
```

## 파이프라인 다시 보기: 세 구간

어제 회로를 추상화하면 세 덩어리다.

| 구간 | 역할 |
| :--- | :--- |
| 카메라 입력 회로 | 외부 Pcam → PHY → Raw → Bayer→RGB → Gamma → AXI4-Stream. PHY 쪽으로 데이터가 들어오고, 전원 제어·`SCCB`(레지스터 설정) 신호가 나감 |
| VDMA | 스트림 영상과 DDR3를 잇는 다리. `S2MM`으로 DDR에 쓰고 `MM2S`로 DDR에서 읽어 다시 스트림으로 내보냄. DRAM 접근은 `PS`의 `HP0` 포트 경유 |
| 비디오 출력 회로 | `MM2S` 스트림을 Video Out이 비디오 포맷으로 바꿔 `rgb2dvi` → HDMI로 출력 |

`DDR3` 메모리는 외부에 있고 `PS`의 DDR 컨트롤러와 연결된다. 카메라도 외부다.

## Video Out단이 필요로 하는 것

`AXI4-Stream to Video Out`은 '스트림 데이터를 비디오 포맷으로 바꿔 내보내는' 모듈이다. 비디오 포맷은 순수 RGB뿐 아니라 `V-Sync`/`H-Sync` 동기 신호까지 포함한다. 이걸 만들려면 세 가지가 붙어야 한다.

| 항목 | 이유 |
| :--- | :--- |
| Dynamic Clock | 비디오 출력이 동작하는 기준 픽셀 클럭. 해상도에 맞는 픽셀 레이트를 공급 |
| `VTC` (Video Timing Controller) | 해상도별 비디오 타이밍(가시 영역, sync, porch)을 생성. VGA 실습에서 카운터로 직접 만들던 부분을 IP가 대신함 |
| 픽셀 클럭 ×5 직렬 클럭 | `RGB888`은 24비트지만 24가닥 전선으로 병렬 전송하지 않고 직렬로 보낸다. 빠른 클럭으로 직렬화해야 하므로 픽셀 클럭의 5배 클럭이 추가로 필요 (TMDS: 픽셀당 10비트를 DDR로 전송) |

우선 흐름을 이렇게 잡으면 된다: "Video Out은 스트림을 비디오 포맷으로 바꿔 내보내는 모듈이고, 그래서 타이밍(`VTC`)·기준 클럭(Dynamic Clock)·직렬 클럭(×5)이 필요하다." 실제 재조립은 어제 노트를 보면서 차근차근 하면 된다.

## AXI4-Stream 신호

VDMA의 `MM2S`(Memory-Map to Stream, 메모리→스트림)와 `S2MM`(Stream to Memory-Map, 스트림→메모리)에서 스트림이 오간다. 포트 표기에서 `M`=master=송신 측, `S`=slave=수신 측이다.

- **원웨이**: AXI4-Stream은 한 방향(master→slave)으로만 데이터가 흐른다. slave→master로 가는 데이터는 없다.
- **`TDATA`**: 실제 데이터. master가 내보내고 slave가 받는다.
- **`TVALID` / `TREADY` 핸드셰이크**: 데이터가 나갈 때 master가 `TVALID`를 함께 세우고, 수신 측이 `TREADY`로 응답한다. 둘 다 `1`인 사이클에 데이터가 전달된다. `TREADY`는 미리 `1`로 떠 있을 수도 있고 받은 뒤 다시 올라올 수도 있는데, 이 설계에서는 미리 떠 있다.

## `TLAST`와 `TUSER`

스펙상 두 신호가 더 있다.

| 신호 | 스펙상 의미 | 이 설계에서의 용도 |
| :--- | :--- | :--- |
| `TLAST` | 버스트(연속 전송)의 마지막 데이터를 알리는 끝 신호 | 한 라인(horizontal)의 마지막 픽셀 = EOL. 라인 마지막 픽셀에서 `1` |
| `TUSER` | 사용자 정의 신호(스펙에서 용도를 지정하지 않음) | 프레임의 첫 데이터 = `SOF`(Start of Frame). 프레임 첫 픽셀에서 `1` |

활용: horizontal 카운터를 돌리다가 `TUSER`가 `1`이 되면 '프레임이 시작됐다 / 첫 픽셀이다'를 알 수 있으므로, 그 시점에 horizontal 카운터를 `0`으로 되돌리면 된다.

## 순수 RGB 구간 vs 비디오 포맷 구간

- **VDMA `MM2S` ~ Video Out 사이(AXI4-Stream 구간)**: porch·sync가 없는 **순수 RGB 데이터**만 흐른다.
- **Video Out 이후(비디오 포맷 구간)**: RGB + porch + sync가 다 포함된다.

porch·sync는 아날로그 모니터(브라운관/CRT) 때문에 생긴 신호다. 디지털 구간에서는 필요 없다. 그래서 사용자 로직은 **순수 RGB 구간에서 처리하는 것이 유리**하다 — porch/sync를 신경 쓸 필요 없이 데이터만 다루면 된다.

또한 기준을 'DDR에 저장된 데이터'로 잡으면, DDR의 원본은 그대로 두고 읽어온 사본만 조작해서 내보낼 수 있다. 입력단 앞에서 변환하면 변환된 값이 원본으로 저장되어 버린다.

## 그레이스케일 필터 삽입 설계

이번 목표는 영상 파이프라인에 사용자 로직을 끼워 넣는 가장 단순한 예제로 **그레이스케일 필터**를 만드는 것이다.

```text
             ┌───────────────┐        ┌──────────────┐        ┌───────────┐
  VDMA MM2S ─┤ (AXI4-Stream) ├──────▶─┤ Gray Filter  ├───────▶┤ Video Out │─▶ rgb2dvi ─▶ HDMI
             └───────────────┘        └──────┬───────┘        └───────────┘
                                     enable  │
                                             ▲
                                   ┌─────────┴─────────┐
                                   │ PS CPU ─▶ GPIO IP  │  (1=grayscale, 0=원본 통과)
                                   └───────────────────┘
```

- VDMA `MM2S`와 Video Out 사이의 AXI4-Stream을 잘라 그 사이에 `그레이스케일 필터` IP를 삽입한다.
- `enable = 1`이면 그레이스케일로 변환해 출력, `enable = 0`이면 원본 데이터를 그대로 통과.
- `enable`은 `PS` 쪽에서 제어한다: `GPIO` IP를 하나 만들어 CPU와 연결하고, `PS`에서 `GPIO`로 `1`/`0`을 내보내 필터를 켜고 끈다.

개념 자체는 단순하다. 아래는 실제로 RTL을 작성하고 블록 디자인에 끼워 넣은 내용이다.

## 그레이스케일 필터 RTL 구현

### 픽셀 비트 레이아웃 주의

Digilent가 제공한 IP(`Bayer to RGB`)가 픽셀 데이터를 표준적이지 않게 패킹해서 내보낸다. 채널이 들어있는 비트 위치가 예전과 달라졌다(상위 비트 쪽에 `B`·`G`, 중간 비트에 `B` 식으로 재배치됨). 그레이스케일은 `R`·`G`·`B` 채널을 각각 뽑아 가중합해야 하므로, **패킹된 픽셀 워드에서 각 채널의 비트 필드를 정확히 잘라내는 것**이 첫 관문이다. 여기서 비트 슬라이스를 틀리면 색이 이상하게 나온다. 채널을 뽑아 계수를 곱해 더하면 그레이 값이 나온다.

### `TREADY` 구동

- slave 쪽에서 나가는 신호가 `TREADY`다. master의 `TVALID`를 받고 나서 `TREADY`를 세운다.
- `TREADY`를 `1`로 고정하지 않고 **'받아도 되는 상태일 때만'** `1`로 만든다. master(VDMA 쪽)의 전송이 멈춰 있을 때(예: porch·sync 구간, 출력이 비어 있을 때)는 받으면 안 되므로, 그때는 `TREADY`를 내려 수신을 막는 구조로 만든다.
- **핸드셰이크(`TVALID` & `TREADY` 동시 `1`)가 일어난 사이클에** 데이터를 연산해서 master(하류) 쪽으로 내보낸다.

### `enable`을 프레임 시작에서만 래치

- 필터 on/off 신호(`enable`, 디자인상 `enable_use`)를 아무 때나 바꾸면, 한 프레임 도중에 컬러로 나오다가 갑자기 흑백으로 바뀐다. 프레임이 깨진다.
- 그래서 `enable` 입력을 바로 쓰지 않고, **`TUSER`(SOF, 프레임 시작)이면서 핸드셰이크가 일어난 시점에만** 내부 `enable` 상태를 갱신(래치)한다. `SOF`가 아니면 직전 상태를 유지한다. 결과적으로 필터 전환은 항상 프레임 경계에서만 일어난다.

### 구조 요약

RTL은 세 부분으로 본다: ① `TVALID`/`TREADY` 핸드셰이크 로직(앞으로 계속 재사용), ② 연산부(채널 추출 → 가중합), ③ 결과를 master 쪽으로 내보내는 출력부. `enable = 0`이면 원본 픽셀을 그대로 통과시킨다. 작성 후 저장하고 IP로 패키징한다.

## 블록 디자인에 삽입

1. 블록 디자인 캔버스에서 우클릭 → **Add Module** → 방금 만든 그레이스케일 필터 모듈 선택. 배치하면 블록에 slave·master 포트가 보인다.
2. 배선:
   - VDMA `MM2S`(스트림 출력) → 그레이스케일 필터 **slave** 입력
   - 그레이스케일 필터 **master** 출력 → `Video Out`의 `video_in`
   - (즉 기존 `VDMA MM2S → Video Out` 스트림을 잘라 그 사이에 필터를 끼움)
3. **Run Connection Automation** → 클록·리셋이 자동으로 잡힌다. AXI·클록·리셋 연결 확인.
4. `enable` 신호는 `GPIO`로 뺀다:
   - `AXI GPIO` IP 추가 → 더블 클릭 → IP Configuration은 값을 다 **custom**으로 두고, **All Outputs** 체크(전부 밖으로 나가는 신호), **GPIO Width = 1**(핀 1개).
   - 포트 목록에서 `GPIO` → `IO` → `O`(Output)를 필터의 `enable` 입력에 연결. AXI·클록·리셋은 Run Connection Automation으로 자동 연결.
5. **Validate Design** 실행(뜨는 warning은 무시).

## Vitis: 플랫폼 갱신과 GPIO 제어 코드 (진행 중)

Validate Design 뒤 bitstream을 생성하고, `PS` 소프트웨어로 그레이스케일 on/off를 제어하는 단계로 넘어갔다. 이번 시간에 코드 착수까지 하고 마무리는 다음 시간.

### 새 플랫폼(.xsa) 내보내기 → Vitis 반영

1. bitstream 생성 후 **Export Hardware** → **Include bitstream** 체크 → `.xsa` 플랫폼 파일 생성.
2. 그 `.xsa`를 프로젝트의 `xsa` 폴더에 **기존 파일과 같은 이름으로** 넣는다(overwrite).
3. **Vitis IDE** 실행 → 기존에 잡아둔 **workspace** 선택 → 열기. (아직 새 플랫폼은 반영 전.)
4. 플랫폼 항목(트리 최상단) 선택 → 새로 만든 `.xsa` 지정 → OK 반복 → **Update**.
5. 기존 빌드 산출물 정리: 컴포넌트 **전체 선택 → Clean** → 예전에 빌드된 것을 싹 지운 뒤 **재빌드(recompile)**.

### GPIO 제어 코드

- `xparameters.h`를 연다(파일명 위에서 Ctrl+클릭). 하드웨어 정의가 여기 다 있다. 아래로 내려가면 `GPIO` 항목이 중간에 끼어 있고 `Device ID` / `Base Address` 등이 보인다 — 이게 보이면 블록 디자인의 `AXI GPIO`가 제대로 반영된 것.
- 제어 방식: `UART`로 메뉴를 하나 만든다(`menu_run` 같은 함수). `UART`로 들어온 입력(키보드 키)을 읽어 그에 맞게 동작. (`static` = 이 파일에서만 쓰는 심볼.)
- 동작: `gray_toggle` = `1`이면 그레이스케일 필터 실행, `0`이면 off. 즉 코드가 `GPIO` 출력을 `1`/`0`으로 쓴다.
- 소스 배치: Vitis `src` 아래에 폴더(예: `gray`) 추가 → New → Source File 로 `grayfilter.c` / `grayfilter.h` 생성.
- GPIO 초기화: `XGpio` 드라이버 사용. `XGpio_Initialize(...)`에 GPIO `Device ID`(`XPAR_..._GPIO_..._DEVICE_ID`)와 채널(control channel) 지정 → 방향 설정 → 값 write.
- 여기까지 착수. 나머지(메뉴 완성, 빌드·실행해서 화면에서 컬러↔흑백 전환 확인)는 다음 시간.

## 실습 확인 항목

- Video Out에 Dynamic Clock, `VTC`, 픽셀 클럭 ×5 직렬 클럭이 왜 필요한지 설명할 수 있는지
- AXI4-Stream이 원웨이이며 `TVALID`/`TREADY` 핸드셰이크로 전달된다는 것, 이 설계에서 `TREADY`가 선행한다는 것
- `TLAST`=라인 끝(EOL), `TUSER`=프레임 시작(SOF)으로 쓰인다는 것과, `TUSER`로 horizontal 카운터를 리셋한다는 것
- VDMA `MM2S`~Video Out 구간이 porch/sync 없는 순수 RGB 스트림이라는 것, 그래서 이 구간에서 영상 처리를 하는 이유
- DDR 원본을 보존하고 읽어온 사본만 조작한다는 접근
- `Bayer to RGB`가 채널을 비표준 비트 위치로 패킹한다는 것, 그래서 채널 비트 슬라이스를 먼저 정확히 잡아야 한다는 것
- `TREADY`를 `1` 고정이 아니라 '받아도 되는 상태'에서만 세우는 이유(master 전송 멈춤·빈 출력 구간 배제)
- `enable`을 `TUSER`(SOF)에서만 래치해 프레임 경계에서만 전환되게 하는 이유
- 블록 디자인 삽입 순서: Add Module → `VDMA MM2S → 필터 slave` / `필터 master → Video Out` → Run Connection Automation → `AXI GPIO`(All Outputs, Width 1)로 `enable` 제어 → Validate Design
- Export Hardware는 **Include bitstream**, `.xsa`는 기존과 같은 이름으로 `xsa` 폴더에 덮어쓰기
- Vitis: 플랫폼을 새 `.xsa`로 Update → 전체 Clean → 재빌드
- `xparameters.h`에서 `AXI GPIO`의 `Device ID`/`Base Address`가 보이는지 확인(블록 반영 여부 체크)
- `XGpio_Initialize` + 채널 지정 → 방향 설정 → `1`/`0` write 로 `gray_toggle` 제어, `UART` 메뉴로 키 입력 받기
- (다음 시간) UART 메뉴 완성 → 빌드·실행 → 화면 컬러↔흑백 전환 확인
