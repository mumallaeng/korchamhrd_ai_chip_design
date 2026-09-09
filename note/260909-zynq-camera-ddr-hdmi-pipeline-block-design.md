# 26-09-09 - Zynq/PYNQ-Z2 카메라→DDR→HDMI 영상 파이프라인 블록 디자인

관련 노트:

- [26-08-28 - 카메라 write 모듈과 frame buffer 실습](260828-camera-frame-buffer-write-module.md)
- [26-08-26 - 최종 프로젝트 팀 구성과 VGA 컬러바 리뷰](260826-final-project-team-formation-and-vga-color-bar-review.md)
- [26-08-25 - VGA CRT 타이밍과 RGB444 카운터/싱크](260825-vga-crt-timing-rgb444-counter-sync.md)

> 수업일: `2026-09-09`
>
> 현재 상태: 최종 프로젝트 보드인 PYNQ-Z2(Zynq-7020)로 넘어와, MIPI 카메라 입력 → `AXI VDMA` → DDR3 → HDMI 출력 파이프라인을 Vivado IP Integrator 블록 디자인으로 조립했다. 입력단(D-PHY RX ~ Bayer to RGB ~ VDMA `S2MM`), 출력단(`VTC`, Dynamic Clock, Video Out, `rgb2dvi`), 외부 포트 이름 정리, Validate Design, HDL 래퍼 생성까지 마치고 합성을 시작했다. 다음 수업에서 제약 파일(XDC), 구현·bitstream, PS 소프트웨어를 이어서 다룬다.

## 수업 범위

| 구분 | 내용 |
| :--- | :--- |
| Zynq SoC 구조 | `PS`(하드코어 Cortex-A9 ×2, DDR3 컨트롤러, 하드코어 주변장치)와 `PL`(사용자 설계 영역) 구분 |
| PS↔PL 연결 | `GP` AXI 포트와 `HP` AXI 포트의 용도 차이, DRAM 접근은 `HP` 포트 사용 |
| PS 재설정 | `HP0` Slave AXI 활성화, `I2C`/`GPIO`를 `EMIO`로 노출, fabric 클럭 2개(100/200MHz) |
| `AXI VDMA` | 스트림 영상과 DDR3를 잇는 다리, 트리플 프레임 버퍼로 tearing 방지 |
| MIPI 입력 경로 | `MIPI_D_PHY_RX` → `MIPI_CSI_2_RX` → `Bayer to RGB` → VDMA `S2MM` |
| HDMI 출력 경로 | VDMA `MM2S` → AXI4-Stream to Video Out(+ `VTC`, + Dynamic Clock) → `rgb2dvi` → `TMDS` |
| 마무리 | 외부 포트 이름 정리, Address Editor 확인, Validate Design(critical warning 무시), Create HDL Wrapper, 합성 |
| 벤더 IP 저장소 | 강사가 공유한 Digilent IP 압축본을 프로젝트 폴더에 풀고 `Settings → IP → Repository`에 등록 |

## 전체 흐름

```text
Pcam (MIPI CSI-2)
  → MIPI_D_PHY_RX   (직렬 레인 수신, RefClk 200MHz)
  → MIPI_CSI_2_RX   (PPI 수신, 픽셀 스트림 복원)
  → Bayer to RGB    (베이어 → RGB888 AXI4-Stream)
  → AXI VDMA S2MM   (스트림 → 메모리)
  → DDR3            (PS HP0 경유, 프레임 버퍼 3개)
  → AXI VDMA MM2S   (메모리 → 스트림)
  → AXI4-Stream to Video Out  (+ VTC 타이밍, + Dynamic Clock)
  → rgb2dvi          (RGB → TMDS 직렬화, 픽셀·5배 직렬 클럭, LOCKED→리셋)
  → TMDS 외부 포트   (HDMI TX 커넥터)
```

## Zynq SoC 구조: PS와 PL

