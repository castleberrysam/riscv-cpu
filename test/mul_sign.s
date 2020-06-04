	.text
	li	t0, 1
	li	t1, 10
	mul	t2, t0, t1
	mulh	t2, t0, t1
	mulhu	t2, t0, t1
	mulhsu	t2, t0, t1

	li	t0, -1
	li	t1, 10
	mul	t2, t0, t1
	mulh	t2, t0, t1
	mulhu	t2, t0, t1
	mulhsu	t2, t0, t1

	li	t0, 1
	li	t1, -10
	mul	t2, t0, t1
	mulh	t2, t0, t1
	mulhu	t2, t0, t1
	mulhsu	t2, t0, t1

	li	t0, -1
	li	t1, -10
	mul	t2, t0, t1
	mulh	t2, t0, t1
	mulhu	t2, t0, t1
	mulhsu	t2, t0, t1

	.word	TEST_MAGIC
