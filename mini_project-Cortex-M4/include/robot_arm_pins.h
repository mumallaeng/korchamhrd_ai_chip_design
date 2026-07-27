#ifndef ROBOT_ARM_PINS_H
#define ROBOT_ARM_PINS_H

#include "stm32f4xx.h"

/* Sensor Shield D10.S: base rotation, PB6 AF2 = TIM4_CH1 */
#define ARM_SERVO_BASE_GPIO       GPIOB
#define ARM_SERVO_BASE_PIN        6U
#define ARM_SERVO_BASE_AF         2U
#define ARM_SERVO_BASE_TIMER      TIM4
#define ARM_SERVO_BASE_CHANNEL    1U

/* Sensor Shield D9.S: shoulder, PC7 AF2 = TIM3_CH2 */
#define ARM_SERVO_SHOULDER_GPIO       GPIOC
#define ARM_SERVO_SHOULDER_PIN        7U
#define ARM_SERVO_SHOULDER_AF         2U
#define ARM_SERVO_SHOULDER_TIMER      TIM3
#define ARM_SERVO_SHOULDER_CHANNEL    2U

/* Sensor Shield D8.S: elbow, PA9 AF1 = TIM1_CH2 */
#define ARM_SERVO_ELBOW_GPIO       GPIOA
#define ARM_SERVO_ELBOW_PIN        9U
#define ARM_SERVO_ELBOW_AF         1U
#define ARM_SERVO_ELBOW_TIMER      TIM1
#define ARM_SERVO_ELBOW_CHANNEL    2U

/* Sensor Shield D6.S: wrist pitch, PB10 AF1 = TIM2_CH3 */
#define ARM_SERVO_WRIST_PITCH_GPIO       GPIOB
#define ARM_SERVO_WRIST_PITCH_PIN        10U
#define ARM_SERVO_WRIST_PITCH_AF         1U
#define ARM_SERVO_WRIST_PITCH_TIMER      TIM2
#define ARM_SERVO_WRIST_PITCH_CHANNEL    3U

/* Sensor Shield D5.S: wrist yaw, PB4 AF2 = TIM3_CH1 */
#define ARM_SERVO_WRIST_YAW_GPIO       GPIOB
#define ARM_SERVO_WRIST_YAW_PIN        4U
#define ARM_SERVO_WRIST_YAW_AF         2U
#define ARM_SERVO_WRIST_YAW_TIMER      TIM3
#define ARM_SERVO_WRIST_YAW_CHANNEL    1U

/* Sensor Shield D3.S: gripper, PB3 AF1 = TIM2_CH2 */
#define ARM_SERVO_GRIPPER_GPIO       GPIOB
#define ARM_SERVO_GRIPPER_PIN        3U
#define ARM_SERVO_GRIPPER_AF         1U
#define ARM_SERVO_GRIPPER_TIMER      TIM2
#define ARM_SERVO_GRIPPER_CHANNEL    2U

#endif /* ROBOT_ARM_PINS_H */