PYNQ-Z2에 올라간 Zynq-7020은 하나의 칩 안에 프로세서와 FPGA 패브릭을 함께 담은 SoC다. 위쪽을 `PS`(Processing System), 아래쪽을 `PL`(Programmable Logic)이라고 부른다.

`PS`는 하드코어다. 칩 안에 물리적으로 박혀 있어 합성·구현 없이 설정만으로 바로 쓴다.

- Cortex-A9 프로세서가 2개 들어 있고, 펌웨어를 바로 올려도 되고 리눅스를 올려 네트워크 통신 기반 프로젝트를 해도 된다.
- DDR3 메모리 컨트롤러가 칩 내부에 있다. 실제 DRAM 소자는 보드 앞뒤로 나뉘어 외부에 실장돼 있고, 합쳐서 약 1GB를 쓸 수 있다.
- Ethernet, USB, `SPI`, `UART`, `CAN`, `I2C` 마스터가 모두 하드코어로 들어 있다.
- 전에 만든 MicroBlaze는 소프트코어라서 합성해 bitstream으로 CPU 자체를 만들어 올려야 했다. Zynq `PS`는 그 과정 없이 고정된 하드웨어를 그대로 가져다 쓴다는 점이 다르다.

`PL`은 사용자가 직접 설계하는 영역이다. IP를 배치·연결하고 bitstream을 만들어 `PS`와 붙여 동작시킨다. `PS`는 "이미 있는 것을 세팅해서 사용", `PL`은 "내가 만든다"로 개념을 잡는다.

```text
        ┌───────────────  PS (하드코어, 고정)  ───────────────┐
        │  Cortex-A9 ×2   DDR3 컨트롤러   SPI/I2C/UART/GPIO   │
        │        │             │                │            │
        │     GP AXI        HP AXI            EMIO            │
        └────────┼─────────────┼────────────────┼────────────┘
                 │             │                │
        ┌────────┼─────────────┼────────────────┼────────────┐
        │        ▼             ▼                ▼            │
        │   사용자 IP / VDMA / 카메라·HDMI 회로  (PL)         │
        └───────────────────────────────────────────────────┘
```

### AXI 포트: GP와 HP

`PS`와 `PL`은 AXI 버스로 통신한다. 포트가 두 종류다.

| 포트 | 용도 |
| :--- | :--- |
| `GP` (General Purpose) | CPU가 `PL` 쪽 IP의 레지스터를 제어하는 저대역 경로 |
| `HP` (High Performance) | `PL`이 DDR3에 대량으로 read/write 하는 고대역 경로 |

카메라 영상을 DDR3에 저장하려면 `PL`에서 메모리로 가는 고대역 경로가 필요하므로 `HP0` Slave AXI 인터페이스를 켠다.

### EMIO

`PS`의 `UART`는 다운로드용 USB-UART 케이블에 이미 고정 연결돼 있어, 별도 `UART`가 필요하면 그 케이블을 쓰지 못하고 다른 핀으로 빼야 한다. `I2C`, `GPIO` 같은 `PS` 주변장치를 `PL`이나 외부 핀으로 끌어내는 설정이 `EMIO`다. 이번 설계에서는 카메라 `I2C`(SCCB)와 `GPIO`를 `EMIO`로 노출한다.

## PS 재설정: AXI, EMIO, 클럭

블록 디자인에 `ZYNQ7 Processing System` IP를 추가하면 `PS` 전체(두 CPU, 버스, DDR 컨트롤러, 모든 하드코어 주변장치)를 하나의 블록으로 나타낸다. 더블 클릭하면 내부를 설정하는 재설정 UI가 뜨고, 여기서 다음을 맞춘다.

