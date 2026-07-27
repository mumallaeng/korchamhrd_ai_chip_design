#include "stm32f4xx.h"
#include "servo.h"
#include "servo_pwm.h"
#include "uart2.h"
#include "adc1.h"
#include "joystick.h"
#include "systick.h"

#define USER_LED_PIN 5U
#define CONTROL_TICK_MS 10U

void _Invalid_ISR(void) // startup vector table의 exception(interrupt) 기본 처리
{
    while (1)
        ;
}

void testudines(void)
{
    uint32_t last_tick_ms;

    RCC->AHB1ENR |= RCC_AHB1ENR_GPIOAEN;

    GPIOA->MODER &= ~GPIO_MODER_MODER5_Msk;
    GPIOA->MODER |= GPIO_MODER_MODER5_0;

    Systick_Init();
    ServoPwm_InitAll();
    Uart2_Init();
    Adc1_InitAll();
    Joystick_Init();
    Servo_ApplyInitialPose();

    Uart2_SendString("Servo key console\r\n");
    Uart2_SendString("q/a BS  w/s SH  e/d EL\r\n");
    Uart2_SendString("r/f WP  t/g WY  y/h GR\r\n");

    last_tick_ms = Systick_GetMillis();

    while (1)
    {
        uint8_t key;
        uint32_t now_ms;

        if (Uart2_TryReceiveByte(&key) != 0U)
        {
            Servo_HandleCalibrationKey(key);
        }

        now_ms = Systick_GetMillis();
        if ((now_ms - last_tick_ms) >= CONTROL_TICK_MS)
        {
            last_tick_ms = now_ms;
            Joystick_PollAndApply();
            GPIOA->ODR ^= (1U << USER_LED_PIN);
        }
    }
}
