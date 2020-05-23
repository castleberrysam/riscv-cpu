	.text
	auipc	t0, 1
	lw	t0, (t0)
	jal	t0, label

label:	.word	0