| 설정 항목 | 값 |
| :--- | :--- |
| PS-PL Configuration | `HP0` Slave AXI 인터페이스 활성화 (`GP` Master AXI는 기본 활성) |
| Peripheral I/O Pins | `I2C`, `GPIO`를 `EMIO`로 라우팅 |
| MIO Configuration | `GPIO EMIO` 폭 `1` (우선 GPIO 1개만 사용) |
| Clock Configuration | fabric 클럭 2개 출력, `FCLK_CLK0` = `100MHz`, `FCLK_CLK1` = `200MHz` |
| DDR Configuration | 보드 프리셋 값 그대로 사용 |

fabric 클럭은 `PS`가 `PL`로 내보내는 클럭이다. 100MHz는 AXI 계열 로직용, 200MHz는 MIPI D-PHY 레퍼런스 클럭용으로 쓴다. DDR 파라미터는 손으로 맞추기 매우 번거롭고 보드 파일이 이미 채워 주므로 건드리지 않는다.

설정을 마치면 Zynq 블록에 `GPIO`, `IIC`, `M_AXI_HP0`, `FCLK_CLK0`(100M), `FCLK_CLK1`(200M) 포트가 나타난다.

### Run Block Automation

Zynq 블록을 배치한 뒤 Run Block Automation을 실행한다. 기본 체크박스가 켜져 있어야 하며, 이 체크가 꺼진 상태로 진행하면 앞서 잡은 DDR·MIO 설정이 반영되지 않는다. 실행하면 외부 DDR 메모리와 `FIXED_IO` 포트가 생기고, 이 상태에서 Zynq 블록이 외부 DDR3 소자와 연결된다.

## AXI VDMA와 트리플 프레임 버퍼

카메라 스트림을 DDR3에 넣고 다시 꺼내려면 스트림 영역과 메모리 영역을 잇는 고리가 필요하다. 그 고리가 `AXI VDMA`(Video Direct Memory Access)다. 블록 디자인에 추가하고 더블 클릭해 설정한다.

| VDMA 설정 | 값 |
| :--- | :--- |
| 스트림 데이터 폭 | `RGB888`(24비트), read/write 동일 |
| 라인 버퍼 깊이 | `1024` (넉넉하게) |
| 프레임 버퍼 개수 | `3` |

### 프레임 버퍼를 3개 두는 이유

프레임 버퍼는 한 프레임을 담는 메모리 공간이고, VDMA는 이를 0·1·2번으로 순환 사용한다.

```text
쓰기(카메라):   FB0 채움 → FB1 채움 → FB2 채움 → FB0 …
읽기(HDMI):          FB0 읽음 → FB1 읽음 → FB2 …
                (읽기는 항상 "직전에 완성된" 버퍼를 봄)
```

- 카메라가 `FB0`을 다 채우면 다음 프레임은 `FB1`에 쓰고, 그동안 출력 회로는 완성된 `FB0`을 읽는다. 출력이 한 프레임을 다 읽기 전에 카메라가 다음 버퍼로 넘어가면 읽기 쪽은 계속 이전 버퍼를 반복해 읽는다.
- 버퍼가 2개면 읽는 도중에 쓰기가 같은 버퍼로 돌아와 화면이 찢어질 수 있다. 3개면 쓰기·읽기가 서로 다른 버퍼에 머물 여유가 생겨 안정적이다.
- 3개보다 많이 만들어도 이득이 없다.

이번 조립은 우선 입력 영상을 그대로 출력으로 흘려보내는 통과 경로만 만든다.

### 연결 시 주의점

- Run Connection Automation을 실행하면 `AXI-Lite`(제어) 버스와 `AXI-Stream`(영상) 경로, 그리고 `PS` 인터커넥트가 자동 생성된다.
- CPU 인터커넥트에서 나온 `AXI-Lite`가 VDMA 레지스터 맵에 붙는다. 이 순간 VDMA는 메모리 맵에 잡혀 CPU가 제어 레지스터를 read/write 할 수 있는 상태가 된다.
- VDMA의 클럭 핀 하나가 자동 연결에서 빠지는 도구 특성이 있다. fabric 클럭 net을 VDMA 클럭 핀에 직접 끌어다 붙여 준다.
- 시스템 리셋은 `Processor System Reset` IP가 담당하며, 각 IP의 클럭·리셋을 클럭끼리·리셋끼리 맞춰 연결한다.

