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

#define PP_DEFINE 1
#define PP_INCLUDE 2

# Tokens that are a single character and whose token value is equal to their
# ASCII values
:literal_tokens
	ds ";{},:=()[].&!~-+*/%<>^|?"

# Preprocessor tokens, special handling
:preprocessor_tokens
	dd &"#define",	@PP_DEFINE
	dd &"#include",	@PP_INCLUDE
	dd 0

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
	dd &"/*",	@TOKEN_COMMENT_C
	dd &"//",	@TOKEN_COMMENT_CPP
	dd 0


:__lex_inited
	dd 0
:__lex_multibyte_tokens_hash
	dd 0
:__lex_string_tokens_hash
	dd 0

#===========================================================================
# Internal method to initialize the lex system.
#===========================================================================
:__lex_init
	%local ht

	# Initialize (if not already initialized)
	mov @tmp0, :__lex_inited
	ld.d @tmp0, [@tmp0]
	eq @tmp0, 1
	%ret?

	mov @tmp0, :__lex_inited
	st.d [@tmp0], 1

	# Toss the string tokens into a hash table
	%call :_ht_init, :__lex_hash_table_test_key_hash, :__lex_hash_table_test_key_compare
	mov @ht, @ret
	mov @tmp0, :__lex_string_tokens_hash
	st.d [@tmp0], @ht
	%call :_ht_insert_table, @ht, :string_tokens

	# Toss the multi-byte tokens into a hash table
	%call :_ht_init, :__lex_hash_table_test_key_hash, :__lex_hash_table_test_key_compare
	mov @ht, @ret
	mov @tmp0, :__lex_multibyte_tokens_hash
	st.d [@tmp0], @ht
	%call :_ht_insert_table, @ht, :multibyte_op_tokens

	%ret
#===========================================================================


#===========================================================================
# void _lex_consume_identifier(lex_file* file, char* buffer,
#                              int buffer_length)
#===========================================================================
:__lex_consume_identifier
	%arg fd
	%arg buffer
	%arg buffer_length
	%local mark

	%call :__lex_read, @fd
	st.b [@buffer], @ret
	add @buffer, 1
.loop
	%call :__lex_peek, @fd

	# If done, return
	%call :_islabel, @ret
	eq @ret, @NULL
	jump? .done

	%call :__lex_read, @fd
	st.b [@buffer], @ret

	add @buffer, 1
	jump .loop

.done
	st.b [@buffer], 0
	mov @ret, @TOKEN_IDENTIFIER
	%ret
#===========================================================================


#===========================================================================
# int _lex_digit(lex_file* file, char* buffer, int buffer_length)
#===========================================================================
:__lex_digit
	%arg fd
	%arg buffer
	%arg buffer_length
	%local mark

	%call :__lex_read, @fd
	st.b [@buffer], @ret
	add @buffer, 1

.loop
	%call :__lex_peek, @fd
	%call :_isdigit, @ret
	eq @ret, @FALSE
	jump? .done

	%call :__lex_read, @fd
	st.b [@buffer], @ret

	add @buffer, 1
	jump .loop

.done
	st.b [@buffer], 0
	mov @ret, @TOKEN_CONSTANT
	%ret
#===========================================================================


#===========================================================================
# int _lex_comment_c(lex_file* file)
#===========================================================================
:__lex_comment_c
	%ret
#===========================================================================


#===========================================================================
# int _lex_comment_cpp(lex_file* file)
#===========================================================================
:__lex_comment_cpp
	%arg fd
.loop
	%call :__lex_read, @fd
	eq @ret, 10
	jump? .done
	jump .loop
.done
	%ret
#===========================================================================


#===========================================================================
# int _lex_string(lex_file* file, char* buffer, int buffer_length)
#===========================================================================
:__lex_string
	%arg fd
	%arg buffer
	%arg buffer_length
	%local mark

	%call :__lex_read, @fd

.loop
	%call :__lex_read, @fd
	eq @ret, '"'
	jump? .done

	st.b [@buffer], @ret
	add @buffer, 1
	jump .loop

.done
	st.b [@buffer], 0
	mov @ret, @TOKEN_STRING_LITERAL
	%ret
#===========================================================================


