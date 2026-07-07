# VGA와 CRT 화면 출력

원본 자료: Classroom 사전 업로드 VGA 강의자료, 파일명 확인 필요

## 핵심 용도

VGA(Video Graphics Array)의 이론적 배경, CRT 브라운관의 주사 방식, `640x480 @ 60Hz` VGA 타이밍, Basys 3/Artix-7 기반 FPGA 구현 흐름을 미리 정리하는 자료다. 날짜별 수업에서 VGA controller, pixel clock, `H-Sync`, `V-Sync`, RGB 출력 실습이 시작되면 이 내용을 바탕으로 본 수업메모에 병합한다.

## CRT와 브라운관

CRT(Cathode-Ray Tube)는 LCD/OLED 같은 평판 디스플레이가 보급되기 전 대표적으로 사용되던 영상 출력 장치다. 1897년 독일 물리학자 카를 페르디난트 브라운이 발명한 음극선관에서 유래하며, 한국어로는 브라운관이라고 부른다.

CRT는 뒤쪽 전자총에서 전자빔을 발사하고, 편향 코일로 전자빔을 좌우/상하 방향으로 굴절시켜 화면 안쪽의 형광체에 부딪히게 한다. 형광체는 전자빔을 맞으면 빛을 내고, 이 과정을 빠르게 반복하면 사람이 하나의 화면으로 인식한다.

| 단계 | 동작 | 의미 |
|---|---|---|
| 전자총 | 가열된 음극에서 전자빔 방출 | 화면을 그릴 에너지 생성 |
| 편향 | 편향 코일로 전자빔 방향 제어 | 좌우/상하 위치 이동 |
| 발광 | 전자빔이 형광체에 충돌 | 픽셀 위치에 빛 생성 |
| 주사 | 왼쪽에서 오른쪽, 위에서 아래로 반복 | 전체 화면 구성 |

## CRT의 특징

| 구분 | 내용 |
|---|---|
| 장점 | 빠른 응답 속도, 우수한 색 표현력, 넓은 시야각 |
| 단점 | 큰 부피와 무게, 전자파 발생, 화면 왜곡 가능 |
| 현재 활용 | 레트로 게임, 미디어 아트, 특수한 색감/응답 속도 활용 |

CRT는 일반 소비자 시장에서는 LCD 보급 이후 거의 사라졌지만, 지연이 작고 색감이 자연스럽다는 이유로 레트로 디스플레이 용도에서는 여전히 가치가 있다.

## VGA 기본 사양

VGA 실습의 기준 타이밍은 `640x480 @ 60Hz`다. 실제 표시 영역은 가로 640픽셀, 세로 480라인이지만, 동기화와 되돌아가는 시간을 포함하면 한 줄은 800 pixel clock, 한 프레임은 525 line으로 구성된다.

| 항목 | 값 | 의미 |
|---|---:|---|
| 표시 해상도 | `640 x 480` | 실제 visible area |
| 화면 주사율 | `60 Hz` | 초당 약 60프레임 |
| 수평 주파수 | `31.46875 kHz` | 초당 라인 주사 횟수 |
| 픽셀 클록 | `25.175 MHz` | 픽셀 단위 진행 기준 클록 |
| 한 줄 총 길이 | `800` pixel clocks | visible + porch + sync |
| 한 프레임 총 높이 | `525` lines | visible + porch + sync |

## VGA 타이밍 구조

VGA는 실제 색 데이터를 내보내는 visible 구간과, 화면 위치를 맞추기 위한 blanking 구간을 함께 사용한다. Blanking 구간에는 화면 데이터를 표시하지 않고, 전자빔 또는 표시 위치가 다음 줄/다음 프레임의 시작점으로 돌아간다.

| 구간 | 역할 |
|---|---|
| Visible Area | 실제 영상이 표시되는 구간 |
| Front Porch | 표시 종료 후 sync pulse 전 대기 |
| Sync Pulse | `H-Sync` 또는 `V-Sync` 동기화 펄스 |
| Back Porch | sync 종료 후 다음 표시 시작 전 대기 |
| Blanking | porch와 sync를 포함한 비표시 구간 |

`H-Sync`는 한 줄의 시작 위치를 맞추는 수평 동기 신호이고, `V-Sync`는 한 프레임의 시작 위치를 맞추는 수직 동기 신호다. FPGA 구현에서는 horizontal counter와 vertical counter를 두고, counter 값이 어느 구간에 있는지에 따라 RGB 출력과 sync 신호를 결정한다.

## 640x480 @ 60Hz 상세 타이밍

