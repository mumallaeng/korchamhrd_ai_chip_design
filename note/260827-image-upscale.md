# 26-08-27 - 이미지 업스케일 실습

관련 노트:

- [26-08-26 - 최종 프로젝트 팀 구성 공지와 VGA 컬러바 실습 리뷰](260826-final-project-team-formation-and-vga-color-bar-review.md)

실습 소스: [260827 IMAGE_UPSCALE](../helloHDL/260827_IMAGE_UPSCALE/)

> 수업일: `2026-08-27`
>
> 현재 상태: 업스케일 경로에 grayscale/binary filter를 순서대로 붙이고, pipelining 개념을 정리한 뒤 카메라(OV7670) 배선과 frame buffer 설계로 넘어감. write 모듈(카메라 → frame buffer)은 다음 시간 과제로 남음.

## 필터 위치 선정과 ISP 개념

pipeline 중 필터를 넣을 수 있는 위치는 한 곳으로 정해져 있지 않다. 데이터가 들어오는 지점, 원본을 그대로 보존하는 지점 등 여러 후보가 있고, 어디에 넣을지는 시스템 설계자가 그 시스템의 목적에 따라 정한다. 지금 만들고 있는 구조는 원본 데이터는 그대로 두고, 업스케일 필터를 거친 결과와 원본을 선택적으로 볼 수 있게 하는 방식이다.

이렇게 이미지를 다루는 시스템 전체를 통틀어 ISP(Image Signal Processing)라고 부른다. 필터, 색감 보정, 데이터 처리 등을 모두 포괄하는 용어로, CCTV 영상 처리나 자동차 자율주행, 로봇 분야 채용 공고에서 "ISP engineer"라는 표현으로 자주 등장한다.

## Grayscale 변환 공식

RGB를 grayscale(밝기)로 변환하는 표준 공식이 있다.

```text
Gray = 0.2126 * R + 0.7152 * G + 0.0722 * B
```

각 채널의 weight는 사람 눈이 밝기 정보 중 초록색에 가장 민감하다는 연구 결과에 따라 정해졌다 — 대략 레드 2, 그린 7, 블루 1의 비중이며 세 weight를 합치면 1이 된다.

하드웨어에서는 소수점 곱셈이 어렵기 때문에, weight의 합이 1이 아니라 256이 되도록 정수로 스케일링한 뒤 곱하고 우측 shift하는 방식을 쓴다. 비슷한 목적의 알고리즘(weight 조합)이 여러 가지 있고, 오늘은 그 중 하나를 골라 적용해보는 흐름으로 넘어갔다.

## Grayscale 하드웨어 구현

실제로 사용한 정수 weight는 R=77, G=150, B=29이며, 셋을 더하면 256이 된다.

```text
Y = (77 * R + 150 * G + 29 * B)
```

이 값을 계산한 뒤 256으로 나누는 대신, 하위 8비트를 버리고 상위 비트만 취하는 방식(우측 shift)으로 나눗셈을 대체한다. 이렇게 구한 Y 값 하나를 R, G, B 세 채널에 동일하게 넣어서 출력하면 grayscale 픽셀이 만들어진다.

## Grayscale 모듈 구현과 스위치 연결

앞서 정리한 공식을 실제 모듈로 만들었다. 입력으로 12비트 RGB 값을 받아 grayscale 계산을 수행하고, 결과를 gray RGB 출력 wire로 내보내는 구조다. 새 모듈을 만들 때마다 출력을 연결하는 wire를 별도로 선언해줘야 한다는 점을 다시 짚었다.

컬러 RGB와 gray RGB 두 출력을 스위치로 골라 쓸 수 있게 mux를 추가했다 — 스위치가 0이면 원본 컬러 RGB가, 1이면 gray RGB가 최종 출력으로 나가는 구조다. 처음 모듈을 붙였을 때 출력 wire를 실제 출력 포트에 연결하지 않아서 값이 안 나오는 실수가 있었고, 어디에 연결이 빠졌는지 확인하며 고쳐나갔다.

## Gray filter를 output register 뒤로 재배치

gray filter를 만드느라 시간이 걸렸는데, 그 뒤로 구조를 한 번 더 손봤다. 원래는 output register 앞에서 gray 계산을 하고 있었는데, 이걸 output register **뒤쪽**으로 옮기면 더 빠르게 만들 수 있다는 아이디어로 재배치했다.

즉 색상 데이터가 먼저 output register를 한 번 거치고, 그 register에서 나온 값을 그대로 내보내거나(스위치 0) gray filter를 한 번 더 거쳐서 내보내는(스위치 1) 구조로 바뀌었다. gray filter 자체도 곱셈·덧셈 단계를 pipeline register로 나눠뒀기 때문에, 필터를 거치는 경로와 거치지 않는 경로의 latency가 서로 달라지지 않도록 sync signal(h_sync/v_sync)도 필터 쪽 register 단수만큼 같이 지연시켜 맞춰준다.

