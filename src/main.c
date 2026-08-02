#include <drivers/uart.h>
#include <rtos/rtos.h>
#include <stdint.h>

#define NTHREADS	3
#define STACKSIZE	128

struct rtos_tcb tcb[NTHREADS];
uint32_t stack[NTHREADS][STACKSIZE];

void motor_start(void);
void motor_stop(void);

void valve_open(void);
void valve_close(void);

void task1(void)
{
	while (1) {
		uart_write(" => Task1 running...\r\n");
		rtos_thread_yield();
	}
}

void task2(void)
{
	while (1)
		uart_write(" => Task2 running...\r\n");
}

void task3(void)
{
	while (1)
		uart_write(" => Task3 running...\r\n");
}

int main(void)
{
	uart_tx_init();

	rtos_thread_add(task1, &tcb[0], &stack[0][STACKSIZE - 1]);
	rtos_thread_add(task2, &tcb[1], &stack[1][STACKSIZE - 1]);
	rtos_thread_add(task3, &tcb[2], &stack[2][STACKSIZE - 1]);
	rtos_kernel_launch(10);

	while (1);
}

void motor_start(void)
{
	uart_write(" => Motor is starting...\r\n");
}

void motor_stop(void)
{
	uart_write(" => Motor is stopping...\r\n");
}

void valve_open(void)
{
	uart_write(" => Valve is opening...\r\n");
}

void valve_close(void)
{
	uart_write(" => Valve is closing...\r\n");
}
