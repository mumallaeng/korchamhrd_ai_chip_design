#include "stm32f4xx.h"
#include "servo_config.h"
#include "servo_pwm.h"

#define TIMER_INPUT_HZ 16000000U // reset HSI: 16 MHz
#define TIMER_TICK_HZ 1000000U   // timer tick: 1 µs

#define TIM4_PSC_VALUE ((TIMER_INPUT_HZ / TIMER_TICK_HZ) - 1U) // 16 MHz / 16 = 1 MHz
#define SERVO_TIMER_ARR_VALUE (SERVO_PWM_PERIOD_US - 1U)       // 20,000 µs - 1 = 19,999

static void ServoPwm_ConfigureTimeBase(TIM_TypeDef *timer)
{
    timer->CR1 = 0U;
    timer->PSC = TIM4_PSC_VALUE;
    timer->ARR = SERVO_TIMER_ARR_VALUE;
}

static void ServoPwm_StartTimer(TIM_TypeDef *timer)
{
    timer->EGR = TIM_EGR_UG;
    timer->CR1 = TIM_CR1_ARPE | TIM_CR1_CEN;
}

static uint16_t ServoPwm_ClampToTimerPeriod(uint16_t pulse_us)
{
    if (pulse_us > SERVO_TIMER_ARR_VALUE) // 최대값보다 큰 값은 최대값으로 설정
    {
        return SERVO_TIMER_ARR_VALUE;
    }

    return pulse_us;
}

void ServoPwm_InitAll(void)
{
    /* clock enable */
    RCC->AHB1ENR |= RCC_AHB1ENR_GPIOAEN | RCC_AHB1ENR_GPIOBEN | RCC_AHB1ENR_GPIOCEN;
    RCC->APB1ENR |= RCC_APB1ENR_TIM2EN | RCC_APB1ENR_TIM3EN | RCC_APB1ENR_TIM4EN;
    RCC->APB2ENR |= RCC_APB2ENR_TIM1EN;

    /* GPIO pin을 timer 출력 pin으로 연결 */
    GPIOB->MODER &= ~(GPIO_MODER_MODER3_Msk | GPIO_MODER_MODER4_Msk | GPIO_MODER_MODER6_Msk | GPIO_MODER_MODER10_Msk);
    GPIOB->MODER |= GPIO_MODER_MODER3_1 | GPIO_MODER_MODER4_1 | GPIO_MODER_MODER6_1 | GPIO_MODER_MODER10_1;
    GPIOC->MODER &= ~GPIO_MODER_MODER7_Msk;
    GPIOC->MODER |= GPIO_MODER_MODER7_1;
    GPIOA->MODER &= ~GPIO_MODER_MODER9_Msk;
    GPIOA->MODER |= GPIO_MODER_MODER9_1;

    GPIOB->AFR[0] &= ~(GPIO_AFRL_AFSEL3_Msk | GPIO_AFRL_AFSEL4_Msk | GPIO_AFRL_AFSEL6_Msk);
    GPIOB->AFR[0] |= GPIO_AFRL_AFSEL3_0 | GPIO_AFRL_AFSEL4_1 | GPIO_AFRL_AFSEL6_1; // PB3=AF1(TIM2_CH2), PB6=AF2(TIM4_CH1)
    GPIOB->AFR[1] &= ~GPIO_AFRH_AFSEL10_Msk;
    GPIOB->AFR[1] |= GPIO_AFRH_AFSEL10_0;
    GPIOC->AFR[0] &= ~GPIO_AFRL_AFSEL7_Msk;
    GPIOC->AFR[0] |= GPIO_AFRL_AFSEL7_1;
    GPIOA->AFR[1] &= ~GPIO_AFRH_AFSEL9_Msk;
    GPIOA->AFR[1] |= GPIO_AFRH_AFSEL9_0;

    /* timer의 시간 단위와 PWM 주기 설정: 1µs 단위로 20ms마다 반복 */
    ServoPwm_ConfigureTimeBase(TIM4);
    ServoPwm_ConfigureTimeBase(TIM3);
    ServoPwm_ConfigureTimeBase(TIM2);
    ServoPwm_ConfigureTimeBase(TIM1);

    /* channel별 PWM 동작 방식 설정: 요청 전까지는 핀 출력 비활성화 */
    TIM4->CCR1 = SERVO_NEUTRAL_US;
    TIM4->CCMR1 &= ~(TIM_CCMR1_CC1S | TIM_CCMR1_OC1M);
    TIM4->CCMR1 |= TIM_CCMR1_OC1M_1 | TIM_CCMR1_OC1M_2 | TIM_CCMR1_OC1PE;
    TIM4->CCER = 0U;

    TIM3->CCR2 = SERVO_NEUTRAL_US;
    TIM3->CCR1 = SERVO_NEUTRAL_US;
    TIM3->CCMR1 &= ~(TIM_CCMR1_CC2S | TIM_CCMR1_OC2M | TIM_CCMR1_CC1S | TIM_CCMR1_OC1M);
    TIM3->CCMR1 |= TIM_CCMR1_OC2M_1 | TIM_CCMR1_OC2M_2 | TIM_CCMR1_OC2PE;
    TIM3->CCMR1 |= TIM_CCMR1_OC1M_1 | TIM_CCMR1_OC1M_2 | TIM_CCMR1_OC1PE;
    TIM3->CCER = 0U;

    TIM1->CCR2 = SERVO_NEUTRAL_US;
    TIM1->CCMR1 &= ~(TIM_CCMR1_CC2S | TIM_CCMR1_OC2M);
    TIM1->CCMR1 |= TIM_CCMR1_OC2M_1 | TIM_CCMR1_OC2M_2 | TIM_CCMR1_OC2PE;
    TIM1->CCER = 0U;
    TIM1->BDTR |= TIM_BDTR_MOE;

    TIM2->CCR3 = SERVO_NEUTRAL_US;
    TIM2->CCR2 = SERVO_NEUTRAL_US;
    TIM2->CCMR2 &= ~(TIM_CCMR2_CC3S | TIM_CCMR2_OC3M);
    TIM2->CCMR2 |= TIM_CCMR2_OC3M_1 | TIM_CCMR2_OC3M_2 | TIM_CCMR2_OC3PE;
    TIM2->CCMR1 &= ~(TIM_CCMR1_CC2S | TIM_CCMR1_OC2M);
    TIM2->CCMR1 |= TIM_CCMR1_OC2M_1 | TIM_CCMR1_OC2M_2 | TIM_CCMR1_OC2PE;
    TIM2->CCER = 0U;

    /* timer 시작 */
    ServoPwm_StartTimer(TIM4);
    ServoPwm_StartTimer(TIM3);
    ServoPwm_StartTimer(TIM1);
    ServoPwm_StartTimer(TIM2);
}