## MIPI CSI-2 카메라 입력 경로

Xilinx 기본 MIPI IP는 Pcam 커넥터와 잘 맞지 않아, Digilent가 전용 IP를 제공한다. 강사가 공유한 Digilent IP 압축본을 프로젝트 폴더에 풀고 `Settings → IP → Repository`에 그 폴더를 추가하면 6개 IP가 저장소에 등록된다.

| IP | 역할 |
| :--- | :--- |
| `MIPI_D_PHY_RX` | 직렬 MIPI 레인을 물리 계층에서 수신, `RxByteClkHS`와 `PPI` 출력 |
| `MIPI_CSI_2_RX` | `PPI`를 받아 픽셀 스트림(베이어 raw) 복원 |
| `Bayer to RGB` | 베이어 데이터를 `RGB888` AXI4-Stream으로 변환 |

### 배치와 연결

1. `MIPI_D_PHY_RX`(`DPHY RX 1.0`)를 추가하고 더블 클릭해 `AXI-Lite` 인터페이스만 체크, 나머지(디버그)는 해제한다.
2. `MIPI_CSI_2_RX` 리시버를 추가하고 마찬가지로 `AXI-Lite`만 선택한다.
3. `MIPI_D_PHY_RX`의 `RxByteClkHS`를 리시버의 `RxByteClkHS`에 연결한다.
4. 두 IP의 `PPI` 인터페이스끼리 연결한다.
5. Run Connection Automation으로 `AXI-Lite`를 인터커넥트에 자동 연결한 뒤, 비디오 클럭·AXI 클럭을 각 클럭 핀에 붙인다.
6. `Bayer to RGB`를 추가한다. 기본값 그대로 두고 리시버의 스트림 출력을 이어, 베이어 → `RGB888` 변환 스트림을 만든다.
7. D-PHY의 카메라 쪽 인터페이스를 선택하고 Make External(`Ctrl+T`)로 외부 포트를 만들어 Pcam 커넥터와 연결되게 한다.

### 클럭·리셋 주의

- `FCLK_CLK1`(200MHz)를 `MIPI_D_PHY_RX`의 레퍼런스 클럭 입력에 넣는다. 레퍼런스 클럭은 200MHz여야 한다.
- D-PHY/CSI-2의 리셋은 **하이 액티브**로 넣어야 한다. 이 극성을 잘못 잡는 실수가 잦다.
- Run Connection Automation은 `AXI-Lite` 자동 연결을 먼저 한 뒤에 나머지 연결을 진행한다. 순서가 바뀌면 연결이 꼬인다.

## Bayer to RGB 이후 메모리 저장 경로

`Bayer to RGB`는 리시버가 복원한 데이터를 `AXI-Stream` 영상 데이터로 바꾸고, 이를 `RGB888`로 정리해 다음 단으로 넘긴다.

- `Bayer to RGB`의 `AXI-Stream` 마스터 출력을 VDMA의 `S2MM`(Stream to Memory-Map) 포트에 연결한다. `S2MM`은 스트림을 메모리 쪽으로 보낸다는 뜻이다.
- 각 IP의 `axi` 클럭과 리셋을 클럭끼리·리셋끼리 맞춘다.
- Run Connection Automation으로 `Bayer to RGB`의 `AXI-Lite`를 인터커넥트에 붙인다.

여기까지 하면 입력단이 완성된다: `Pcam → D-PHY RX → CSI-2 RX → Bayer to RGB → VDMA S2MM → DDR3`.

## HDMI 출력 경로: VTC, Dynamic Clock, Video Out

입력 영상은 DDR3에 쌓였고, 이제 메모리에서 꺼내 HDMI로 내보내는 출력단을 만든다.