#===========================================================================
# int __lex_char_literal(lex_file* file, char* buffer, int buffer_length)
#===========================================================================
:__lex_char_literal
	%arg fd
	%arg buffer
	%arg buffer_length
	%local mark

	%call :__lex_read, @fd
	st.b [@buffer], @ret
	add @buffer, 1

.loop
	%call :__lex_read, @fd
	st.b [@buffer], @ret
	add @buffer, 1
	eq @ret, 39
	jump? .done

	jump .loop

.done
	st.b [@buffer], 0
	mov @ret, @TOKEN_CONSTANT
	%ret
#===========================================================================


#===========================================================================
# void _lex_handle_preprocessor(lex_file* file, int preprocessor_token)
#===========================================================================
:__lex_handle_preprocessor
	%arg fd
	%arg token
	%local identifier
	%local index
	%local value

	eq @token, @PP_INCLUDE
	jump? .include

	eq @token, @PP_DEFINE
	jump? .define

	%call :_fatal, &"Unexpected token"

.include
	# TODO
	%ret

.define
	%call :__lex_peek, @fd
	%call :_iswhitespace
	eq @ret, @FALSE
	jump? .ws_def_id
	%call :__lex_read, @fd
	jump .define

.ws_def_id
	%call :__lex_consume_identifier, @fd, .buffer, 32
	eq @ret, @TOKEN_IDENTIFIER
	jump? .is_identifier

	%call :_fatal, &"Unexpected token"

.is_identifier
	%call :__lex_peek, @fd
	%call :_iswhitespace
	eq @ret, @FALSE
	jump? .ws_def_value
	%call :__lex_read, @fd
	jump .is_identifier

.ws_def_value
	%call :_stralloc, .buffer
	mov @identifier, @ret
	mov @index, 0

.loop
	%call :__lex_read, @fd
	eq @ret, 10
	jump? .eol

	mov @tmp0, @index
	add @tmp0, .buffer
	st.b [@tmp0], @ret
	add @index, 1

	eq @ret, -1
	%call? :_fatal, &"Unexpected EOF in #define"

	jump .loop

.eol
	mov @tmp0, @index
	add @tmp0, .buffer
	st.b [@tmp0], 0

	%call :_stralloc, .buffer
	mov @value, @ret

	%call :__lex_define_macro, @fd, @identifier, @value

	%ret

.buffer

	db 0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0
#===========================================================================


#===========================================================================
# int _lex_multibyte_operator(char* buffer)
#===========================================================================
:__lex_is_valid_operator
	%arg buffer
	%local c

	# Check to see if we have a multi-byte op
	mov @tmp0, @buffer
	add @tmp0, 1
	ld.b @tmp0, [@tmp0]
	eq @tmp0, 0
	jump? .single

	ld.d @tmp0, [:__lex_multibyte_tokens_hash]
	%call :_ht_lookup, @tmp0, @buffer
	%ret

.single
	ld.b @c, [@buffer]
	%call :_strchr, :literal_tokens, @c
	eq @ret, 0
	mov^ @ret, @c
	%ret
#===========================================================================


#===========================================================================
# int _lex_multibyte_operator(lex_file* file, char* buffer, int buffer_length)
#===========================================================================
:__lex_operator
	%arg fd
	%arg buffer
	%arg buffer_length
	%local current
	%local last
	%local c

	mov @last, 0
	mov @current, @buffer

	# Zero out the buffer
	st.d [@buffer], 0
	mov @tmp0, @buffer
	add @tmp0, 4
	st.d [@tmp0], 0

.loop
	%call :__lex_peek, @fd
	mov @c, @ret
	st.b [@current], @c

	%call :__lex_is_valid_operator, @buffer
	eq @ret, @NULL
	jump? .done

	mov @last, @ret
	add @current, 1
	%call :__lex_read, @fd
	jump .loop

.done
	st.b [@current], 0
	mov @ret, @last
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
	%local tmp
	%local tmp2

	# Initialize our lex subsystem if it hasn't been already
	%call :__lex_init

	st.b [@buffer], 0

	# If there's a token already peeked, just return it
	%call :__lex_get_peek_token, @fd
	eq @ret, @TOKEN_NONE
	jump? .whitespace_loop
	mov @tmp, @ret

	# Remove the peeked token from the peek buffer
	%call :__lex_set_peek_token, @fd, @TOKEN_NONE
	%call :__lex_get_token_buf, @fd
	mov @tmp2, @ret
	%call :_strcpy, @buffer, @tmp2
	mov @ret, @tmp
	%ret

