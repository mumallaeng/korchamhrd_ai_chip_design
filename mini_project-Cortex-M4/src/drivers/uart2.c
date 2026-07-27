#include "stm32f4xx.h"
#include "uart_config.h"
#include "uart2.h"

#define UART2_RX_BUFFER_SIZE 32U

static volatile uint8_t g_rx_buffer[UART2_RX_BUFFER_SIZE];
static volatile uint8_t g_rx_head;
static volatile uint8_t g_rx_tail;

void Uart2_Init(void)
{
    RCC->AHB1ENR |= RCC_AHB1ENR_GPIOAEN;
    RCC->APB1ENR |= RCC_APB1ENR_USART2EN;

    GPIOA->MODER &= ~(GPIO_MODER_MODER2_Msk | GPIO_MODER_MODER3_Msk);
    GPIOA->MODER |= GPIO_MODER_MODER2_1 | GPIO_MODER_MODER3_1;

    GPIOA->AFR[0] &= ~(GPIO_AFRL_AFSEL2);
    GPIOA->AFR[0] |= GPIO_AFRL_AFSEL2_0 | GPIO_AFRL_AFSEL2_1 | GPIO_AFRL_AFSEL2_2;
    GPIOA->AFR[0] &= ~(GPIO_AFRL_AFSEL3);
    GPIOA->AFR[0] |= GPIO_AFRL_AFSEL3_0 | GPIO_AFRL_AFSEL3_1 | GPIO_AFRL_AFSEL3_2;

    USART2->BRR = UART2_BRR_VALUE;
    USART2->CR1 |= USART_CR1_UE | USART_CR1_TE | USART_CR1_RE | USART_CR1_RXNEIE;

    NVIC_EnableIRQ(USART2_IRQn);
}

void USART2_IRQHandler(void)
{
    if ((USART2->SR & USART_SR_RXNE) != 0U)
    {
        uint8_t byte = (uint8_t)USART2->DR;
        uint8_t next_head = (uint8_t)((g_rx_head + 1U) % UART2_RX_BUFFER_SIZE);

        if (next_head != g_rx_tail) /* drop the byte if the buffer is full */
        {
            g_rx_buffer[g_rx_head] = byte;
            g_rx_head = next_head;
        }
    }
}

void Uart2_SendByte(uint8_t byte)
{
    while ((USART2->SR & USART_SR_TXE) == 0U)
        ;

    USART2->DR = byte;
}

uint8_t Uart2_TryReceiveByte(uint8_t *out_byte)
{
    if (g_rx_head == g_rx_tail)
    {
        return 0U;
    }

    *out_byte = g_rx_buffer[g_rx_tail];
    g_rx_tail = (uint8_t)((g_rx_tail + 1U) % UART2_RX_BUFFER_SIZE);
    return 1U;
}

uint8_t Uart2_ReceiveByte(void)
{
    uint8_t byte;

    while (Uart2_TryReceiveByte(&byte) == 0U)
        ;

    return byte;
}

void Uart2_SendString(const char *text)
{
    while (*text != '\0')
    {
        Uart2_SendByte((uint8_t)*text);
        text++;
    }
}

void Uart2_SendNumber(uint16_t value)
{
    char digits[5];
    int digit_count = 0;

    if (value == 0U)
    {
        Uart2_SendByte((uint8_t)'0');
        return;
    }

    while (value != 0U)
    {
        digits[digit_count] = (char)('0' + (value % 10U));
        digit_count++;
        value /= 10U;
    }

    while (digit_count > 0)
    {
        digit_count--;
        Uart2_SendByte((uint8_t)digits[digit_count]);
    }
}
