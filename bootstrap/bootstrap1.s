=#0 0005
=#1 0300
=#2 1000
S+012   
=#1 0304
=(11
=#8 0000
S 81
=#1 0308
=(11
=#2 0601
=#9 0000
S+912   
=#4 0064
=#0 0001
- 22
S+0820  
?=02
=#5 00dc
J?5 
=[32
=#2 0009
?=32
=#5 00f0
J?5 
=#2 003a
?=32
=#5 0148
J?5 
=#2 0023
?=32
=#5 0194
J?5 
J 4 
#EOF
=#0 0007
- 11
S 01
#TAB
= 55
=#0 0001
- 22
S+0820  
=[32
=#2 000a
?=32
J?4 
=#0 0002
=#1 0001
= 29
- 33
S+0231  
J 5 
###COLON
=#0 0001
=#2 016c
=#6 0004
S+0826  
=#6 ????
=#0 0003
=#2 0000
S+0962  
J 4 
#COMMENT
=#0 0001
- 22
S+0820  
=[32
=#2 000a
?=32
J?4 
J 5 
####
# Second stage bootstrap
# Loads from bootstrap2.s, ignoring comment lines and supporting a special :abcd syntax
# that sets the current write address to that address
# R0: Scratch #1
# R1: Scratch #2
# R2: Scratch #3
# R3: Line prefix
# R4: Loop continue address
# R5: Subloop continue address
# R6: Address to write to
# R8: Input file handle
# R9: Output file handle
