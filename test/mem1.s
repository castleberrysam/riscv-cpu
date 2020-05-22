	.text
	addi t0, x0, 431
	lui t0, 29312
	auipc t5, 1
	addi s0, t5, 60
	sw t0, 0(s0)
	lh t1, 2(s0)
	lh a0, 0(s0)
	lb s1, 1(s0)
	slti x0, x0, 0
