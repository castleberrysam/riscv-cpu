	.text
	lla	t0, tvec
	csrw	mtvec, t0

	auipc	t0, 0
	sw	t0, 1(t0)
	.word	TEST_MAGIC

tvec:	csrr	t0, mcause
	.word	TEST_MAGIC
