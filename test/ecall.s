	.text
	lla	t0, tvec
	csrw	mtvec, t0

	ecall
	.word	TEST_MAGIC

tvec:	csrr	t0, mcause
	.word	TEST_MAGIC
