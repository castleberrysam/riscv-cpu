	.text
	lla	t0, tvec
	csrw	mtvec, t0

	auipc	t0, 128
	sw	t0, (t0)
	.word	TEST_MAGIC

tvec:	csrr	t0, mcause
	.word	TEST_MAGIC
