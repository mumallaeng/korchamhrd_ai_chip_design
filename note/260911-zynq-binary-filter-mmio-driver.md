# 26-09-11 - Zynq binary filter MMIO driver와 register access macro

관련 노트:

- [26-09-10 - AXI4-Stream 영상 구간과 그레이스케일 필터 RTL·블록 삽입](260910-axi-stream-video-region-grayscale-filter-insertion.md)
- [[domains/semiconductor/ai-npu-system-integration/c-pointer-struct-mmio-gpio-register-access]]
- [[domains/semiconductor/ai-npu-system-integration/gpio-register-mmio-cr-idr-odr]]
- [[domains/semiconductor/ai-npu-system-integration/fpga-board-physical-intuition-and-hw-sw-layer-map]]

> 수업일: `2026-09-11`
>
> 현재 상태: Vitis의 `pcam_hdmi` application에서 binary filter용 software driver를 작성했다. `xparameters.h`가 제공하는 IP base address와 내부 register offset을 분리하고, 직접 pointer dereference로 수행하던 MMIO access를 `Xil_Out32`·`Xil_In32` 및 `WR`·`RD` macro로 감쌌다. 초기화 함수에서는 control register와 threshold register를 설정하고, 이후 control bit를 보존하며 enable 상태를 변경하는 흐름까지 확인했다. 화면 녹화에서 코드 작성 과정은 확인되지만 실제 board 출력과 UART 실행 결과는 확인되지 않았으므로 구현 완료로 단정하지 않는다.

## 수업 범위

| 구분 | 내용 |
| :--- | :--- |
| 대상 | `pcam_hdmi/src/bin_filter/bin_filter.c`의 binary filter software driver |
| hardware address | `xparameters.h`의 `XPAR_BIN_FILTER_V1_0_BASEADDR` 사용 |
| register map | control register `0x00`, threshold register `0x04` |
| control bit | enable `bit 0`, invert `bit 1` |
| MMIO write/read | `Xil_Out32(address, value)`, `Xil_In32(address)` |
| driver abstraction | `base address + offset` 계산을 `WR(off, value)`·`RD(off)` macro로 감춤 |
| 상태 관리 | `ready`와 `ctrl_shadow`로 초기화 여부와 control bit 상태 관리 |

## 1. Base address와 register offset

Binary filter IP 전체를 선택하는 주소와 IP 내부 register를 선택하는 offset을 분리한다.

```c
#define BINF_BASE  XPAR_BIN_FILTER_V1_0_BASEADDR
#define BINF_CR    0x00u
#define BINF_THR   0x04u
```

실제 register address는 다음 관계로 계산된다.

```text
register address = BINF_BASE + register offset
```

| 이름 | 역할 |
| :--- | :--- |
| `BINF_BASE` | Vivado address map에서 binary filter IP에 할당된 시작 주소 |
| `BINF_CR` | filter 동작을 제어하는 control register offset |
| `BINF_THR` | binary 변환 기준값을 저장하는 threshold register offset |

Base address는 IP instance 전체의 위치이고, offset은 그 IP 안의 특정 register 위치다. `xparameters.h`의 symbol을 사용하면 Vivado에서 export된 hardware address와 software가 같은 값을 공유할 수 있다.

## 2. Control bit mask

화면에서 control register의 두 기능을 bit mask로 정의했다.

```c
#define CTRL_EN      0x00000001u
#define CTRL_INVERT  0x00000002u
```

| mask | 대상 bit | 의미 |
| :--- | :---: | :--- |
| `CTRL_EN` | 0 | binary filter enable |
| `CTRL_INVERT` | 1 | binary output polarity invert |

`u` suffix는 정수 literal을 unsigned로 취급하라는 뜻이다. Register와 mask의 자료형을 `u32` 계열로 맞추면 signed 연산이 섞이는 위험을 줄일 수 있다.

## 3. 직접 pointer access와 Xilinx MMIO 함수

수업에서는 control register write를 두 방식으로 비교했다.

```c
*(volatile u32 *)(BINF_BASE + BINF_CR) = ctrl_shadow;
```

```c
Xil_Out32(BINF_BASE + BINF_CR, ctrl_shadow);
```

두 표현은 같은 MMIO register에 32-bit 값을 쓰려는 목적을 가진다. 직접 pointer 방식에서는 주소 cast, `volatile`, dereference를 코드가 직접 책임진다. `Xil_Out32`는 Xilinx standalone BSP가 제공하는 register access 함수이므로 호출 의도가 더 명확하고 platform이 제공하는 접근 방식을 재사용할 수 있다.

Read에는 다음 함수를 사용한다.

```c
u32 value = Xil_In32(BINF_BASE + BINF_CR);
```

`Xil_Out32`의 첫 번째 인자는 address이고 두 번째 인자는 write value다. `Xil_In32`는 address를 받아 해당 위치의 32-bit 값을 반환한다.

## 4. IP 전용 WR·RD macro

Base address를 매 호출마다 반복하지 않도록 binary filter 전용 macro를 만들었다.

