#ifndef UART_CONFIG_H
#define UART_CONFIG_H

#define UART2_PCLK_HZ 16000000U /* Reset clock tree: PCLK1 = HSI 16 MHz */
#define UART2_BAUD 115200U      /* ST-LINK virtual COM baud rate */
#define UART2_BRR_VALUE ((UART2_PCLK_HZ + (UART2_BAUD / 2U)) / UART2_BAUD)
/* 16 MHz / 115200 = 138.89, rounded to BRR 139 = 0x008B for OVER8 = 0. */

#endif /* UART_CONFIG_H */
