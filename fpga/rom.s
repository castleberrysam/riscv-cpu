main_loop:
	li	s0, 1
	jal	ra, delay
	li	s0, 2
	jal	ra, delay
	li	s0, 4
	jal	ra, delay
	li	s0, 8
	jal	ra, delay
	li	s0, 4
	jal	ra, delay
	li	s0, 2
	jal	ra, delay

	jal	zero, main_loop

delay:	li	t0, 0
	li	t1, 0x1000000

delay_loop:
	addi	t0, t0, 1
	blt	t0, t1, delay_loop

	jalr	zero, ra