void ServoPwm_SetPulseUs(ArmServoId servo, uint16_t pulse_us)
{
    uint16_t safe_pulse_us = ServoPwm_ClampToTimerPeriod(pulse_us);

    switch (servo)
    {
    case ARM_SERVO_BASE:
        TIM4->CCR1 = safe_pulse_us;
        TIM4->EGR = TIM_EGR_UG;
        TIM4->CCER |= TIM_CCER_CC1E;
        break;
    case ARM_SERVO_SHOULDER:
        TIM3->CCR2 = safe_pulse_us;
        TIM3->EGR = TIM_EGR_UG;
        TIM3->CCER |= TIM_CCER_CC2E;
        break;
    case ARM_SERVO_ELBOW:
        TIM1->CCR2 = safe_pulse_us;
        TIM1->EGR = TIM_EGR_UG;
        TIM1->CCER |= TIM_CCER_CC2E;
        break;
    case ARM_SERVO_WRIST_PITCH:
        TIM2->CCR3 = safe_pulse_us;
        TIM2->EGR = TIM_EGR_UG;
        TIM2->CCER |= TIM_CCER_CC3E;
        break;
    case ARM_SERVO_WRIST_YAW:
        TIM3->CCR1 = safe_pulse_us;
        TIM3->EGR = TIM_EGR_UG;
        TIM3->CCER |= TIM_CCER_CC1E;
        break;
    case ARM_SERVO_GRIPPER:
        TIM2->CCR2 = safe_pulse_us;
        TIM2->EGR = TIM_EGR_UG;
        TIM2->CCER |= TIM_CCER_CC2E;
        break;
    default:
        break;
    }
}

void ServoPwm_DisableOutput(ArmServoId servo)
{
    switch (servo)
    {
    case ARM_SERVO_BASE:
        TIM4->CCER &= ~TIM_CCER_CC1E;
        break;
    case ARM_SERVO_SHOULDER:
        TIM3->CCER &= ~TIM_CCER_CC2E;
        break;
    case ARM_SERVO_ELBOW:
        TIM1->CCER &= ~TIM_CCER_CC2E;
        break;
    case ARM_SERVO_WRIST_PITCH:
        TIM2->CCER &= ~TIM_CCER_CC3E;
        break;
    case ARM_SERVO_WRIST_YAW:
        TIM3->CCER &= ~TIM_CCER_CC1E;
        break;
    case ARM_SERVO_GRIPPER:
        TIM2->CCER &= ~TIM_CCER_CC2E;
        break;
    default:
        break;
    }
}
