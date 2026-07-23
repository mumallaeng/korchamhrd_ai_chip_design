# 26-07-23 - 15과 ADC·Sensor Interface

관련 노트:

- [26-07-22 - 13과 I2C·14과 SPI Interface](260722-i2c-spi-interface.md)
- [26-07-21 - Startup·Interrupt·Event-Driven Firmware](260721-interrupt-event-driven.md)
- [15과 ADC source](../helloEmbedded/1501.ADC_EX/) · [ADC `main.c`](../helloEmbedded/1501.ADC_EX/main.c) · [ADC driver](../helloEmbedded/1501.ADC_EX/adc.c) · [bit-field macro](../helloEmbedded/1501.ADC_EX/macro.h) · [clock option](../helloEmbedded/1501.ADC_EX/option.h)

## 수업 범위

| 과 | 주제 | 실습 |
| :--- | :--- | :--- |
| 15과 | ADC·Sensor Interface | `PA6 / ADC1_IN6` 가변저항 전압을 polling으로 읽어 UART 출력 |

## 실습 code 연결

`1501.ADC_EX`는 GPIO input pin을 `analog mode`로 전환하고, ADC1 regular conversion sequence에 channel 6을 넣은 뒤, software start와 `EOC` polling으로 `ADC1->DR` 값을 읽는 bare-metal firmware다. 가변저항은 `3.3V`와 `GND` 사이의 전압 분배기로 연결하고, 가운데 출력인 `Vout`을 `PA6 / ADC1_IN6`으로 넣는다.

## ADC와 센서 인터페이스 회로

### ADC 개념

`ADC`는 `Analog-to-Digital Converter`로, 연속적인 analog voltage를 digital value로 변환한다. MCU는 sensor 출력 전압을 직접 의미 있는 물리량으로 이해하지 못하므로, ADC를 통해 정수값으로 변환한 뒤 software에서 해석함.

```text
Sensor voltage
    |
    v
ADC input pin
    |
    v
sample and hold
    |
    v
ADC conversion
    |
    v
digital value in ADC_DR
```

STM32F411 ADC는 12/10/8/6bit resolution을 선택할 수 있고, channel별 sampling time을 설정할 수 있다. 입력 전압 범위는 기준 전압 사이여야 함.

ADC는 digital 회로의 잡음과 분리하기 위해 별도의 아날로그 전원·기준 pin을 가진다.

| Pin | 역할 | 실습 board 연결 |
| :--- | :--- | :--- |
| `VDDA`, `VSSA` | 아날로그 전원과 ground | digital `VDD`/`VSS`에 함께 연결 |
| `VREF+` | ADC 상한 기준 전압 | `VDDA`에 연결 |
| `VREF-` | ADC 하한 기준 전압 | `VSSA`에 연결 |

정밀한 측정이 필요한 회로에서는 `VDDA`를 filter를 거쳐 분리하거나 별도 기준 전압원을 `VREF+`에 공급하지만, 실습 board처럼 digital 전원과 공유하면 그 잡음이 ADC 결과에 그대로 반영될 수 있다.

| 항목 | 내용 |
| :--- | :--- |
| Resolution | 12bit, 10bit, 8bit, 6bit 선택 |
| Input range | `VREF- <= VIN <= VREF+` |
| Channel | 여러 analog input을 하나의 ADC가 순차 변환 |
| Sampling time | channel별 sampling cycle 설정 |

12bit ADC에서는 변환 결과가 `0`~`4095` 범위다.

```text
ADC code = VIN / VREF * 4095

VIN = 0V      -> 0
VIN = VREF/2  -> 약 2048
VIN = VREF    -> 4095
```

#### ADC 값은 전압이고, 전압은 다시 물리량으로 환산한다

ADC code는 sensor의 온도·빛·압력을 직접 나타내는 값이 아니다. 기준 전압으로 나눈 input voltage의 양자화 결과다. 먼저 code를 voltage로 되돌리고, 그 뒤 sensor data sheet의 전달식으로 물리량을 계산한다.

```text
VIN  ≈ ADC_code / (2^resolution - 1) * VREF+
sensor value = sensor-specific function(VIN)
```

12bit, `VREF+ = 3.3V`, `ADC_code = 2048`이면 `VIN`은 약 `1.65V`다. 1 LSB의 전압 크기는 약 `3.3V / 4096 = 0.806mV`지만, 이것이 곧 실제 측정 정확도는 아니다. VREF 오차, sensor 오차, analog noise, PCB ground, sampling time이 함께 결과를 좌우함.