## Pipelining: 왜 combinational logic을 나누는가

gray filter의 곱셈·덧셈·shift를 한 클럭 안에서 전부 처리하려고 하면, 그 계산 전체가 하나의 커다란 combinational logic이 된다. 이렇게 combinational logic이 길어지면 두 가지 문제가 생긴다.

- **Glitch**: 입력이 바뀐 순간부터 결과가 안정되기까지 걸리는 시간(propagation delay) 동안, 신호 경로마다 전파 속도가 달라서 나노초 단위의 원치 않는 스파이크가 섞여 나올 수 있다.
- **Negative slack**: combinational logic이 결과를 안정적으로 내는 데 걸리는 시간이 클럭 주기보다 길어지면, 다음 클럭이 너무 일찍 도착해서 계산이 끝나기 전의 불안정한 값을 그대로 읽어버려 결과가 이상하게 나온다.

해결책은 하나의 긴 combinational logic을 여러 단으로 잘라서 그 사이사이에 register(pipeline stage)를 끼우는 것이다. gray filter의 경우 "곱하기 → 더하기·shift" 두 단계로 나눠서, 1단에서 곱셈 결과를 register에 저장하고 2단에서 그 값들을 더하고 shift해서 출력한다. 이렇게 하면 클럭 한 주기 안에서 처리해야 할 combinational logic의 양이 줄어들어 회로가 훨씬 안정적으로 동작한다.

단점은 pipeline 단수만큼 결과가 늦게 나온다는 것이다(latency 증가). 그리고 RGB 데이터가 pipeline을 거치는 동안 h_sync/v_sync 같은 sync signal도 정확히 같은 클럭 수만큼 지연시켜 맞춰줘야 한다 — 안 그러면 색상 데이터와 sync signal의 타이밍이 어긋나서 화면이 이상하게 나온다.

pipeline 구조를 제대로 짤 줄 아는지는 반도체/설계 분야 면접에서도 자주 나오는 질문이라고 강조했다.

## Binary filter 추가

grayscale 다음 단계로 binary(흑백 이진화) filter를 추가했다. gray filter를 거친 값을 입력으로 받아, 미리 정해둔 threshold 값과 비교해서 그 값보다 크면 흰색(모든 비트 1), 작으면 검은색(모든 비트 0)으로 출력한다. 구현 자체는 comparator 하나로 끝나는 간단한 구조다. gray filter의 출력을 binary filter의 입력으로 이어붙이는 방식으로 두 필터를 chain처럼 연결했다.

binary filter는 gray filter와 달리 pipeline stage가 하나만 있으면 된다 — 비교 연산 자체가 combinational logic으로 봐도 부담이 크지 않은 수준이라, 곱셈처럼 여러 단으로 쪼갤 필요 없이 결과를 register 한 번만 거쳐 내보내면 충분하다. 그만큼 h_sync/v_sync에 걸어주는 지연도 한 클럭이면 된다.

## 다음 주제 예고: 카메라 입력을 frame buffer에 쓰기

오늘까지 만든 구조는 미리 저장해둔 이미지를 읽기만 하는 쪽(read)만 있다. 다음 단계는 작은 카메라 모듈(OV7670 계열로 추정)로 들어오는 영상을 메모리에 저장(write)한 뒤, 그 메모리를 그대로 읽어서 화면에 뿌리는 구조다. 지금 있는 "read" 부분은 그대로 재사용하고, 카메라 입력을 받아 메모리에 쓰는 "write" 부분만 새로 추가하면 카메라 영상이 화면에 나오게 된다는 설명이었다.

## 카메라 모듈 배선

다음 실습을 위해 카메라 모듈을 Basys3 보드에 직접 배선했다.

- **Data bus**: D0~D7 8개 핀을 보드 핀에 순서대로 연결한다. 꼭 D0부터 차례로 이어갈 필요는 없고, 카메라 쪽 D0~D7과 보드 쪽 대응 핀만 코드에서 맞게 지정하면 순서 자체는 상관없다.
- **Sync signal**: VSYNC와 HREF(HSYNC가 아니라 H reference 신호로 불리는 핀)가 있다. Clock 관련 핀(PCLK/XCLK 계열)도 있는데, 서로 역할이 다르니 구분해서 이해해야 한다고 짚었다.
- **Configuration interface**: I2C와 비슷한 2선(clock/data) 방식으로 카메라 register를 설정하는 핀이 별도로 있다. 지금 단계에서는 아직 연결하지 않고 다음에 다룬다.
- **RESET/PWDN**: 연결하지 않아도 동작에는 문제없다고 확인됐다.
- **Power**: 3.3V와 GND를 연결한다. GND는 아무 GND 핀에나 연결해도 되지만, VCC와 GND를 서로 바꿔 꽂으면 절대 안 된다 — 보드나 카메라가 급격히 뜨거워지며 고장 날 수 있다.
- **안전 수칙**: 배선하기 전에 Basys3 보드 전원을 반드시 끈다.

