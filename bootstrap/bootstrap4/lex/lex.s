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

#include "regs.h"

#define TRUE 1
#define FALSE 0
#define NULL 0

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
	dd &"auto", 	@TOKEN_AUTO
	dd &"break", 	@TOKEN_BREAK
	dd &"case", 	@TOKEN_CASE
	dd &"char", 	@TOKEN_CHAR
	dd &"const", 	@TOKEN_CONST
	dd &"continue", @TOKEN_CONTINUE
	dd &"default", 	@TOKEN_DEFAULT
	dd &"do", 		@TOKEN_DO
	dd &"double", 	@TOKEN_DOUBLE
	dd &"else", 	@TOKEN_ELSE
	dd &"enum", 	@TOKEN_ENUM
	dd &"extern", 	@TOKEN_EXTERN
	dd &"float", 	@TOKEN_FLOAT
	dd &"for", 		@TOKEN_FOR
	dd &"goto", 	@TOKEN_GOTO
	dd &"if", 		@TOKEN_IF
	dd &"int", 		@TOKEN_INT
	dd &"long", 	@TOKEN_LONG
	dd &"register", @TOKEN_REGISTER
	dd &"return", 	@TOKEN_RETURN
	dd &"short", 	@TOKEN_SHORT
	dd &"signed", 	@TOKEN_SIGNED
	dd &"sizeof", 	@TOKEN_SIZEOF
	dd &"static", 	@TOKEN_STATIC
	dd &"struct", 	@TOKEN_STRUCT
	dd &"switch", 	@TOKEN_SWITCH
	dd &"typedef", 	@TOKEN_TYPEDEF
	dd &"union", 	@TOKEN_UNION
	dd &"unsigned", @TOKEN_UNSIGNED
	dd &"void", 	@TOKEN_VOID
	dd &"volatile", @TOKEN_VOLATILE
	dd &"while", 	@TOKEN_WHILE
	dd 0

# Multi-byte operators
:multibyte_op_tokens
	dd &"...",	@TOKEN_ELLIPSIS
	dd &">>=",	@TOKEN_RIGHT_ASSIGN
	dd &"<<=",	@TOKEN_LEFT_ASSIGN
	dd &"+=",	@TOKEN_ADD_ASSIGN
	dd &"-=",	@TOKEN_SUB_ASSIGN
	dd &"*=",	@TOKEN_MUL_ASSIGN
	dd &"/=",	@TOKEN_DIV_ASSIGN
	dd &"%=",	@TOKEN_MOD_ASSIGN
	dd &"&=",	@TOKEN_AND_ASSIGN
	dd &"^=",	@TOKEN_XOR_ASSIGN
	dd &"|=",	@TOKEN_OR_ASSIGN
	dd &">>",	@TOKEN_RIGHT_OP
	dd &"<<",	@TOKEN_LEFT_OP
	dd &"++",	@TOKEN_INC_OP
	dd &"--",	@TOKEN_DEC_OP
	dd &"->",	@TOKEN_PTR_OP
	dd &"&&",	@TOKEN_AND_OP
	dd &"||",	@TOKEN_OR_OP
	dd &"<=",	@TOKEN_LE_OP
	dd &">=",	@TOKEN_GE_OP
	dd &"==",	@TOKEN_EQ_OP
	dd &"!=",	@TOKEN_NE_OP
	dd 0

#===========================================================================
# int _lex_attempt_match_table(lex_file* file, char* buffer, int buffer_length,
#                              char* string)
#
# Returns:
#   1 if a match
#===========================================================================
:__lex_attempt_match
	%arg fd
	%arg buffer
	%arg buffer_length
	%arg string
	%local mark
	%local char

	%call :__lex_mark, @fd
	mov @mark, @ret

.loop
	ld.b @char, [@string]

	# If it's a match, we leave the stream as-is but don't read any more chars
	eq @char, @NULL
	mov? @ret, @TRUE
	%ret?

	%call :__lex_read, @fd

	eq @char, @ret

	%call^ :__lex_rewind, @fd, @mark
	mov^ @ret, @FALSE
	%ret^

	# Check the next byte
	add @string, 1
	jump .loop
#===========================================================================


