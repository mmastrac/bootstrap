#include "regs.h"

:_hash_table_test
	dd &"hash_table"
	dd :_hash_table_test_string, &"test_string"
	dd 0, 0

:__hash_table_test_key_compare
	%call :_strcmp
	eq @ret, 0
	mov? @ret, 1
	mov^ @ret, 0
	%ret

:__hash_table_test_key_hash
	%arg key
	%call :_strhash, @key
	%ret

:_hash_table_test_string
	%local ht
	%call :_ht_init, :__hash_table_test_key_hash, :__hash_table_test_key_compare
	mov @ht, @ret

	# Unique hashes
	%call :_ht_insert, @ht, &"A", 1
	%call :_ht_insert, @ht, &"B", 2
	# Specifically designed to collide
	%call :_ht_insert, @ht, &"Aa", 3
	%call :_ht_insert, @ht, &"BB", 4

	# Doesn't exist - bucket missing
	%call :_ht_lookup, @ht, &"C"
	%call :_test_assert_zero, @ret, &"Expected NULL"

	%call :_ht_lookup, @ht, &"A"
	%call :_test_assert_equal, @ret, 1, &"Expected A = 1"
	%call :_ht_lookup, @ht, &"B"
	%call :_test_assert_equal, @ret, 2, &"Expected B = 2"
	%call :_ht_lookup, @ht, &"Aa"
	%call :_test_assert_equal, @ret, 3, &"Expected Aa = 3"
	%call :_ht_lookup, @ht, &"BB"
	%call :_test_assert_equal, @ret, 4, &"Expected BB = 4"

	%ret

.node_a
	ds "A"
.node_b
	ds "B"
.node_c
	ds "C"
.node_d
	ds "D"
