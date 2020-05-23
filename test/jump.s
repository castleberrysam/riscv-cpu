	.text
	jal	ra, label
	addi	s0, x0, -1
	jal	x0, end

label:	jalr	x0, ra, 0

end:	addi	a0, x0, -1
	.word	0

	# 0, 3, 1, 2, 4
