	.text
	li	t1, 10
	addi	s0, t5, 60
	auipc   s0, 0
	sw	t0, 0(s0)
	lh	t1, 2(s0)
	addi    t3, t1, 3
	lh	a0, 0(s0)
	add     t4, t1, a0
	lb	s1, 1(s0)
	sub     t1, t3, s0
	.word	0