ADC 내부 sample-and-hold capacitor는 sampling time 동안 input source에서 충전된다. 가변저항을 너무 큰 저항값으로 사용하거나 sensor output impedance가 높으면 capacitor가 충분히 충전되기 전에 conversion이 시작되어 오차가 커질 수 있다. 그래서 channel별 sampling time을 입력 source 특성에 맞춰 잡고, 필요하면 buffer amplifier·RC filter·여러 번 측정한 평균을 사용함.

### 가변저항 입력 회로

실습에서는 가변저항을 전압 분배기로 사용하여 `PA6`, `ADC1_IN6`에 analog voltage를 넣는다.

```text
3.3V
  |
 [R1]
  |
  +---- Vout ---- PA6 / ADC1_IN6
  |
 [R2]
  |
 GND

Vout = 3.3V * R2 / (R1 + R2)
```

가변저항 knob를 돌리면 `R1:R2` 비율이 변하고, 이에 따라 `Vout`과 ADC 변환값이 함께 변한다.

### PA6 Analog Input 설정

GPIO pin을 ADC input으로 쓰려면 해당 pin을 analog mode로 설정한다. `PA6`은 `MODER[13:12] = 11`로 설정함.

```text
GPIOA MODER for PA6

bit13 bit12
  0     0    input
  0     1    output
  1     0    alternate function
  1     1    analog
```

Analog mode에서는 digital input buffer를 우회하거나 비활성화하여 analog 신호를 ADC로 전달하는 구조로 이해하면 된다.

#### ADC 변환 mode와 data 관리

실습의 `PA6 → ADC1_IN6`은 한 channel을 software start로 한 번 변환하고 `EOC`를 polling하는 가장 단순한 regular conversion이다. ADC peripheral은 이 기본 형태를 기준으로 연속 변환, 여러 channel scan, 외부 trigger, interrupt/DMA 전달로 확장할 수 있다.

| mode | hardware 동작 | software가 설계할 것 |
| :--- | :--- | :--- |
| single regular conversion | `SWSTART` 뒤 sequence 한 번 실행 | `EOC` 확인 후 `DR` read |
| continuous conversion | sequence가 끝난 뒤 자동 재시작 | 최신 data만 볼지, sample rate를 제한할지 결정 |
| scan sequence | 설정한 여러 channel을 순서대로 변환 | `SQR1/2/3` 순서와 각 channel sampling time 설정 |
| external trigger | timer 등 외부 event가 시작 시점 결정 | sensor sample 시점을 시간 기준과 동기화 |
| interrupt/DMA | `EOC` 또는 DMA request가 data 전달 | ISR을 짧게 유지하거나 memory buffer·overrun 처리 |

`ADC_DR`은 마지막 regular conversion 결과가 놓이는 data register다. CPU가 늦게 읽으면 다음 conversion이 기존 값을 덮어쓸 수 있으므로, 빠른 연속 sampling에서는 polling보다 DMA circular buffer가 적합할 수 있다. analog watchdog은 conversion code가 설정한 high/low threshold 밖으로 나갔을 때 event를 내는 기능으로, 온도·전압이 허용 범위를 벗어났는지 CPU가 매번 계산하지 않고 감지할 때 사용함.

### ADC1_IN6 Driver 함수

ADC1 channel 6 초기화 흐름은 다음과 같다.

```text
1. GPIOA clock enable
2. PA6 analog mode 설정
3. ADC1 clock enable
4. CH6 sampling time 설정
5. conversion sequence 길이 1로 설정
6. sequence 첫 channel을 CH6으로 설정
7. ADC common clock 설정
8. ADC1 enable
```

핵심 register 설정은 다음과 같음.

| Register | 설정 |
| :--- | :--- |
| `GPIOA->MODER` | `PA6` analog mode |
| `ADC1->SMPR2` | channel 6 sampling time, `480 cycles` |
| `ADC1->SQR1` | conversion sequence length |
| `ADC1->SQR3` | first conversion channel = 6 |
| `ADC->CCR` | ADC clock prescaler, `0x2`는 `PCLK2/6` |
| `ADC1->CR2` | `ADON`, `SWSTART` |
| `ADC1->SR` | `EOC`, `STRT` 등 상태 |
| `ADC1->DR` | conversion result |

ADC clock은 `PCLK2`를 `CCR`의 prescaler로 나눠 만든다. 실습 설정 `0x2`는 `/6` 분주라 `96MHz / 6 = 16MHz`이며, ADC가 허용하는 최대 clock을 넘지 않도록 이 분주를 정한다.

### Regular Sequence·상태 flag 읽기

`ADC1->SQR1.L[3:0]`은 regular conversion 개수에서 `1`을 뺀 값이다. 이 실습은 `L = 0`으로 써서 conversion을 한 번만 실행한다. 여러 channel을 scan하려면 `L`을 늘리고 `SQR3 → SQR2 → SQR1`의 `SQ1`~`SQ16` field에 읽을 channel 번호를 순서대로 넣는다.

