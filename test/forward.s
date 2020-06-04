	.text
	addi    t5, x0, 1
	addi	s0, t5, 60
	addi    s0, t5, 3
	addi    t0, s0, 1
	addi    s0, s0, 1
	addi    s0, s0, 1
	add     s0, s0, s0
	add     s0, t5, s0
	add     t5, s0, t5
	add     t5, t5, t5
	addi    x0, x0, -12
	add     s0, x0, x0
	.word	TEST_MAGIC
