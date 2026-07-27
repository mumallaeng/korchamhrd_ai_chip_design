#ifndef UART2_H
#define UART2_H

#include <stdint.h>

void Uart2_Init(void);
void Uart2_SendByte(uint8_t byte);
uint8_t Uart2_ReceiveByte(void);
uint8_t Uart2_TryReceiveByte(uint8_t *out_byte);
void Uart2_SendString(const char *text);
void Uart2_SendNumber(uint16_t value);

#endif /* UART2_H */