| 방향 | Visible | Front Porch | Sync Pulse | Back Porch | Total |
|---|---:|---:|---:|---:|---:|
| Horizontal | `640` | `16` | `96` | `48` | `800` |
| Vertical | `480` | `10` | `2` | `33` | `525` |

실제 표시 조건은 보통 `h_count < 640`이고 `v_count < 480`인 구간으로 잡는다. 이 구간에서만 RGB 값을 내보내고, 나머지 구간에서는 RGB를 0으로 두거나 display enable을 끈다.

## VGA 커넥터와 신호

VGA는 HD-DB15 커넥터를 사용하며, 색상 신호와 동기 신호가 분리되어 전달된다. RGB는 아날로그 전압 신호이고, `H-Sync`/`V-Sync`는 화면 위치를 맞추는 디지털 동기 신호다.

| 핀 | 신호 | 역할 |
|---:|---|---|
| `1` | Red | 적색 아날로그 신호 |
| `2` | Green | 녹색 아날로그 신호 |
| `3` | Blue | 청색 아날로그 신호 |
| `5`, `6`, `7`, `8`, `10` | GND | 접지 |
| `13` | Horizontal Sync | 수평 동기 |
| `14` | Vertical Sync | 수직 동기 |

## Basys 3 / Artix-7 구현 흐름

Basys 3는 Artix-7 FPGA 기반 보드이며, VGA 출력에서는 FPGA 내부 디지털 RGB 값을 저항 네트워크를 거쳐 아날로그 전압으로 변환한다. R, G, B를 각각 4비트씩 사용하면 총 12비트 색상, 즉 `2^12 = 4096`가지 색상을 표현할 수 있다.

| 구현 요소 | 내용 |
|---|---|
| 입력 클록 | 보드 기준 `100 MHz` |
| 픽셀 클록 | 분주 또는 clocking wizard로 약 `25 MHz` 생성 |
| 색상 출력 | `vgaRed[3:0]`, `vgaGreen[3:0]`, `vgaBlue[3:0]` |
| DAC 방식 | `510Ω`, `1kΩ`, `2kΩ`, `4kΩ` 가중치 저항 전압 분배 |
| 동기 출력 | `H-Sync`, `V-Sync` |
| 표시 제어 | visible 구간에서만 RGB 활성화 |

실습에서는 switch 입력을 `sw_red`, `sw_green`, `sw_blue` 같은 색상 선택 신호로 받아 화면 전체 색을 바꾸거나, counter 값에 따라 영역별 색을 다르게 출력하는 방식으로 시작할 수 있다.

## FPGA 내부 로직 관점

VGA controller의 핵심은 pixel clock 기준으로 horizontal counter와 vertical counter를 증가시키는 동작이다. Horizontal counter가 한 줄의 총 길이인 800에 도달하면 0으로 돌아가고 vertical counter가 1 증가한다. Vertical counter가 525에 도달하면 한 프레임이 끝나고 다시 0으로 돌아간다.

| 로직 | 역할 |
|---|---|
| Pixel clock generator | `100 MHz`에서 `25 MHz` 계열 클록 생성 |
| Horizontal counter | 한 줄 내 pixel 위치 추적 |
| Vertical counter | 프레임 내 line 위치 추적 |
| Sync generator | counter 범위에 따라 `H-Sync`, `V-Sync` 생성 |
| Display enable | visible area 여부 판단 |
| Color generator | switch, 좌표, 패턴에 따라 RGB 값 결정 |

## 수업 연결

- CRT 동작을 이해하면 VGA의 visible/blanking/sync 구조가 자연스럽게 이어진다.
- `640x480`만 세는 것이 아니라 total 값인 `800x525` 기준으로 counter를 설계해야 한다.
- `25.175 MHz`가 표준 값이지만, 실습에서는 보드 클록 `100 MHz`를 단순 분주해 `25 MHz` 근사값으로 사용하는 흐름이 나올 수 있다.
- RGB 출력은 디지털 4비트 값이지만 VGA 커넥터에서는 저항 DAC를 거친 아날로그 전압으로 전달된다.
- 실습 완료 후 코드와 화면 사진을 Classroom에 업로드해야 한다.

## 다음에 확인할 것

| 확인 항목 | 이유 |
|---|---|
| 실제 강의자료 파일명 | 원본 위치를 `_staging` README에 정확히 반영 |
| Basys 3 VGA XDC 핀명 | 수업 코드의 port 이름과 보드 제약 연결 |
| `H-Sync`, `V-Sync` active polarity | 모니터 표시 안정성 확인 |
| `25 MHz`와 `25.175 MHz` 차이 | 실습 모니터 호환성 확인 |