.whitespace_loop
	# Read from the file handle
	%call :__lex_peek, @fd
	mov @c, @ret

	# EOF?
	eq @c, @TOKEN_EOF
	%ret?

	# EOT?
	eq @c, @TOKEN_EOT
	jump? .whitespace

	# Eat whitespace
	%call :_iswhitespace, @c
	eq @ret, @TRUE
	jump? .whitespace

	jump .not_whitespace

.whitespace
	%call :__lex_read, @fd
	jump .whitespace_loop

.not_whitespace
	ne @c, '#'
	jump? .not_preprocessor

	%call :__lex_read, @fd

	%call :__lex_consume_identifier, @fd, @buffer, @buffer_length

	%call :_streq, @buffer, &"include"
	eq @ret, @TRUE
	mov? @tmp0, @PP_INCLUDE
	jump? .pre

	%call :_streq, @buffer, &"define"
	eq @ret, @TRUE
	mov? @tmp0, @PP_DEFINE
	jump? .pre

	%call :_fatal, &"Unexpected preprocessor token"

.pre
	%call :__lex_handle_preprocessor, @fd, @tmp0

	# We never return preprocessor commands - they are silently handled and modify our combined lexer state
	jump .whitespace_loop

.not_preprocessor
	# Attempt to match label/identifier
	%call :_islabelstart, @c
	eq r0, @FALSE
	jump? .not_identifier

	# This could be a keyword, a macro, or an identifier
	%call :__lex_consume_identifier, @fd, @buffer, @buffer_length

	# Is it a macro?
	%call :__lex_activate_macro, @fd, @buffer
	eq @ret, 0
	jump^ .whitespace_loop

	# Not a macro, check keywords first
	ld.d @tmp0, [:__lex_string_tokens_hash]
	%call :_ht_lookup, @tmp0, @buffer
	# If it's a keyword, return that keyword
	eq @ret, 0
	%ret^

	# If not a keyword, then it's an identifier
	mov @ret, @TOKEN_IDENTIFIER
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
	eq @c, '"'
	jump^ .not_quote
	%call :__lex_string, @fd, @buffer, @buffer_length # tail call
	%ret

.not_quote
	eq @c, 39
	jump^ .not_squote
	%call :__lex_char_literal, @fd, @buffer, @buffer_length # tail call
	%ret

.not_squote
	# Attempt to match operators
	%call :__lex_operator, @fd, @buffer, @buffer_length
	eq @ret, @TOKEN_COMMENT_CPP
	jump^ .not_comment_cpp
	%call :__lex_comment_cpp, @fd
	jump .whitespace_loop
.not_comment_cpp
	eq @ret, @TOKEN_COMMENT_C
	jump^ .not_comment_c
	%call :__lex_comment_c, @fd
	jump .whitespace_loop
.not_comment_c
	eq @ret, @NULL
	%ret^

.not_operator
	%call :_fatal, &"Unexpected character"

.done
	%ret
#===========================================================================


#===========================================================================
# int lex_peek(lex_file* file, char* buffer, int buffer_length)
#
# Returns:
#   Lexical token type (or NULL if no token found)
#===========================================================================
:_lex_peek
	%arg fd
	%arg buffer
	%arg buffer_length
	%local token
	%local token_buf

	%call :__lex_get_token_buf, @fd
	mov @token_buf, @ret

	# If there's a token already peeked, we don't need to re-read
	%call :__lex_get_peek_token, @fd
	mov @token, @ret
	eq @token, @TOKEN_NONE
	jump^ .read

	# Read the token into the peek buffer
	%call :_lex, @fd, @token_buf, @buffer_length
	mov @token, @ret
	%call :__lex_set_peek_token, @fd, @token

.read
	eq @buffer, 0
	jump? .no_strcpy
	%call :_strcpy, @buffer, @token_buf

.no_strcpy
	# Return the actual token
	mov @ret, @token
	%ret
#===========================================================================


#===========================================================================
# Args:
#   R0: char
# Returns:
#   R0: 1 if true
#===========================================================================
:_islabelstart
	eq r0, '_'
	jump? .rettrue
	call :_isalpha
	eq r0, $1
	jump? .rettrue
	mov r0, $0
	ret
.rettrue
	mov r0, $1
	ret
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

