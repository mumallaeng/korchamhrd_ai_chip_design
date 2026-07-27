#ifndef SYSTICK_H
#define SYSTICK_H

#include <stdint.h>

void Systick_Init(void);
uint32_t Systick_GetMillis(void);

#endif /* SYSTICK_H */
