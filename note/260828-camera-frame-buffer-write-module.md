# 26-08-28 - 카메라 write 모듈과 frame buffer 실습

관련 노트:

- [26-08-27 - 이미지 업스케일 실습](260827-image-upscale.md)

> 수업일: `2026-08-28`
>
> 현재 상태: 어제 과제로 남았던 카메라(OV7670) → frame buffer write 모듈을 실제로 만드는 실습 진행.

## Write 타이밍 정리: PCLK/HREF 조건

카메라 데이터를 읽어들이는 조건을 다시 정리했다.

- 유효한 데이터를 읽는 조건은 **HREF가 high**이고 **PCLK의 rising edge**가 발생하는 순간이다. 이 두 조건이 동시에 만족할 때만 data bus 값을 읽는다.
- HREF가 low인 구간의 데이터는 무효(invalid)하므로 읽을 필요가 없다. HREF가 high인 구간만 유효 데이터가 나오는데, 어제 배운 DE(Display Enable) 신호와 같은 개념으로 보면 된다.
- 데이터는 RGB565 포맷(16비트)으로 받지만 data bus는 8비트라서, 한 pixel을 8비트씩 두 번(첫 번째 byte, 두 번째 byte) 나눠 받는다. 두 byte를 합쳐야 하나의 pixel(16비트)이 완성되고, 그 결과를 memory에 저장한다.
- 그래서 write 모듈은 지금 들어오는 byte가 pixel의 첫 번째인지 두 번째인지 판단하는 상태를 가져야 한다.
- VSYNC는 low로 유지되다가 순간적으로 high로 뜨는 게 한 frame의 끝(동시에 다음 frame의 시작)을 의미한다 — 어제 정리한 내용과 동일.

## Frame buffer는 dual-port RAM, 중심에는 CDC

frame buffer는 한 frame을 저장하는 memory인데, 실제로는 **dual-port RAM**이다. 저장(write)도 되고 읽기(read)도 되는 memory로, port가 두 개라서 clock도 두 곳에서 따로 들어온다 — 하나는 write clock, 하나는 read clock.

- 왼쪽(write 쪽)은 카메라 clock 도메인, 오른쪽(read 쪽)은 VGA(+ 전체 출력 시스템) clock 도메인이다. 서로 다른 두 clock 도메인이 공존하기 때문에 한쪽 신호를 다른 쪽에 그냥 연결할 수 없고, 그 경계에 memory를 놓아서 다리 역할을 하게 한 것이다.
- 이 memory를 중심에 두고 생각하면 구조가 명확해진다 — 이 지점이 바로 **CDC(Clock Domain Crossing)** 구간이다.
- write 쪽에 필요한 신호: write enable, write address, write data(카메라에서 받은 pixel data).
- 카메라(OV7670)가 동작하려면 외부에서 clock(XCLK)을 만들어 넣어줘야 한다는 것도 다시 짚었다 — 어제 배운 내용과 동일한 clock generator가 필요하다.

## I2C/SCCB 설정을 FPGA 내부로 옮기는 방향

지금까지는 NUCLEO(STM32) 보드로 카메라 SCCB 설정(레지스터 설정 → RGB565, QVGA 모드 등)을 대신 처리해왔다. 이유는 FPGA 쪽에 I2C 모듈과 설정 값이 아직 없었기 때문이다.

- 강사가 갖고 있는 카메라 설정용 코드(레지스터 초기화 값)를 학생들에게 공유해서, STM32 쪽 프로젝트에 반영하는 방식으로 우선 진행했다.
- 다음 단계로는 이 설정 로직 자체를 FPGA 내부로 옮기는 것이 목표다 — 기존에 만들어둔 I2C master 모듈을 재사용해서 SCCB 설정 절차를 FPGA에서 직접 처리하도록 구현하면, NUCLEO 보드 없이도 카메라 설정까지 끝낼 수 있다.
- 이후 Vivado를 띄워서 write 모듈을 직접 코딩하는 실습으로 넘어갔다.

## SCCB 설정 FSM: 주말 과제

기존 STM32(NUCLEO) 코드가 카메라에 SCCB로 보내는 실제 신호를 logic analyzer로 캡처해서, 그 write 시퀀스만 그대로 참고해 FPGA용 SCCB 설정 FSM을 만드는 게 주말 과제로 나왔다.

