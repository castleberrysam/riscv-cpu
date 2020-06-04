	.text
	lla	t0, tvec
	csrw	mtvec, t0

	.word	0
	li	t0, 1
	.word	TEST_MAGIC

tvec:	csrr	t0, mcause
	csrr	t0, mepc
	addi	t0, t0, 4
	csrw	mepc, t0
	mret
