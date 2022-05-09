#include "regs.h"

#define HT_OVERHEAD 20
#define HT_NODE_SIZE 12

:_ht_int_key_hash
	%arg key
	mov @ret, @key
	%ret

:_ht_int_key_compare
	%arg key1
	%arg key2
	eq @key1, @key2
	mov? @ret, 1
	mov^ @ret, 0
	%ret

#===========================================================================
# ht* ht_init(void* key_hash_function, void* key_compare_function)
#
# Creates a hash table
#===========================================================================
:_ht_init
	%arg key_hash_function
	%arg key_compare_function
	%local ht
	%local buckets
	mov @buckets, 13
	mov @tmp0, @buckets
	mul @tmp0, 4
	add @tmp0, @HT_OVERHEAD
	%call :_malloc, @tmp0
	mov @ht, @ret
	# Bucket count
	st.d [@ret], @buckets
	add @ret, 4
	st.d [@ret], @key_hash_function
	add @ret, 4
	st.d [@ret], @key_compare_function
	add @ret, 12
	# Zero the buckets
.loop
	eq @buckets, 0
	mov? r0, @ht
	%ret?
	st.d, [@ret], 0
	add @ret, 4
	sub @buckets, 1
	jump .loop
#===========================================================================


#===========================================================================
# void* ht_lookup(void* ht, void* key)
#===========================================================================
:_ht_lookup
	%arg ht
	%arg key
	%local hash
	%call :__ht_hash @ht, @key
	mov @hash, @ret
	# Which bucket?
	ld.d @tmp0, [@ht]
	mov @tmp1, @hash
	mod @tmp1, @tmp0
	mul @tmp1, 4
	add @tmp1, @HT_OVERHEAD
	add @tmp1, @ht
	# If the bucket is NULL, the item doesn't exist
	ld.d @tmp0, [@tmp1]
	eq @tmp0, 0
	mov? @ret, 0
	jump? .done
	# Exists, so now search it
	mov @tmp1, @ht
	add @tmp1, 12
	st.d [@tmp1], @hash
	add @tmp1, 4
	st.d [@tmp1], @key
	%call :_ll_search, @tmp0, :__ht_ll_lookup_func, @ht
	eq @ret, 0
	jump? .done
	add @ret, 8
	ld.d @ret, [@ret]
.done
	%ret
#===========================================================================


#===========================================================================
# void ht_insert(void* ht, void* key, void* value)
#===========================================================================
:_ht_insert
	%arg ht
	%arg key
	%arg value
	%local hash
	%local ll
	%local llptr
	%local node
	%call :__ht_hash @ht, @key
	mov @hash, @ret
	# Which bucket?
	ld.d @tmp0, [@ht]
	mov @llptr, @hash
	mod @llptr, @tmp0
	mul @llptr, 4
	add @llptr, @HT_OVERHEAD
	add @llptr, @ht
	# If the bucket is NULL, create it
	ld.d @ll, [@llptr]
	ne @ll, 0
	jump? .exists
	%call :_ll_init
	mov @ll, @ret
	st.d [@llptr], @ll
.exists
	%call :_ll_create_node, @HT_NODE_SIZE
	mov @node, @ret
	mov @tmp0, @node
	st.d [@tmp0], @hash
	add @tmp0, 4
	st.d [@tmp0], @key
	add @tmp0, 4
	st.d [@tmp0], @value

	%call :_ll_insert_head, @ll, @node
	%ret
#===========================================================================


#===========================================================================
# void ht_insert_table(void* ht, void* table)
#===========================================================================
:_ht_insert_table
	%arg ht
	%arg table
.loop
	ld.d @tmp0, [@table]
	eq @tmp0, 0
	jump? .done
	add @table, 4
	ld.d @tmp1, [@table]
	add @table, 4
	%call :_ht_insert, @ht, @tmp0, @tmp1
	jump .loop
.done
	%ret


#===========================================================================
# Lookup func
#===========================================================================
:__ht_ll_lookup_func
	%arg node
	%arg ht
	mov @tmp1, @ht
	add @tmp1, 12
	# Quick check on hash
	ld.d @tmp0, [@node]
	ne @tmp0, [@tmp1]
	mov? @ret, 0
	jump? .ret
	# If hash matches, call lookup func
	add @tmp1, 4
	mov @tmp2, [@tmp1]
	add @node, 4
	ld.d @tmp0, [@node]
	add @ht, 8
	ld.d @tmp1, [@ht]
	%call @tmp1, @tmp0, @tmp2
.ret
	%ret
#===========================================================================


#===========================================================================
# Hashes a key based on the hash function in the table
#===========================================================================
:__ht_hash
	%arg ht
	%arg key
	mov @tmp0, @ht
	add @tmp0, 4
	ld.d @tmp0, [@tmp0]
	%call @tmp0 @key
	%ret
#===========================================================================
