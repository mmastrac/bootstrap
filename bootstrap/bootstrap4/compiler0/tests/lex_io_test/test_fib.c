int fib(int n) {
	int sum;
	if (n == 0) {
		return 0;
	}
	if (n == 1) {
		return 1;
	}
	sum = 0;
	sum = fib(n - 1);
	sum = sum + fib(n - 2);
}