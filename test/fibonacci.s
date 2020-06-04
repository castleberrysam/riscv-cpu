	.text
	li	a0, 100
	jal	ra, fibonacci
	.word	TEST_MAGIC

fibonacci:
	mv	t0, a0
	li	a0, 1
	li	a1, 1

loop:	addi	t0, t0, -1
	blez	t0, return

	add	t1, a0, a1
	mv	a1, a0
	mv	a0, t1
	j	loop

return:	ret