이후 학생들이 직접 배선하는 실습 시간으로 넘어갔다.

## OV7670 카메라 데이터시트 핵심

배선을 마친 뒤 OV7670 카메라 모듈의 데이터시트를 같이 읽었다. 지금 쓰는 모듈은 센서 품질이 아주 좋은 편은 아니지만, 카메라 인터페이스의 기본 개념 자체는 다른 카메라 모듈에도 거의 그대로 적용된다고 짚었다.

- **Clock**: FPGA가 clock generator로 XCLK(외부 clock, 보통 24MHz, 최대 40MHz까지 가능)을 만들어서 카메라에 넣어준다. 카메라는 이 XCLK을 받아 내부적으로 처리한 뒤, PCLK(pixel clock)를 다시 FPGA 쪽으로 내보낸다 — 즉 clock을 넣어주는 방향과 받는 방향이 서로 다르다.
- **Frame/line sync**: VSYNC는 low로 유지되다가 순간적으로 high로 뜨는 순간이 한 frame의 끝(동시에 다음 frame의 시작)을 의미한다. H-Reference(HREF, 데이터시트에는 HD로 표기)는 한 line(640픽셀) 동안 high를 유지하다가 그 line이 끝나면 low로 떨어진다 — VSYNC가 low이고 HREF가 high인 구간에서만 유효한 pixel data가 나온다는 뜻으로, DE(Display Enable)와 비슷한 역할이다.
- **Pixel data format**: data bus(D0~D7, 8비트)로 한 pixel을 2바이트에 나눠 보낸다. PCLK 상승 edge마다 한 바이트씩 나오고, 두 바이트를 합쳐야 하나의 pixel(RGB565, 16비트)이 완성된다. 첫 번째 바이트는 R(5비트)+G 상위 3비트, 두 번째 바이트는 G 하위 3비트+B(5비트)로 나뉜다.
- 출력 해상도는 설정에 따라 VGA/QVGA/QQVGA 등으로 바뀔 수 있는데, 오늘은 SCCB(I2C와 호환되는 카메라 설정 인터페이스) 설정이 이미 끝나서 QVGA·RGB 모드로 나온다고 가정하고 진행했다.
- 지금 카메라 설정(SCCB)을 NUCLEO 보드로 대신 처리하는 이유는 현재 FPGA 쪽에 I2C가 아직 구현되어 있지 않기 때문이다. 나중에 FPGA 보드에 I2C를 직접 구현하면 그때는 NUCLEO 보드 없이도 카메라 설정까지 FPGA만으로 끝낼 수 있다.

## 프레임 버퍼(듀얼 포트 메모리) 설계 시작

frame buffer가 필요한 이유를 clock 도메인 차이로 정리했다 — 카메라는 30fps, VGA 출력은 60fps로 서로 frame rate가 다르기 때문에 카메라 데이터를 VGA 쪽에 바로 연결할 수 없고, 서로 다른 clock 도메인 사이에서 FIFO/queue가 흔히 하는 것처럼 frame buffer가 중간에서 버퍼 역할을 해준다.

카메라 write 경로와 VGA read 경로는 이렇게 서로 다른 clock 도메인에서 동작하기 때문에, 하나의 메모리를 read 전용 주소·write 전용 주소로 나누고 각각 별도의 clock을 받는 dual-port 메모리 구조로 설계를 시작했다. write 쪽에는 address, pixel data, H-Reference, VSYNC가 들어가고, 카메라에 XCLK을 공급하는 clock generator도 이 모듈에 같이 필요하다.

지금까지 만든 read 쪽(frame buffer → VGA 출력)은 이미 완성된 상태이고, 남은 건 write 쪽(카메라 → frame buffer에 저장) 모듈뿐이다. 이 write 모듈은 과제로 남겨졌다 — PCLK edge가 들어올 때마다 데이터가 유효하다고 보고, 그 데이터가 pixel의 첫 번째/두 번째 바이트인지 구분해서 16비트 pixel data로 합쳐 저장하는 방식으로 만들면 된다는 힌트를 줬다. 다음 시간에 강사와 함께 만들어보되, 그 전에 각자 먼저 시도해보라는 과제다.

오늘 수업은 여기서 마무리됐고, 다음 주 수업에서 이어가기로 했다.
