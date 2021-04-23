/*
* Hello world for subservient
*
* Continuously read a string from memory and and bitbang on UART
*
*/
#define GPIO_ADDR 0x40000000
#define AXIS_ADDR 0xC0000000
#define HALT_ADDR 0x90000000

	/*
	a0 = Console address
	a1 = String address
	t0 = Character to write
	*/

.globl _start
_start:
	/* Load gpio address to a0 */
	li	a0, GPIO_ADDR

	/* Set GPIO high initially */
	addi	t0, zero, 1
	sb	t0, 0(a0)

loop:
	/* Load string address to a0 */
	la  a1,     str

next_char:
	/* Read char from string */
	lbu	t0, 0(a1)

	/* If zero, we reached end of string and will reload */
	beqz	t0, loop

	/* Bitbanged UART loop */
	ori	t0, t0, 0x100
	slli	t0, t0, 1
1:	sb	t0, 0(a0)
	srli	t0, t0, 1
	nop
	nop
	bnez	t0, 1b

	j next_char

str:
	.section .data
	.string "Hi! I'm subservient\n"