```text
SQR1.L = 0        -> conversion 1회
SQR3.SQ1 = 6      -> 첫 번째 conversion은 channel 6

ADC1->CR2.ADON    -> ADC peripheral enable
ADC1->CR2.SWSTART -> regular conversion 시작
ADC1->SR.EOC      -> conversion 완료
ADC1->DR[11:0]    -> 이번 conversion 결과
```

현재 source는 `CR1.RES` field를 별도로 바꾸지 않아 reset 기본값인 12bit를 사용한다. 따라서 `ADC1_Get_Data()`는 `DR`의 하위 12bit만 추출하며, 가능한 code 범위는 `0x000`~`0xFFF`다.

`ADC1_Get_Status()`는 `SR` bit `1`의 `EOC`를 확인하고, 완료되었으면 `EOC`와 bit `4`의 `STRT`를 clear한 뒤 `1`을 반환한다. `OVR`은 bit `5`이므로 이 예제에서 clear하는 bit `4`와 구분해서 읽는다.

```c
void ADC1_IN6_Init(void)
{
    Macro_Set_Bit(RCC->AHB1ENR, 0);
    Macro_Write_Block(GPIOA->MODER, 0x3, 0x3, 12);

    Macro_Set_Bit(RCC->APB2ENR, 8);
    Macro_Write_Block(ADC1->SMPR2, 0x7, 0x7, 18);
    Macro_Write_Block(ADC1->SQR1, 0xF, 0x0, 20);
    Macro_Write_Block(ADC1->SQR3, 0x1F, 6, 0);
    Macro_Write_Block(ADC->CCR, 0x3, 0x2, 16);

    Macro_Set_Bit(ADC1->CR2, 0);
}

void ADC1_Start(void)
{
    Macro_Set_Bit(ADC1->CR2, 30);
}

int ADC1_Get_Status(void)
{
    int r = Macro_Check_Bit_Set(ADC1->SR, 1);

    if (r)
    {
        Macro_Clear_Bit(ADC1->SR, 1);
        Macro_Clear_Bit(ADC1->SR, 4);
    }

    return r;
}

int ADC1_Get_Data(void)
{
    return Macro_Extract_Area(ADC1->DR, 0xFFF, 0);
}
```

`Main()`은 UART를 먼저 준비한 뒤 conversion을 시작하고 `EOC` 상태를 기다려 `DR`의 하위 12bit 값을 출력한다. source의 빈 loop는 출력이 너무 빠르게 반복되지 않도록 둔 단순 delay다.

```c
void Main(void)
{
    Sys_Init(115200);
    printf("ADC Test\n");

    volatile int i;
    ADC1_IN6_Init();

    for (;;)
    {
        ADC1_Start();

        while (!ADC1_Get_Status())
            ;

        printf("0x%.4X\n", ADC1_Get_Data());

        for (i = 0; i < 0x400000; i++)
            ;
    }
}
```

가변저항을 돌리면 출력값이 `0x0000` 근처에서 `0x0fff` 근처까지 변한다. 실제 최솟값과 최댓값은 보드 전원, 회로 오차, 가변저항 상태에 따라 약간 달라질 수 있음.

## 정리

이번 범위의 핵심은 MCU 제어 코드가 단순히 C 문법만으로 동작하는 것이 아니라, 회로와 주소 기반 레지스터 제어를 전제로 한다는 점이다.

```text
전자 소자와 논리 회로
    ↓
IC, ASIC, SoC
    ↓
CPU, 메모리, 주변장치
    ↓
MCU와 memory map
    ↓
Memory-Mapped I/O
    ↓
GPIO 레지스터 직접 제어
    ↓
ADC peripheral 제어
```

GPIO 제어에서는 pin 번호, 레지스터 base address, offset, bit 위치, 회로의 active-high/active-low 조건을 함께 봐야 한다. 같은 LED 제어라도 회로가 active-high인지 active-low인지에 따라 `ODR`에 써야 하는 값과 output type 선택이 달라짐.

뒤쪽 peripheral도 같은 방식으로 이어진다. 먼저 clock을 켜고, pin mode나 alternate function을 맞춘 뒤, peripheral register를 설정하고, status flag와 data register를 읽고 쓰면서 동작을 확인한다.

```text
clock enable
    ↓
GPIO pin mode 또는 alternate function 설정
    ↓
peripheral register 설정
    ↓
status flag 확인
    ↓
data register read/write
    ↓
pending flag clear 또는 다음 transaction 진행
```

`ADC`는 analog sensor voltage를 digital value로 바꾼다. 이 실습도 `base address + register offset + bit field + 회로 연결`을 함께 읽는 훈련으로 이어진다.