| IP | 역할 |
| :--- | :--- |
| Dynamic Clock Generator (`axi_dynclk`) | 픽셀 클럭 생성, 해상도별 픽셀 레이트 공급 |
| Video Timing Controller (`VTC`) | `hsync`, `vsync`, active video / Display Enable 타이밍 생성 |
| AXI4-Stream to Video Out | 메모리에서 온 스트림을 타이밍에 맞춰 픽셀 버스로 출력 |

### VTC의 의미

`VTC`는 VGA·720p·1080p 등 해상도별 타이밍 정보를 만들어 주는 IP다. 전에 VGA 실습에서 카운터로 직접 만들었던 `hsync`/`vsync`/Display Enable 생성 회로를, 이번에는 IP가 대신한다.

### 배치와 연결

1. Dynamic Clock Generator를 추가하고 Run Connection Automation을 실행하면 100MHz 입력, 리셋, 클럭이 잡힌다.
2. `VTC`를 추가한다. 한 옵션만 주의해서 조정하고(나머지 기본값) OK 한다.
3. Dynamic Clock Generator 출력을 `VTC`의 클럭 입력에 연결한다.
4. AXI4-Stream to Video Out을 추가하고 더블 클릭해 Independent 클럭 / Master 모드를 선택한다.
5. `VTC`의 타이밍 출력을 Video Out의 타이밍 입력에 연결한다.
6. `VTC`의 `gen_clken`(젠 클럭 이네이블)을 Video Out에 연결한다. 빠뜨리기 쉬운 연결이다.
7. Video Out의 출력 클럭을 Dynamic Clock Generator 출력과 연결한다.
8. Video Out의 `video_in`(AXI4-Stream 영상 데이터)은 VDMA의 `MM2S`(Memory-Map to Stream) 포트에서 받는다. 즉 DDR3 → VDMA `MM2S` → 스트림 → Video Out으로 흐른다.

## rgb2dvi: RGB에서 TMDS로

Video Out이 만든 RGB 픽셀 버스를 HDMI(DVI) 신호로 직렬화하는 IP가 `rgb2dvi`다. 추가하기 전에 기본으로 잡혀 있는 불필요한 연결이 선택돼 있으면 먼저 지운다.

| `rgb2dvi` 입력 | 연결원 |
| :--- | :--- |
| RGB 비디오 입력 | Video Out의 RGB 출력 |
| 픽셀 클럭 | Dynamic Clock Generator의 픽셀 클럭 출력 |
| 직렬 클럭 | Dynamic Clock Generator의 5배 클럭 출력 (픽셀 클럭의 5배) |
| 리셋 | Dynamic Clock Generator의 `LOCKED` 신호 |

- 직렬 클럭이 픽셀 클럭의 5배인 이유는 TMDS가 픽셀당 10비트를 두 배 데이터레이트로 실어 보내기 때문이다. 픽셀 클럭, 5배 직렬 클럭, `LOCKED`→리셋 세 연결을 정확히 맞추는 것이 핵심이다.
- `rgb2dvi`의 `TMDS` 출력을 Make External로 빼내 HDMI TX 커넥터에 연결한다.

## 외부 포트 이름 정리

카메라·모니터·제어 신호를 Make External(`Ctrl+T`)로 빼면 포트 이름 끝에 `_0` 같은 접미가 붙어 지저분하고 어떤 신호인지 불명확하다. 제약 파일(XDC)과 정확히 맞물리도록 포트 이름을 정리한다.

| 외부 포트 | 의미 |
| :--- | :--- |
| 카메라 MIPI 데이터 입력 | Pcam에서 들어오는 영상 데이터 (MIPI 인터페이스) |
| 카메라 `IIC` (SCCB) | 카메라 레지스터를 설정하는 제어선, `EMIO`로 뺀 `PS` `I2C` |
| 카메라 `GPIO` | 카메라 on/off(전원·인에이블) 신호, `EMIO`로 뺀 `PS` `GPIO` |
| `TMDS` | HDMI TX 출력, 접미 `_0` 제거 |

