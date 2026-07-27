#ifndef SERVO_CONFIG_H
#define SERVO_CONFIG_H

#define SERVO_PWM_HZ 50U       /* Servo command period: 20 ms */
#define SERVO_NEUTRAL_US 1500U /* First calibration pulse: 1.5 ms */
#define SERVO_PWM_PERIOD_US (1000000U / SERVO_PWM_HZ)
#define SERVO_PULSE_STEP_US 8U /* Per-keypress raw pulse step while calibrating */

#endif /* SERVO_CONFIG_H */
