	.text
	li	a0, 100
	jal	ra, fibonacci
	slti	x0, x0, 0
	.word	0

fibonacci:
	addi	t0, a0, 0
	li	a0, 1
	li	a1, 1

loop:	addi	t0, t0, -1
	ble	t0, zero, return

	add	t1, a0, a1
	addi	a1, a0, 0
	addi	a0, t1, 0
	beq	zero, zero, loop

return:	jalr	x0, ra
