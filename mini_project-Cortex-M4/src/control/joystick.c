#include "stm32f4xx.h"
#include "joystick.h"
#include "joystick_config.h"
#include "adc1.h"
#include "servo.h"
#include "servo_pwm.h"
#include "systick.h"

#define JOYSTICK_BUTTON_DEBOUNCE_MS 20U

static uint8_t g_button_raw_prev;
static uint8_t g_button_debounced;
static uint32_t g_button_change_ms;

void Joystick_Init(void)
{
    RCC->AHB1ENR |= RCC_AHB1ENR_GPIOBEN;

    JOYSTICK3_BUTTON_GPIO->MODER &= ~GPIO_MODER_MODER5_Msk;
    JOYSTICK3_BUTTON_GPIO->PUPDR &= ~GPIO_PUPDR_PUPD5_Msk;
    JOYSTICK3_BUTTON_GPIO->PUPDR |= GPIO_PUPDR_PUPD5_0; /* internal pull-up, button ties pin to GND */

    g_button_raw_prev = 0U;
    g_button_debounced = 0U;
    g_button_change_ms = 0U;
}

static uint8_t Joystick_IsUpDownAxis(uint8_t adc_channel)
{
    return (adc_channel == JOYSTICK_A1_ADC_CHANNEL) ||
           (adc_channel == JOYSTICK_A2_ADC_CHANNEL) ||
           (adc_channel == JOYSTICK_A4_ADC_CHANNEL);
}

static int16_t Joystick_AxisDelta(uint8_t adc_channel)
{
    uint16_t raw = Adc1_ReadChannel(adc_channel);
    int32_t offset = (int32_t)raw - (int32_t)JOYSTICK_ADC_CENTER;
    int16_t delta_us = 0;

    if (offset > (int32_t)JOYSTICK_DEADZONE)
    {
        delta_us = (int16_t)JOYSTICK_PULSE_STEP_US;
    }
    else if (offset < -(int32_t)JOYSTICK_DEADZONE)
    {
        delta_us = -(int16_t)JOYSTICK_PULSE_STEP_US;
    }

    /* Up/down axes (A1, A2, A4) are mounted reversed vs. left/right. */
    return Joystick_IsUpDownAxis(adc_channel) ? (int16_t)(-delta_us) : delta_us;
}

static void Joystick_ApplyAxis(ArmServoId servo, uint8_t adc_channel)
{
    int16_t delta_us = Joystick_AxisDelta(adc_channel);

    if (delta_us != 0)
    {
        Servo_AdjustPulse(servo, delta_us);
        Servo_EchoPulse(servo);
    }
}

static void Joystick_PollButton(void)
{
    uint8_t raw_pressed;
    uint32_t now_ms;

    /* Active-low button: pin reads 0 while pressed. */
    raw_pressed = ((JOYSTICK3_BUTTON_GPIO->IDR & (1U << JOYSTICK3_BUTTON_PIN)) == 0U) ? 1U : 0U;
    now_ms = Systick_GetMillis();

    if (raw_pressed != g_button_raw_prev)
    {
        g_button_raw_prev = raw_pressed;
        g_button_change_ms = now_ms;
        return;
    }

    if ((now_ms - g_button_change_ms) < JOYSTICK_BUTTON_DEBOUNCE_MS)
    {
        return;
    }

    if ((raw_pressed != 0U) && (g_button_debounced == 0U))
    {
        Servo_ToggleGripper();
    }

    g_button_debounced = raw_pressed;
}

void Joystick_PollAndApply(void)
{
    Joystick_ApplyAxis(ARM_SERVO_BASE, JOYSTICK_A0_ADC_CHANNEL);
    Joystick_ApplyAxis(ARM_SERVO_SHOULDER, JOYSTICK_A1_ADC_CHANNEL);
    Joystick_ApplyAxis(ARM_SERVO_GRIPPER, JOYSTICK_A2_ADC_CHANNEL);
    Joystick_ApplyAxis(ARM_SERVO_ELBOW, JOYSTICK_A3_ADC_CHANNEL);
    Joystick_ApplyAxis(ARM_SERVO_WRIST_PITCH, JOYSTICK_A5_ADC_CHANNEL);
    Joystick_ApplyAxis(ARM_SERVO_WRIST_YAW, JOYSTICK_A4_ADC_CHANNEL);

    Joystick_PollButton();
}
