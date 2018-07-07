# Singly-linked-list support
# Inserts nodes at the head

#include "regs.h"

#===========================================================================
# ll_head* ll_init()
#
# Initialize a linked list, return the handle in r0
#===========================================================================
:_ll_init
	%call :_malloc, 4
	st.d [@ret], $0
	ret
#===========================================================================


#===========================================================================
# ll_node* ll_create_node(int size)
#
# Creates an uninitialized node with the size in r0 (automatically including
# space for the link field at the beginning)
#===========================================================================
:_ll_create_node
	%arg size
	add @size, 4
	%call :_malloc, @size
	# Return a pointer to the buffer
	add @ret, 4
	%ret
#===========================================================================


#===========================================================================
# ll_node* node ll_remove_head(ll_head* ll)
#
# Removes the head node, returning the old node.
#===========================================================================
:_ll_remove_head
	%arg list
	%local old

	ld.d @old, [@list]
	eq @old, 0

	# If the list is already empty, just return 0
	mov? @ret, 0
	%ret?

	# Set up the next node
	mov @tmp0, @old
	ld.d @tmp0, [@tmp0]
	st.d [@list], @tmp0

	mov @ret, @old
	eq @ret, 0
	add^ @ret, 4
	%ret


#===========================================================================
# void ll_insert_head(ll_head* ll, ll_node* node)
#
# Inserts a node at the head of the list, updating the list's head pointer.
#===========================================================================
:_ll_insert_head
	%arg list
	%arg node
	%local old
	ld.d @old, [@list]
	sub @node, 4
	st.d [@list], @node
	st.d [@node], @old
	%ret
#===========================================================================


#===========================================================================
# ll_node* ll_search(ll_head* ll, ll_func* func, int data)
#
# Given a search function in r0, returns the first node that matches, or
# zero if no nodes match.
#
# If func returns non-zero, the record is considered a match.
#===========================================================================
:_ll_search
	%arg list
	%arg func
	%arg data
	%local record
	mov @record, @list
.loop
	ld.d @record, [@record]

	# Not found
	eq @record, 0
	mov? @ret, 0
	jump? .done

	mov r0, @record
	add r0, 4
	%call @func, r0, @data
	eq r0, 0
	jump? .loop
	mov @ret, @record
	add @ret, 4
.done
	%ret
#===========================================================================
