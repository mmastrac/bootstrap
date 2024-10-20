# Array with stack-like operations

#include "regs.h"

#===========================================================================
# array* array_init(int capacity)
#
# Creates an array with zero size and a given capacity.
#===========================================================================
:_array_init
    %arg capacity
    %local size
    mov @size, @capacity
    # One slot for size, one for capacity
    add @size, 2
    # Four bytes per slot
    mul @size, 4
    %call :_malloc, @size
    st.d [@ret], 0
    add @ret, 4
    st.d [@ret], @capacity
    sub @ret, 4
    %ret

#===========================================================================
# void* array_get_buffer(array* array)
#===========================================================================
:_array_get_buffer
    %arg array
    add @array, 8
    mov @ret, @array
    %ret

#===========================================================================
# void* array_size(array* array)
#===========================================================================
:_array_size
    %arg array
    ld.d @ret, [@array]
    %ret

#===========================================================================
# void* array_size_set(array* array, int size)
#===========================================================================
:_array_size_set
    %arg array
    %arg size
    st.d [@array], @size
    %ret

#===========================================================================
# void array_push(array* array, void* item)
#===========================================================================
:_array_push
    %arg array
    %arg item
    %local size
    %call :_array_size, @array
    mov @size, @ret
    %call :_array_set, @array, @size, @item
    %ret

#===========================================================================
# void* array_pop(array* array)
#===========================================================================
:_array_pop
    %arg array
    %local size
    %call :_array_size, @array
    mov @size, @ret
    sub @size, 1
    st.d [@array], @size
    %call :_array_get, @array, @size
    %ret

#===========================================================================
# void* array_peek(array* array)
#===========================================================================
:_array_peek
    %arg array
    %local size
    %call :_array_size, @array
    mov @size, @ret
    sub @size, 1
    %call :_array_get, @array, @size
    %ret

#===========================================================================
# void* array_set(array* array, int index, int item)
#===========================================================================
:_array_set
    %arg array
    %arg index
    %arg item
    %local size
    %call :_array_size, @array
    # size = max(size, index + 1)
    mov @size, @ret
    add @index, 1
    gt @index, @size
    mov? @size, @index
    st.d [@array], @size
    # Now store the item
    add @index, 1
    mul @index, 4
    add @array, @index
    st.d [@array], @item
    mov @ret, @item
    %ret

#===========================================================================
# void* array_get(array* array, int index)
#===========================================================================
:_array_get
    %arg array
    %arg index
    # Skip size + capacity
    add @index, 2
    # Four bytes per slot
    mul @index, 4
    add @array, @index
    ld.d @ret, [@array]
    %ret
