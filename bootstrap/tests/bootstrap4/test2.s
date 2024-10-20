# Test for global/local labels

:global_label
mov r5, $1

.local_label
mov r0, .local_label

:global_label2

.local_label
mov r0, .local_label

mov r1, :global_label
mov r1, :global_label2

