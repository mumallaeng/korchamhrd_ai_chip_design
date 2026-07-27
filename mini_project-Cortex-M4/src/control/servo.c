#include <stdint.h>

#include "servo.h"
#include "servo_config.h"
#include "servo_pwm.h"
#include "uart2.h"

typedef enum
{
    SERVO_DIRECTION_UNVERIFIED = 0,
    SERVO_DIRECTION_POSITIVE = 1,
    SERVO_DIRECTION_NEGATIVE = -1
} ServoDirection;

typedef struct
{
    uint16_t safe_min_us;
    uint16_t neutral_us;
    uint16_t safe_max_us;
    uint16_t initial_us;
    ServoDirection direction;
} ServoCalibration;

/* Calibration table: 0일 땐 PWM 출력 비활성화 */
static const ServoCalibration g_servo_calibration[ARM_SERVO_COUNT] =
    {
        [ARM_SERVO_BASE] = {0U, SERVO_NEUTRAL_US, 0U, SERVO_NEUTRAL_US, SERVO_DIRECTION_UNVERIFIED},
        [ARM_SERVO_SHOULDER] = {0U, SERVO_NEUTRAL_US, 0U, 450U, SERVO_DIRECTION_UNVERIFIED},
        [ARM_SERVO_ELBOW] = {0U, SERVO_NEUTRAL_US, 0U, 340U, SERVO_DIRECTION_UNVERIFIED},
        [ARM_SERVO_WRIST_PITCH] = {0U, SERVO_NEUTRAL_US, 0U, 700U, SERVO_DIRECTION_UNVERIFIED},
        [ARM_SERVO_WRIST_YAW] = {360U, SERVO_NEUTRAL_US, 2620U, 2300U, SERVO_DIRECTION_UNVERIFIED},
        [ARM_SERVO_GRIPPER] = {400U, SERVO_NEUTRAL_US, 1000U, 400U, SERVO_DIRECTION_UNVERIFIED}};

static const char *const kServoName[ARM_SERVO_COUNT] =
    {
        [ARM_SERVO_BASE] = "BS",
        [ARM_SERVO_SHOULDER] = "SH",
        [ARM_SERVO_ELBOW] = "EL",
        [ARM_SERVO_WRIST_PITCH] = "WP",
        [ARM_SERVO_WRIST_YAW] = "WY",
        [ARM_SERVO_GRIPPER] = "GR"};

static uint16_t g_current_pulse_us[ARM_SERVO_COUNT];

static uint16_t Servo_ClampToKnownRange(const ServoCalibration *calibration)
{
    uint16_t pulse_us = calibration->initial_us;

    if ((calibration->safe_min_us != 0U) &&
        (calibration->safe_max_us != 0U) &&
        (calibration->safe_min_us <= calibration->safe_max_us))
    {
        if (pulse_us < calibration->safe_min_us)
        {
            pulse_us = calibration->safe_min_us;
        }
        else if (pulse_us > calibration->safe_max_us)
        {
            pulse_us = calibration->safe_max_us;
        }
    }

    return pulse_us;
}

void Servo_ApplyInitialPose(void)
{
    ArmServoId servo;

    for (servo = ARM_SERVO_BASE; servo < ARM_SERVO_COUNT; servo++)
    {
        if (g_servo_calibration[servo].initial_us == 0U)
        {
            g_current_pulse_us[servo] = 0U;
            ServoPwm_DisableOutput(servo);
        }
        else
        {
            g_current_pulse_us[servo] = Servo_ClampToKnownRange(&g_servo_calibration[servo]);
            ServoPwm_SetPulseUs(servo, g_current_pulse_us[servo]);
        }
    }
}

void Servo_AdjustPulse(ArmServoId servo, int16_t delta_us)
{
    int32_t next_pulse_us = (int32_t)g_current_pulse_us[servo] + delta_us;

    if (next_pulse_us < 0)
    {
        next_pulse_us = 0;
    }

    g_current_pulse_us[servo] = (uint16_t)next_pulse_us;
    ServoPwm_SetPulseUs(servo, g_current_pulse_us[servo]);
}

void Servo_EchoPulse(ArmServoId servo)
{
    Uart2_SendString(kServoName[servo]);
    Uart2_SendString(": ");
    Uart2_SendNumber(g_current_pulse_us[servo]);
    Uart2_SendString("\r\n");
}

void Servo_ToggleGripper(void)
{
    uint16_t open_us = g_servo_calibration[ARM_SERVO_GRIPPER].safe_min_us;
    uint16_t closed_us = g_servo_calibration[ARM_SERVO_GRIPPER].safe_max_us;
    uint16_t midpoint_us = open_us + ((closed_us - open_us) / 2U);

    if (g_current_pulse_us[ARM_SERVO_GRIPPER] < midpoint_us)
    {
        g_current_pulse_us[ARM_SERVO_GRIPPER] = closed_us;
    }
    else
    {
        g_current_pulse_us[ARM_SERVO_GRIPPER] = open_us;
    }

    ServoPwm_SetPulseUs(ARM_SERVO_GRIPPER, g_current_pulse_us[ARM_SERVO_GRIPPER]);
    Servo_EchoPulse(ARM_SERVO_GRIPPER);
}

void Servo_HandleCalibrationKey(uint8_t key)
{
    ArmServoId servo;
    int16_t delta_us;

    switch (key)
    {
    case 'q':
        servo = ARM_SERVO_BASE;
        delta_us = (int16_t)SERVO_PULSE_STEP_US;
        break;
    case 'a':
        servo = ARM_SERVO_BASE;
        delta_us = -(int16_t)SERVO_PULSE_STEP_US;
        break;
    case 'w':
        servo = ARM_SERVO_SHOULDER;
        delta_us = (int16_t)SERVO_PULSE_STEP_US;
        break;
    case 's':
        servo = ARM_SERVO_SHOULDER;
        delta_us = -(int16_t)SERVO_PULSE_STEP_US;
        break;
    case 'e':
        servo = ARM_SERVO_ELBOW;
        delta_us = (int16_t)SERVO_PULSE_STEP_US;
        break;
    case 'd':
        servo = ARM_SERVO_ELBOW;
        delta_us = -(int16_t)SERVO_PULSE_STEP_US;
        break;
    case 'r':
        servo = ARM_SERVO_WRIST_PITCH;
        delta_us = (int16_t)SERVO_PULSE_STEP_US;
        break;
    case 'f':
        servo = ARM_SERVO_WRIST_PITCH;
        delta_us = -(int16_t)SERVO_PULSE_STEP_US;
        break;
    case 't':
        servo = ARM_SERVO_WRIST_YAW;
        delta_us = (int16_t)SERVO_PULSE_STEP_US;
        break;
    case 'g':
        servo = ARM_SERVO_WRIST_YAW;
        delta_us = -(int16_t)SERVO_PULSE_STEP_US;
        break;
    case 'y':
        servo = ARM_SERVO_GRIPPER;
        delta_us = (int16_t)SERVO_PULSE_STEP_US;
        break;
    case 'h':
        servo = ARM_SERVO_GRIPPER;
        delta_us = -(int16_t)SERVO_PULSE_STEP_US;
        break;
    default:
        return;
    }

    Servo_AdjustPulse(servo, delta_us);
    Servo_EchoPulse(servo);
}
