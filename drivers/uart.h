#ifndef RTOS_DRIVERS_UART_H
#define RTOS_DRIVERS_UART_H

void uart_tx_init(void);

void uart_putchar(char c);

void uart_write(char *c);

#endif /* RTOS_DRIVERS_UART_H */