```c
#define WR(off, v) \
    Xil_Out32((UINTPTR)(BINF_BASE + (off)), (u32)(v))

#define RD(off) \
    Xil_In32((UINTPTR)(BINF_BASE + (off)))
```

사용 코드는 다음처럼 register offset과 값에 집중할 수 있다.

```c
WR(BINF_CR, ctrl_shadow);
WR(BINF_THR, threshold);

u32 control = RD(BINF_CR);
```

| cast | 목적 |
| :--- | :--- |
| `UINTPTR` | address를 target pointer 폭에 맞는 unsigned integer type으로 전달 |
| `u32` | register에 기록할 값을 32-bit unsigned type으로 전달 |

이 macro는 단순한 축약이다. `WR(BINF_CR, value)`가 내부적으로 `BINF_BASE + BINF_CR` 주소에 값을 쓴다는 사실은 register map과 함께 유지해야 한다.

## 5. 초기화 흐름

화면에서 확인한 `binf_init()`의 흐름은 다음과 같다.

```text
이미 ready인가?
  ├─ yes → XST_SUCCESS 반환
  └─ no
      → ctrl_shadow = 0
      → control register write
      → threshold 기본값 write
      → ready = 1
      → 초기화 정보 출력
      → XST_SUCCESS 반환
```

`ready`는 software driver가 초기화를 한 번 수행했는지 나타낸다. 이 변수만으로 실제 IP가 정상 동작함을 증명하지는 않는다. Hardware 확인이 필요하면 version/status register readback, UART log, 화면 출력 또는 별도의 self-test가 필요하다.

## 6. Shadow register와 read-modify-write

`ctrl_shadow`는 software가 control register의 현재 의도값을 보존하는 복사본이다. Enable bit만 변경할 때 다른 control bit를 유지하기 위해 bitwise OR와 AND를 사용한다.

```c
if (on) {
    ctrl_shadow |= CTRL_EN;
} else {
    ctrl_shadow &= ~CTRL_EN;
}

WR(BINF_CR, ctrl_shadow);
```

| 표현 | 동작 |
| :--- | :--- |
| `ctrl_shadow |= CTRL_EN` | enable bit를 `1`로 설정하고 다른 bit 보존 |
| `ctrl_shadow &= ~CTRL_EN` | enable bit만 `0`으로 지우고 다른 bit 보존 |

매번 control register 전체에 상수 `0` 또는 `1`을 쓰면 invert 같은 다른 bit 상태가 사라질 수 있다. Shadow 값을 수정한 뒤 전체 register에 쓰는 방식은 여러 제어 bit를 함께 관리할 때 유용하다.

단, hardware가 control register 값을 자체적으로 변경하거나 write-one-to-clear bit를 포함한다면 software shadow와 실제 register가 달라질 수 있다. 그런 register는 datasheet의 bit별 read/write semantics에 맞는 별도 처리가 필요하다.

## 7. Software driver와 RTL register의 연결

```text
Vitis C code
  → WR(offset, value)
  → Xil_Out32(base + offset, value)
  → PS의 AXI master transaction
  → AXI interconnect address decode
  → binary filter AXI4-Lite slave register
  → RTL control signal
  → AXI4-Stream pixel processing behavior
```

Software의 `BINF_CR`, `BINF_THR` offset과 RTL IP의 register map이 다르면 compile은 성공해도 의도한 hardware가 제어되지 않는다. 따라서 C header와 RTL register specification은 같은 주소·bit 정의를 사용해야 한다.

## 8. 확인할 사항

- [ ] `BINF_BASE`가 현재 export된 XSA의 `xparameters.h`와 일치하는지 확인
- [ ] RTL의 `0x00`, `0x04` register 역할과 C macro가 일치하는지 확인
- [ ] threshold 기본값과 허용 범위를 register specification에 명시
- [ ] `binf_init()`의 반환문과 compile warning 확인
- [ ] `binf_set(1)`·`binf_set(0)`으로 binary/passthrough 전환 확인
- [ ] invert bit 변경 시 `CTRL_EN` 상태가 보존되는지 확인
- [ ] UART log의 base address와 threshold 출력 확인
- [ ] 실제 HDMI 화면에서 threshold·invert·enable 결과 확인

## 녹화 검토 메모

- 오전 11시 36분 녹화는 약 13분 54초이며 Vitis의 `bin_filter.c` 작성 화면을 담고 있다.
- 음성은 base address, control/threshold offset, `Xil_Out32`, `Xil_In32`, `WR`·`RD` macro 설명을 판독할 수 있었다.
- 자동 전사는 약 5분 이후 같은 문장을 반복 생성해 신뢰할 수 없었다. 해당 구간은 화면 프레임으로 코드 진행을 확인하고, 화면에서 식별되지 않은 세부 구현은 노트에 확정 사실로 추가하지 않았다.
- 녹화에서는 편집 중인 syntax error 표시가 중간에 보이지만 이후 코드가 계속 수정됐다. 최종 build·board 동작 성공 여부는 영상만으로 확인되지 않았다.
