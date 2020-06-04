	.text
	lui	s0, 74565
	addi	s0, s0, 1656
	auipc	s1, 1
	sw	s0, 40(s1)
	lw	ra, 40(s1)
	.word	TEST_MAGIC
