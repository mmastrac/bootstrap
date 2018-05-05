#!/bin/bash
set -euox pipefail
cc -g vm.c -o vm

ROOT=bootstrap
TEST=$ROOT/tests
echo Compile 1
./vm $ROOT/bootstrap0.bin $ROOT/bootstrap1.s /tmp/b1.bin > /dev/null

echo Test 1
./vm /tmp/b1.bin $TEST/bootstrap1/test1.s /tmp/t1.bin > /dev/null
diff $TEST/bootstrap1/test1.bin /tmp/t1.bin

echo Compile 2
./vm /tmp/b1.bin $ROOT/bootstrap2.s /tmp/b2.bin > /dev/null
echo Test 2
./vm /tmp/b2.bin $TEST/bootstrap2/test1.s /tmp/t1.bin > /dev/null
diff $TEST/bootstrap2/test1.bin /tmp/t1.bin
echo Test 2
./vm /tmp/b2.bin $TEST/bootstrap2/test2.s /tmp/t2.bin > /dev/null
diff $TEST/bootstrap2/test2.bin /tmp/t2.bin
echo Test 2
./vm /tmp/b2.bin $TEST/bootstrap2/test3.s /tmp/t3.bin > /dev/null
diff $TEST/bootstrap2/test3.bin /tmp/t3.bin
echo Test 2
./vm /tmp/b2.bin $TEST/bootstrap2/test4.s /tmp/t4.bin > /dev/null
diff $TEST/bootstrap2/test4.bin /tmp/t4.bin
echo Test 2
./vm /tmp/b2.bin $TEST/bootstrap2/test5.s /tmp/t5.bin > /dev/null
diff $TEST/bootstrap2/test5.bin /tmp/t5.bin
echo Test 2
./vm /tmp/b2.bin $TEST/bootstrap2/test6.s /tmp/t6.bin > /dev/null
diff $TEST/bootstrap2/test6.bin /tmp/t6.bin
echo Test 2
./vm /tmp/b2.bin $TEST/bootstrap2/test7.s /tmp/t7.bin > /dev/null
diff $TEST/bootstrap2/test7.bin /tmp/t7.bin

echo Compile 3
./vm /tmp/b2.bin $ROOT/bootstrap3.s /tmp/b3.bin > /dev/null
echo Test 3
./vm /tmp/b3.bin $TEST/bootstrap3/test1.s /tmp/t1.bin > /dev/null
diff $TEST/bootstrap3/test1.bin /tmp/t1.bin
echo Test 3
./vm /tmp/b3.bin $TEST/bootstrap3/test2.s /tmp/t2.bin > /dev/null
diff $TEST/bootstrap3/test2.bin /tmp/t2.bin
echo Test 3
./vm /tmp/b3.bin $TEST/bootstrap3/test3.s /tmp/t3.bin > /dev/null
diff $TEST/bootstrap3/test3.bin /tmp/t3.bin
echo Test 3
./vm /tmp/b3.bin $TEST/bootstrap3/test4.s /tmp/t4.bin > /dev/null
diff $TEST/bootstrap3/test4.bin /tmp/t4.bin
echo Test 3
./vm /tmp/b3.bin $TEST/bootstrap3/test5.s /tmp/t5.bin > /dev/null
diff $TEST/bootstrap3/test5.bin /tmp/t5.bin

echo Compile 4
./vm /tmp/b3.bin $ROOT/bootstrap4.s /tmp/b4.bin > /dev/null

echo Done
