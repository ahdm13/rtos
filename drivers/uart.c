#include "system.h"
#include "drivers/uart.h"
#include <cmsis/stm32f1xx.h>
#include <stdint.h>

#define APB1_CLK SYSFREQ
#define BAUDRATE 115200

#define IOPAEN (uint32_t)(1 << 2)
#define AFIOEN (uint32_t)(1 << 0)
#define USART2EN (uint32_t)(1 << 17)

#define CR1_TE (uint32_t)(1 << 3)
#define CR1_UE (uint32_t)(1 << 13)
#define SR_TXE (uint32_t)(1 << 7)

#define UART_SET_PIN2 (uint32_t)((1 << 11) | (1 << 9))
#define UART_UNSET_PIN2 (uint32_t)((1 << 10) | (1 << 8))

void uart_tx_init(void)
{
	/* Enable clock access for GPIOA */
	RCC->APB2ENR |= (IOPAEN | AFIOEN);

	/* Set PA2 to alternate function mode */
	GPIOA->CRL |= UART_SET_PIN2;
	GPIOA->CRL &= ~UART_UNSET_PIN2;

	/* Enable clock access for USART2 */
	RCC->APB1ENR |= USART2EN;

	/* Configure baudrate */
	USART2->BRR = (uint16_t)((APB1_CLK + (BAUDRATE / 2))/BAUDRATE);

	/* Configure transfer direction */
	USART2->CR1 = CR1_TE;

	/* Enable USART2 module */
	USART2->CR1 |= CR1_UE;
}

void uart_putchar(char c)
{
	/* Make sure transmit data register is empty */
	while (!(USART2->SR & SR_TXE));

	/* Write data to transmit data register */
	USART2->DR = (c & 0xFF);
}

void uart_write(char *str)
{
	for (; *str != '\0'; str++)
		uart_putchar(*str);
}
