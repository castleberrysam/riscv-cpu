	.text
	lla	t0, tvec
	csrw	mtvec, t0

	li	t0, 2
	jr	t0
	.word	TEST_MAGIC

tvec:	csrr	t0, mcause
	.word	TEST_MAGIC
