# Various forms of load
ld.d r0, [r0]      # =(00
ld.d r0, [4]       # =$x ....=(0x
ld.d r0, [:memory] # =$x ....=(0x

# Equivalent version w/mov
mov r0, [r0]
mov r0, [4]
mov r0, [:memory]

# Same forms work for add/sub/etc (note that it forces 32-bit mode)
add r0, [r0]
sub r0, [r0]
add r0, [4]
add r0, [:memory]

# Note that st.d must specify at least one register as we only have one compiler temp
st.d [r0], r0
st.d [r0], 4
st.d [r0], :memory
st.d [r0], [r0]
st.d [r0], [4]
# We can legally store one memory location to another
st.d [r0], [:memory]
st.d [:memory], r0
st.d [4], r0

:memory
	dd 1234