- 이미 만들어져 있는 I2C master 모듈을 그대로 갖다 쓰면 되고, 새로 만들어야 하는 건 "레지스터 주소·값 목록을 순서대로 I2C master에 태워 보내는" FSM(SCCB setup controller)뿐이다 — 이미 절반은 준비된 셈이다.
- SCCB 프로토콜 자체는 단순하다: **디바이스 주소 → 레지스터 주소 → 데이터 값** 세 개를 한 묶음으로 보내고, 이 묶음을 레지스터 개수만큼 반복해서 순서대로 보내면 끝이다.
- 참고 중인 STM32 C 코드의 레지스터 테이블은 마지막에 `0xFF, 0xFF`로 끝난다 — FSM은 이 종료 마커(0xFF/0xFF)가 나올 때까지 계속 다음 레지스터·값 쌍을 읽어서 보내는 식으로 루프를 돌리면 된다.
- **주의사항**: OV7670에 소프트웨어 리셋 명령을 보낸 뒤에는 최소 30ms를 기다렸다가 SCCB 설정 데이터를 보내야 한다. 이 딜레이를 안 넣으면 카메라 설정이 됐다 안 됐다 하는 간헐적 오동작이 발생한다.
- 레지스터 값 하나하나를 외우는 게 중요한 게 아니라, 이 SCCB 설정 절차를 FSM으로 구현할 수 있는지 이해하는 게 핵심이라고 강조했다. OV7670 데이터시트에 각 레지스터 의미가 나와 있으니 필요할 때 참고하면 된다고 했다.
- I2C는 면접에서 사실상 항상 나오는 단골 질문(FSM을 직접 그려보라는 요청까지 포함)이라, 남이 짠 코드를 베끼지 말고 직접 만들어봐야 실제로 설명할 수 있다는 점을 여러 번 강조했다.

## 실습 소스: [260828 OV7670_Basic](../helloHDL/260828_OV7670_Basic/)

실제로 만들면서 나온 이슈와 수정 내역.

- **핀 배정 차이**: 수업 코드는 `cam_href`/`cam_vsync`/`xclk`/`pclk`를 Pmod JB에, `cam_data[7:0]`을 JC에 연결하는 기준이었는데, 실제 배선은 책상 배치상 보드를 왼쪽에 두는 게 편해서 의도적으로 JA와 JXADC를 썼다. 그래서 XDC를 JA/JXADC 핀 번호에 맞게 다시 작성했다.
- **`xclk` 미연결**: `pclk_gen`이 만든 clock을 카메라로 나가야 할 `xclk`가 아니라 카메라에서 들어오는 입력 `pclk`에 잘못 연결해서, 카메라에 clock이 전혀 안 들어가고 있었다.
- **`framebuffer`의 write/read clock 미선언**: `wclk`/`rclk`라는 이름으로 연결했는데 그 신호 자체가 선언돼 있지 않았다. write는 카메라 쪽 `pclk`, read는 시스템 `clk`로 연결.
- **`h_sync`/`v_sync` 이중 구동**: `VGA_Decoder` 출력이 top-level 포트에 직접 연결돼 있는데 `VGA_OutReg`도 같은 포트를 구동해서 충돌. `VGA_Decoder` 출력을 중간 wire로 받아서 `VGA_OutReg`만 최종 포트를 구동하도록 정리.
- **RGB wire 오타/폭 문제**: 참조되는 신호는 `w_rgb`(12비트)인데 실제 선언은 `w_rbg`(오타, 11비트)였다. 이름과 폭 모두 수정.
- **`x_pixel`/`y_pixel` 폭 오류**: top에서 9비트로 선언했는데 `VGA_Decoder`/`framebuffer_reader`는 10비트를 쓴다. 800줄까지 세는 카운터라 9비트로는 MSB가 잘려서 화면 하단이 깨지는 문제로 이어질 뻔했다. 10비트로 수정.
- **Implementation 단계 clock 배치 에러**: `pclk`가 물린 물리 핀(Pmod JA10)이 clock-capable 핀이 아니라서 BUFG로 가는 dedicated 경로를 못 잡고 placement가 실패했다. Vivado가 제시하는 표준 우회법대로 XDC에 `set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets pclk_IBUF]`를 추가해서 해결(synthesis 단계에서는 이 net이 아직 없어서 나는 경고는 무시해도 되는 정상 동작).
- 이 수정들을 반영한 뒤 synthesis는 0 errors/0 warnings로 통과했고, 최종 bitstream 생성은 원격 PC 메모리 여유가 부족해 잠시 지연됨 — 다시 시도 예정.
