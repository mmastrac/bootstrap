# C lexer, complete for C89

# Can be linked against the basic parser in bootstrap4, or a more complete parser
# to generate assembly.

# Assumes parser provides a method to disambiguate between an identifier or a type.

# See this C grammar:
# https://www.lysator.liu.se/c/ANSI-C-grammar-l.html

# Example of _lex_check_type
#:_lex_check_type
#	mov r0, @IDENTIFIER
#	ret

#define TOKEN_AUTO 		100
#define TOKEN_BREAK 	101
#define TOKEN_CASE 		102
#define TOKEN_CHAR 		103
#define TOKEN_CONST 	104
#define TOKEN_CONTINUE 	105
#define TOKEN_DEFAULT 	106
#define TOKEN_DO 		107
#define TOKEN_DOUBLE 	108
#define TOKEN_ELSE 		109
#define TOKEN_ENUM 		110
#define TOKEN_EXTERN 	111
#define TOKEN_FLOAT 	112
#define TOKEN_FOR 		113
#define TOKEN_GOTO 		114
#define TOKEN_IF 		115
#define TOKEN_INT 		116
#define TOKEN_LONG 		117
#define TOKEN_REGISTER 	118
#define TOKEN_RETURN 	119
#define TOKEN_SHORT 	120
#define TOKEN_SIGNED 	121
#define TOKEN_SIZEOF 	122
#define TOKEN_STATIC 	123
#define TOKEN_STRUCT 	124
#define TOKEN_SWITCH 	125
#define TOKEN_TYPEDEF 	126
#define TOKEN_UNION 	127
#define TOKEN_UNSIGNED 	128
#define TOKEN_VOID 		129
#define TOKEN_VOLATILE 	130
#define TOKEN_WHILE 	131

#define TOKEN_TYPE_NAME 	132
#define TOKEN_IDENTIFIER 	133

#define TOKEN_CONSTANT 			134
#define TOKEN_STRING_LITERAL 	135

#define TOKEN_ELLIPSIS 		136
#define TOKEN_RIGHT_ASSIGN 	137
#define TOKEN_LEFT_ASSIGN 	138
#define TOKEN_ADD_ASSIGN 	139
#define TOKEN_SUB_ASSIGN 	140
#define TOKEN_MUL_ASSIGN 	141
#define TOKEN_DIV_ASSIGN 	142
#define TOKEN_MOD_ASSIGN 	143
#define TOKEN_AND_ASSIGN 	144
#define TOKEN_XOR_ASSIGN 	145
#define TOKEN_OR_ASSIGN 	146
#define TOKEN_RIGHT_OP 		147
#define TOKEN_LEFT_OP 		148
#define TOKEN_INC_OP 		149
#define TOKEN_DEC_OP 		150
#define TOKEN_PTR_OP 		151
#define TOKEN_AND_OP 		152
#define TOKEN_OR_OP 		153
#define TOKEN_LE_OP 		154
#define TOKEN_GE_OP 		155
#define TOKEN_EQ_OP 		156
#define TOKEN_NE_OP 		157

# Tokens that are a single character and whose token value is equal to their
# ASCII values
:literal_tokens
	ds ";{},:=()[].&!~-+*/%<>^|?"

# String-like tokens
:string_tokens
	dd &"auto", 		@TOKEN_AUTO
	dd &"break", 		@TOKEN_BREAK
	dd &"case", 		@TOKEN_CASE
	dd &"char", 		@TOKEN_CHAR
	dd &"const", 		@TOKEN_CONST
	dd &"continue", 	@TOKEN_CONTINUE
	dd &"default", 		@TOKEN_DEFAULT
	dd &"do", 			@TOKEN_DO
	dd &"double", 		@TOKEN_DOUBLE
	dd &"else", 		@TOKEN_ELSE
	dd &"enum", 		@TOKEN_ENUM
	dd &"extern", 		@TOKEN_EXTERN
	dd &"float", 		@TOKEN_FLOAT
	dd &"for", 			@TOKEN_FOR
	dd &"goto", 		@TOKEN_GOTO
	dd &"if", 			@TOKEN_IF
	dd &"int", 			@TOKEN_INT
	dd &"long", 		@TOKEN_LONG
	dd &"register", 	@TOKEN_REGISTER
	dd &"return", 		@TOKEN_RETURN
	dd &"short", 		@TOKEN_SHORT
	dd &"signed", 		@TOKEN_SIGNED
	dd &"sizeof", 		@TOKEN_SIZEOF
	dd &"static", 		@TOKEN_STATIC
	dd &"struct", 		@TOKEN_STRUCT
	dd &"switch", 		@TOKEN_SWITCH
	dd &"typedef", 		@TOKEN_TYPEDEF
	dd &"union", 		@TOKEN_UNION
	dd &"unsigned", 	@TOKEN_UNSIGNED
	dd &"void", 		@TOKEN_VOID
	dd &"volatile", 	@TOKEN_VOLATILE
	dd &"while", 		@TOKEN_WHILE
	dd 0

# Multi-byte operators


#===========================================================================
# R0: File handle
# R1: Pointer to string with token
# R2: Initial character
# Returns:
#   R0: 1 if a match (leaving stream at the end of the token),
#       0 if not a match (rewinding stream to position when method started)
#===========================================================================
:__lex_attempt_match



#===========================================================================
# R0: File handle
# R1: Pointer to table
# R2: Initial character
# Returns:
#   R0: Token from table, or zero if no match
#===========================================================================
:__lex_attempt_match_table
.str_loop
	ld.d r2, r3
	eq r2, $0
	jmp? .str_loop_done
	mov r1, r2
	call :lex_attempt_match
	eq r0, $1
	add? r3, $4
	ld.d? r0, r3
	ret?
	add r3, $8
	jmp .str_loop


#===========================================================================
# R0: File handle
# R1: Byte buffer that receives zero-terminated token text
# R2: Buffer length
# Returns:
#   R0: Lexical token type (or 0 if no token found)
#===========================================================================
:_lex
	%arg handle, buffer, buffer_length
	%local c

	# Read from the file handle in r0
	%call :read_char, @handle
	mov @c, r0

	# Eat whitespace
	%call :_iswhitespace, @c
	eq r0, $1
	jmp? :_lex

	# Attempt to match strings
	mov r0, r10
	mov r1, :string_tokens
	mov r2, r13
	%call :__lex_attempt_match_table, @handle, @buffer, @buffer_length, :string_tokens, @c

	# Attempt to match label/identifier
	%call :_islabel, @c
	eq r0, $1
	...

	# Attempt to match constants
	%call :_isdigit, @c
	eq r0, $1

	%tailcall? :__lex_digit, @handle, @buffer, @buffer_length # tail call

	# Attempt to match multi-byte operators
	call :__lex_attempt_match_table, @handle, @buffer, @buffer_length, :op_tokens, @c

	# Attempt to match single-byte operators
	mov r0, :literal_tokens
.token_loop
	ld.b r1, r0
	eq r1, $0
	jmp? .token_done
	eq r1, r13
	mov? r0, r13
	ret?
	add r0, $1
	jmp .token_loop
.token_done
	mov r0, $0
	ret



#===========================================================================
# Args:
#   R0: char
# Returns:
#   R0: 1 if true
#===========================================================================
:_islabel
	eq r0, '_'
	jmp? .rettrue
	call :_isdigit
	eq r0, $1
	jmp? .rettrue
	call :_isalpha
	eq r0, $1
	jmp? .rettrue
	mov r0, $0
	ret
.rettrue
	mov r0, $1
	ret
#===========================================================================

