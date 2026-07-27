#ifndef JOYSTICK_CONFIG_H
#define JOYSTICK_CONFIG_H

/*
 * NUCLEO-F411RE + Sensor Shield v5.0 Arduino analog header.
 * Joystick 1 (A0/A1), joystick 2 (A2/A3), joystick 3 (A4/A5) - test wiring.
 * Product wiring keeps only joystick 3 (wrist pitch/yaw + gripper button).
 */
#define JOYSTICK_A0_ADC_CHANNEL 0U  /* PA0: base, left/right */
#define JOYSTICK_A1_ADC_CHANNEL 1U  /* PA1: shoulder, up/down */
#define JOYSTICK_A2_ADC_CHANNEL 4U  /* PA4: elbow, up/down */
#define JOYSTICK_A3_ADC_CHANNEL 8U  /* PB0: gripper (analog), left/right */
#define JOYSTICK_A4_ADC_CHANNEL 11U /* PC1: wrist pitch, up/down */
#define JOYSTICK_A5_ADC_CHANNEL 10U /* PC0: wrist yaw, left/right */

/* Joystick 3 button: 1 click toggles gripper open/close. Confirm wiring - default D4/PB5. */
#define JOYSTICK3_BUTTON_GPIO GPIOB
#define JOYSTICK3_BUTTON_PIN 5U

#define JOYSTICK_ADC_CENTER 2048U    /* 12-bit ADC midpoint */
#define JOYSTICK_DEADZONE 250U       /* ignore drift/noise around center */
#define JOYSTICK_PULSE_STEP_US 2U    /* pulse step applied per poll tick while deflected */

#endif /* JOYSTICK_CONFIG_H */
