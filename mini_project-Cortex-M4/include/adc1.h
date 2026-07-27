#ifndef ADC1_H
#define ADC1_H

#include <stdint.h>

void Adc1_InitAll(void);
uint16_t Adc1_ReadChannel(uint8_t channel);

#endif /* ADC1_H */
