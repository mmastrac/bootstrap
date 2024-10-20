int fib(int n) {
	int sum;
	if (n == 0) {
		return 0;
	}
	if (n == 1) {
		return 1;
	}
	sum = fib(n - 2);
	sum = sum + fib(n - 1);
	return sum;
}

int result_fib() {
	return fib(9) + 8;
}
