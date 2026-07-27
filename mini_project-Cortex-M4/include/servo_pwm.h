#ifndef SERVO_PWM_H
#define SERVO_PWM_H

#include <stdint.h>

typedef enum
{
    ARM_SERVO_BASE = 0,
    ARM_SERVO_SHOULDER,
    ARM_SERVO_ELBOW,
    ARM_SERVO_WRIST_PITCH,
    ARM_SERVO_WRIST_YAW,
    ARM_SERVO_GRIPPER,
    ARM_SERVO_COUNT
} ArmServoId;

void ServoPwm_InitAll(void);
void ServoPwm_SetPulseUs(ArmServoId servo, uint16_t pulse_us);
void ServoPwm_DisableOutput(ArmServoId servo);

#endif /* SERVO_PWM_H */
