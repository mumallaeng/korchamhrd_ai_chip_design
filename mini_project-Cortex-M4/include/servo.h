#ifndef SERVO_H
#define SERVO_H

#include <stdint.h>

#include "servo_pwm.h"

#define SERVO_ANGLE_MIN_DEG 0U
#define SERVO_ANGLE_MAX_DEG 180U

void Servo_ApplyInitialPose(void);
void Servo_HandleCalibrationKey(uint8_t key);
void Servo_AdjustPulse(ArmServoId servo, int16_t delta_us);
void Servo_EchoPulse(ArmServoId servo);
void Servo_ToggleGripper(void);

#endif /* SERVO_H */
