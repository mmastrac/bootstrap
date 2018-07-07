#include "regs.h"

:_linked_list_test
	dd &"linked_list"
	dd :_linked_list_test_walk, &"test_walk"
	dd :_linked_list_test_insert_remove, &"test_insert_remove"
	dd 0, 0

:_linked_list_test_find_none
	mov @ret, 0
	ret

:_linked_list_test_find_string
	%arg node
	%arg data
	ld.d @node, [@node]
	%call :_strcmp, @node, @data
	eq @ret, 0
	mov? r0, 1
	mov^ r0, 0
	%ret

:_linked_list_test_find_digit
	%arg node
	%arg data
	add @node, 4
	ld.d @node, [@node]
	eq @node, @data
	mov? r0, 1
	mov^ r0, 0
	%ret

:_linked_list_test_walk
	%local ll
	%local node
	%local nodea
	%local nodeb
	%local nodec

	%call :_ll_init
	mov @ll, @ret

	%call :_ll_create_node, 8
	mov @node, @ret
	mov @nodea, @node
	%call :_ll_insert_head, @ll, @node
	st.d [@node], .node_a
	add @node, 4
	st.d [@node], 1

	%call :_ll_create_node, 8
	mov @node, @ret
	mov @nodeb, @node
	%call :_ll_insert_head, @ll, @node
	st.d [@node], .node_b
	add @node, 4
	st.d [@node], 2

	%call :_ll_create_node, 8
	mov @node, @ret
	mov @nodec, @node
	%call :_ll_insert_head, @ll, @node
	st.d [@node], .node_c
	add @node, 4
	st.d [@node], 3

	%call :_ll_search, @ll, :_linked_list_test_find_none, 0
	%call :_test_assert_zero, @ret, &"Expected NULL"

	%call :_ll_search, @ll, :_linked_list_test_find_string, .node_a
	%call :_test_assert_equal, @ret, @nodea, &"Expected node A"
	%call :_ll_search, @ll, :_linked_list_test_find_string, .node_b
	%call :_test_assert_equal, @ret, @nodeb, &"Expected node B"
	%call :_ll_search, @ll, :_linked_list_test_find_string, .node_c
	%call :_test_assert_equal, @ret, @nodec, &"Expected node C"
	%call :_ll_search, @ll, :_linked_list_test_find_string, .node_d
	%call :_test_assert_zero, @ret, &"Expected NULL"

	%call :_ll_search, @ll, :_linked_list_test_find_digit, 1
	%call :_test_assert_equal, @ret, @nodea, &"Expected node A"
	%call :_ll_search, @ll, :_linked_list_test_find_digit, 2
	%call :_test_assert_equal, @ret, @nodeb, &"Expected node B"
	%call :_ll_search, @ll, :_linked_list_test_find_digit, 3
	%call :_test_assert_equal, @ret, @nodec, &"Expected node C"
	%call :_ll_search, @ll, :_linked_list_test_find_digit, 4
	%call :_test_assert_zero, @ret, &"Expected NULL"

	%ret

.node_a
	ds "A"
.node_b
	ds "B"
.node_c
	ds "C"
.node_d
	ds "D"

:_linked_list_test_insert_remove
	%local ll
	%local node
	%local nodea
	%local nodeb
	%local nodec

	%call :_ll_init
	mov @ll, @ret

	%call :_ll_create_node, 8
	mov @node, @ret
	mov @nodea, @node
	%call :_ll_insert_head, @ll, @node
	st.d [@node], .node_a
	add @node, 4
	st.d [@node], 1

	%call :_ll_create_node, 8
	mov @node, @ret
	mov @nodeb, @node
	%call :_ll_insert_head, @ll, @node
	st.d [@node], .node_b
	add @node, 4
	st.d [@node], 2

	%call :_ll_create_node, 8
	mov @node, @ret
	mov @nodec, @node
	%call :_ll_insert_head, @ll, @node
	st.d [@node], .node_c
	add @node, 4
	st.d [@node], 3

	%call :_ll_search, @ll, :_linked_list_test_find_string, .node_a
	%call :_test_assert_equal, @ret, @nodea, &"Expected node A"

	%call :_ll_remove_head, @ll
	%call :_test_assert_equal, @ret, @nodec, &"Expected node C"

	%call :_ll_search, @ll, :_linked_list_test_find_string, .node_a
	%call :_test_assert_equal, @ret, @nodea, &"Expected node A"

	%call :_ll_remove_head, @ll
	%call :_test_assert_equal, @ret, @nodeb, &"Expected node B"

	%call :_ll_search, @ll, :_linked_list_test_find_string, .node_a
	%call :_test_assert_equal, @ret, @nodea, &"Expected node A"

	%call :_ll_remove_head, @ll
	%call :_test_assert_equal, @ret, @nodea, &"Expected node A"

	%call :_ll_search, @ll, :_linked_list_test_find_string, .node_a
	%call :_test_assert_equal, @ret, 0, &"Expected NULL"

	%call :_ll_remove_head, @ll
	%call :_test_assert_equal, @ret, 0, &"Expected NULL"

	%ret

.node_a
	ds "A"
.node_b
	ds "B"
.node_c
	ds "C"
