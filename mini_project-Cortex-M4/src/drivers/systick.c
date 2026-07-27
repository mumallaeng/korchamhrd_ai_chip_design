#include "stm32f4xx.h"
#include "systick.h"

static volatile uint32_t g_millis;

void Systick_Init(void)
{
    SysTick_Config(SystemCoreClock / 1000U); /* 1 ms tick */
}

uint32_t Systick_GetMillis(void)
{
    return g_millis;
}

void SysTick_Handler(void)
{
    g_millis++;
}