#===========================================================================
# int _lex_attempt_match_table(lex_file* file, char* buffer, int buffer_length,
#                              void* table, char first_char)
# Returns:
#   Token from the table, or zero if no match
#===========================================================================
:__lex_attempt_match_table
	%arg fd
	%arg buffer
	%arg buffer_length
	%arg table
	%arg c
.str_loop
	ld.d @tmp0, [@table]

	# Table searched, string not found
	eq @tmp0, @NULL
	mov? @ret, @NULL
	%ret?

	# See if this string is a potential match
	ld.b @tmp0, [@tmp0]
	eq @tmp0, @c
	add^ @table, 8
	jump^ .str_loop

	# Possible match, call __lex_attempt_match
	ld.d @tmp0, [@table]
	add @tmp0, 1
	%call :__lex_attempt_match, @fd, @buffer, @buffer_length, @tmp0
	eq @ret, @TRUE
	add? @table, 4
	ld.d? @table, [@table]
	mov? @ret, @table
	%ret?

	add @table, 8
	jump^ .str_loop
#===========================================================================



#===========================================================================
# void _lex_consume_identifier(lex_file* file, char* buffer,
#                              int buffer_length, char first_char)
#===========================================================================
:__lex_consume_identifier
	%arg fd
	%arg buffer
	%arg buffer_length
	%arg c
	%local mark

	st.b [@buffer], @c
.loop
	%call :__lex_mark, @fd
	mov @mark, @ret

	%call :__lex_read, @fd
	st.b [@buffer], @ret

	# If done, return
	%call :_islabel, @ret
	eq @ret, @NULL
	jump? .done

	add @buffer, 1
	jump .loop

.done
	%call :__lex_rewind, @fd, @mark
	mov @ret, @TOKEN_IDENTIFIER
	%ret
#===========================================================================


#===========================================================================
# int lex(lex_file* file, char* buffer, int buffer_length)
#
# Returns:
#   Lexical token type (or NULL if no token found)
#===========================================================================
:_lex
	%arg fd
	%arg buffer
	%arg buffer_length
	%local c

.whitespace_loop
	# Read from the file handle
	%call :__lex_read, @fd
	mov @c, @ret

	# Eat whitespace
	%call :_iswhitespace, @c
	eq @ret, @TRUE
	jump? .whitespace_loop

	# Attempt to match multi-byte string tokens
	%call :__lex_attempt_match_table, @fd, @buffer, @buffer_length, :string_tokens, @c
	eq @ret, @NULL
	jump^ .done

	# Attempt to match label/identifier
	%call :_islabel, @c
	eq r0, @FALSE
	jump? .not_identifier

	%call :__lex_consume_identifier, @fd, @buffer, @buffer_length, @c
	%ret

.not_identifier
	# Attempt to match constants
	%call :_isdigit, @c
	eq r0, @FALSE
	jump? .not_digit

	#%tcall? :__lex_digit, @handle, @buffer, @buffer_length # tail call
	%call :__lex_digit, @fd, @buffer, @buffer_length # tail call
	%ret

.not_digit
	# Attempt to match multi-byte operators
	%call :__lex_attempt_match_table, @fd, @buffer, @buffer_length, :multibyte_op_tokens, @c

	# Attempt to match single-byte operators
	%call :_strchr, :literal_tokens, @c
	eq @ret, @NULL
	jump? .not_single_byte

	mov @ret, @c
	%ret

.not_single_byte
	%call :_fatal, &"Unexpected character 0x%x"

.done
	%ret
#===========================================================================


#===========================================================================
# int _lex_digit(lex_file* file, char* buffer, int buffer_length)
#===========================================================================
:__lex_digit
	%arg fd
	%arg buffer
	%arg buffer_length
	%ret
#===========================================================================


#===========================================================================
# Args:
#   R0: char
# Returns:
#   R0: 1 if true
#===========================================================================
:_islabel
	push r0
	eq r0, '_'
	jump? .rettrue
	call :_isdigit
	eq r0, $1
	jump? .rettrue
	pop r0
	push r0
	call :_isalpha
	eq r0, $1
	jump? .rettrue
	pop r0
	mov r0, $0
	ret
.rettrue
	pop r0
	mov r0, $1
	ret
#===========================================================================

