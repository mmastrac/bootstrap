#include "regs.h"

:_linked_list_test
	dd &"linked_list"
	dd :_linked_list_test_walk, &"test_walk"
	dd 0, 0

:_linked_list_test_find_none
	mov @ret, 0
	ret

:_linked_list_test_find_string
	mov @ret, 0
	ret

:_linked_list_test_find_digit
	mov @ret, 0
	ret

:_linked_list_test_walk
	%local ll
	%local node

	%call :_ll_init
	mov @ll, @ret

	%call :_ll_create_node, 8
	mov @node, @ret
	%call :_ll_insert_head, @ll, @node
	st.d [@node], .node_a
	add @node, 4
	st.d [@node], 1

	%call :_ll_create_node, 8
	mov @node, @ret
	%call :_ll_insert_head, @ll, @node
	st.d [@node], .node_b
	add @node, 4
	st.d [@node], 2

	%call :_ll_create_node, 8
	mov @node, @ret
	%call :_ll_insert_head, @ll, @node
	st.d [@node], .node_c
	add @node, 4
	st.d [@node], 3
	%ret

.node_a
	ds "A"
.node_b
	ds "B"
.node_c
	ds "C"
