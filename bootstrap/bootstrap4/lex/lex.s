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
#include "../bootstrap4/lex/lex.h"

#define TRUE 1
#define FALSE 0
#define NULL 0

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
	%local orig_string

	mov @orig_string, @string

	%call :__lex_mark, @fd
	mov @mark, @ret

.loop
	ld.b @char, [@string]

	# If it's a match, we leave the stream as-is but don't read any more chars
	eq @char, @NULL
	jump? .match

	%call :__lex_read, @fd

	eq @char, @ret

	%call^ :__lex_rewind, @fd, @mark
	mov^ @ret, @FALSE
	%ret^

	# Check the next byte
	add @string, 1
	jump .loop

.match
	sub @orig_string, 1
	%call :_strcpy, @buffer, @orig_string
	mov @ret, @TRUE
	%ret
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
	add @buffer, 1
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
	st.b [@buffer], 0
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

	st.b [@buffer], 0

.whitespace_loop
	# Read from the file handle
	%call :__lex_read, @fd
	mov @c, @ret

	# EOF?
	eq @c, @TOKEN_EOF
	%ret?

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
	eq @ret, @NULL
	jump^ .done

	# Attempt to match single-byte operators
	%call :_strchr, :literal_tokens, @c
	eq @ret, @NULL
	jump? .not_single_byte

	mov @ret, @c
	st.b [@buffer], @c
	add @buffer, 1
	st.b [@buffer], 0
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

