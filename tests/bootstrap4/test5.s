# Test data

ds "Hello world" 1

db "Hello world" 1

dw $1 $2 9999 1234

dd $1 $2 9999 :label

ds "String"
dd :label
ds "String 2"
dd :label

:label

db 'a' 'b' 'c'

db -1, -2, -256
dw -1, -2, -65536
dd -1, -2, -2147483648

#define zero 0
db 0, 0x0, $0, @zero