포트 블록의 글자를 클릭하면 왼쪽 패널에서 이름을 수정할 수 있다.

## Validate Design과 마무리

1. `GPIO`, `IIC`를 각각 선택하고 `Ctrl+T`로 외부 포트를 만든다.
2. Validate Design을 실행한다. Digilent 제공 IP의 일부 연결에 대해 critical warning이 뜨지만 무시해도 된다.
3. Address Editor에서 메모리 맵을 확인한다. 메모리 맵에 잡힌 IP(VDMA, D-PHY RX, CSI-2 RX 등)의 주소가 배정돼 있어야 CPU가 레지스터로 제어할 수 있다.
4. Create HDL Wrapper를 실행해 블록 디자인 전체를 하나의 HDL 최상위 모듈로 감싼다. auto-update 옵션을 켜고 OK 한다.
5. 합성을 시작한다.

## 실습 확인 항목

- `ZYNQ7 Processing System` 재설정에서 `HP0` Slave AXI, `I2C`/`GPIO` `EMIO`, fabric 클럭 100/200MHz가 잡혔는지 확인
- Run Block Automation의 기본 체크박스가 켜진 상태로 실행됐는지 확인
- VDMA 프레임 버퍼가 `3`, 데이터 폭이 `RGB888`인지 확인
- VDMA에서 자동 연결되지 않은 클럭 핀을 수동으로 붙였는지 확인
- `MIPI_D_PHY_RX` 레퍼런스 클럭이 200MHz, 리셋 극성이 하이 액티브인지 확인
- Digilent IP 저장소를 `Settings → IP → Repository`에 추가해 6개 IP가 보이는지 확인
- 입력단 스트림 경로(`CSI-2 RX → Bayer to RGB → VDMA S2MM`)와 출력단 스트림 경로(`VDMA MM2S → Video Out → rgb2dvi`) 연결 확인
- `VTC`의 `gen_clken`이 Video Out에 연결됐는지 확인
- `rgb2dvi`에 픽셀 클럭·5배 직렬 클럭·`LOCKED`→리셋이 맞게 들어갔는지 확인
- 외부 포트 이름을 XDC와 맞도록 정리했는지 확인 (카메라 데이터·`IIC`·`GPIO`, `TMDS`)
- Validate Design의 critical warning이 Digilent IP 관련 무시 가능 항목인지 확인
- Address Editor에서 메모리 맵 주소가 모두 배정됐는지 확인
- Create HDL Wrapper(auto-update) 후 합성 진입 확인

## 환경 점검

| 증상 | 확인 순서 | 처리 기준 |
| :--- | :--- | :--- |
| 전원 인가 후 보드 LED 미점등 | 전원 스위치(1번) 확인 → USB 케이블을 3번 커넥터에 연결 → 전원 소스 점퍼(2번, `Wall` 위치) 확인 | 점퍼·케이블 정상인데도 무반응이면 보드 불량으로 판단, 다른 보드로 교체 |
| 카메라 입력·HDMI 출력 동작 불안정 | USB 전원만으로 구동 중인지 확인 | 외부 전원 어댑터를 반드시 연결 (USB만으로는 전력 부족) |
| Pcam 인식 불가 | 플렉시블 케이블 방향(렌즈 방향 기준)과 커넥터 래치 상태 확인 | 커넥터 래치를 살짝 올려 케이블을 끝까지 삽입한 뒤 래치를 눌러 고정, 케이블은 접히지 않게 취급 |
| 부트/저장 모드 점퍼(26번) 위치 의문 | 현재 점퍼 위치 확인 | bitstream 저장 위치(JTAG/QSPI/SD) 선택용이며 현재 실습 단계에서는 그대로 두어도 무방 |
