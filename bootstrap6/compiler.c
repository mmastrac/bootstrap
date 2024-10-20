#define BUFFER_SIZE 32
#define TRUE 1
#define FALSE 0

// https://www.lysator.liu.se/c/ANSI-C-grammar-y.html

int lex_file;
int buffer;

int token(int* buf) {
	int t;
	t = lex(lex_file, buffer, BUFFER_SIZE);
	*buf = stralloc(buffer);
	return t;
}

int compile_labeled_statement() {
	int mark;

	mark = compile_mark();

	if (compile_token(TOKEN_IDENTIFIER) && compile_token(':') && compile_statement()) {
		return TRUE;
	}

	compile_rewind(mark);

	if (compile_token(TOKEN_CASE) && compile_constant_expression() && compile_token(':') && compile_statement()) {
		return TRUE;
	}

	compile_rewind(mark);

	if (compile_token(TOKEN_DEFAULT) && compile_token(':') && compile_statement()) {
		return TRUE;
	}

	compile_rewind(mark);

	return FALSE;
}

int compile_statement() {
	if (compile_labeled_statement()) {
		return TRUE;
	}
	if (compile_compound_statement()) {
		return TRUE;
	}
	if (compile_expression_statement()) {
		return TRUE;
	}
	if (compile_selection_statement()) {
		return TRUE;
	}
	if (compile_iteration_statement()) {
		return TRUE;
	}
	if (compile_jump_statement()) {
		return TRUE;
	}

	return FALSE;
}

int main() {
	buffer = malloc(BUFFER_SIZE);
}
