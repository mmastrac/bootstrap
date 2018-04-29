# Test data


ds "Hello world" $1

db "Hello world" $1

dw $1 $2 $9999 $1234

dd $1 $2 $9999 :label

ds "String"
dd :label
ds "String 2"
dd :label

:label
