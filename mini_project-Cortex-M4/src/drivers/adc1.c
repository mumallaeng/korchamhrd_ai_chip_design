#include "stm32f4xx.h"
#include "adc1.h"

void Adc1_InitAll(void)
{
    RCC->AHB1ENR |= RCC_AHB1ENR_GPIOAEN | RCC_AHB1ENR_GPIOBEN | RCC_AHB1ENR_GPIOCEN;
    RCC->APB2ENR |= RCC_APB2ENR_ADC1EN;

    /* A0=PA0, A1=PA1, A2=PA4: analog mode */
    GPIOA->MODER &= ~(GPIO_MODER_MODER0_Msk | GPIO_MODER_MODER1_Msk | GPIO_MODER_MODER4_Msk);
    GPIOA->MODER |= GPIO_MODER_MODER0_Msk | GPIO_MODER_MODER1_Msk | GPIO_MODER_MODER4_Msk;

    /* A3=PB0: analog mode */
    GPIOB->MODER &= ~GPIO_MODER_MODER0_Msk;
    GPIOB->MODER |= GPIO_MODER_MODER0_Msk;

    /* A5=PC0, A4=PC1: analog mode */
    GPIOC->MODER &= ~(GPIO_MODER_MODER0_Msk | GPIO_MODER_MODER1_Msk);
    GPIOC->MODER |= GPIO_MODER_MODER0_Msk | GPIO_MODER_MODER1_Msk;

    /* Longer sample time for the joystick pot channels (0,1,4,8,10,11) */
    ADC1->SMPR2 |= ADC_SMPR2_SMP0_1 | ADC_SMPR2_SMP1_1 | ADC_SMPR2_SMP4_1 | ADC_SMPR2_SMP8_1;
    ADC1->SMPR1 |= ADC_SMPR1_SMP10_1 | ADC_SMPR1_SMP11_1;

    ADC1->CR2 |= ADC_CR2_ADON;
}

uint16_t Adc1_ReadChannel(uint8_t channel)
{
    ADC1->SQR3 = (uint32_t)channel & 0x1FU;
    ADC1->CR2 |= ADC_CR2_SWSTART;

    while ((ADC1->SR & ADC_SR_EOC) == 0U)
    {
    }

    return (uint16_t)ADC1->DR;
}
