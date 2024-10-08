#!/bin/bash
set -euox pipefail
cc vm.c -std=c99 -D_ATFILE_SOURCE=1 -o vm

ROOT=bootstrap
TEST=$ROOT/tests
BUILD=out
rm -rf "$BUILD" || true
mkdir "$BUILD"

echo Compile 1
./vm $ROOT/bootstrap0.bin $ROOT/bootstrap1/bootstrap1.s $BUILD/b1.bin

echo Test 1
./vm $BUILD/b1.bin $TEST/bootstrap1/test1.s $BUILD/t1.bin
diff $TEST/bootstrap1/test1.bin $BUILD/t1.bin

echo Compile 2
./vm $BUILD/b1.bin $ROOT/bootstrap2/bootstrap2.s $BUILD/b2.bin
echo Test 2
./vm $BUILD/b2.bin $TEST/bootstrap2/test1.s $BUILD/t1.bin
diff $TEST/bootstrap2/test1.bin $BUILD/t1.bin
echo Test 2
./vm $BUILD/b2.bin $TEST/bootstrap2/test2.s $BUILD/t2.bin
diff $TEST/bootstrap2/test2.bin $BUILD/t2.bin
echo Test 2
./vm $BUILD/b2.bin $TEST/bootstrap2/test3.s $BUILD/t3.bin
diff $TEST/bootstrap2/test3.bin $BUILD/t3.bin
echo Test 2
./vm $BUILD/b2.bin $TEST/bootstrap2/test4.s $BUILD/t4.bin
diff $TEST/bootstrap2/test4.bin $BUILD/t4.bin
echo Test 2
./vm $BUILD/b2.bin $TEST/bootstrap2/test5.s $BUILD/t5.bin
diff $TEST/bootstrap2/test5.bin $BUILD/t5.bin
echo Test 2
./vm $BUILD/b2.bin $TEST/bootstrap2/test6.s $BUILD/t6.bin
diff $TEST/bootstrap2/test6.bin $BUILD/t6.bin
echo Test 2
./vm $BUILD/b2.bin $TEST/bootstrap2/test7.s $BUILD/t7.bin
diff $TEST/bootstrap2/test7.bin $BUILD/t7.bin

echo Compile 3
./vm $BUILD/b2.bin $ROOT/bootstrap3/bootstrap3.s $BUILD/b3.bin
echo Test 3
./vm $BUILD/b3.bin $TEST/bootstrap3/test1.s $BUILD/t1.bin
diff $TEST/bootstrap3/test1.bin $BUILD/t1.bin
echo Test 3
./vm $BUILD/b3.bin $TEST/bootstrap3/test2.s $BUILD/t2.bin
diff $TEST/bootstrap3/test2.bin $BUILD/t2.bin
echo Test 3
./vm $BUILD/b3.bin $TEST/bootstrap3/test3.s $BUILD/t3.bin
diff $TEST/bootstrap3/test3.bin $BUILD/t3.bin
echo Test 3
./vm $BUILD/b3.bin $TEST/bootstrap3/test4.s $BUILD/t4.bin
diff $TEST/bootstrap3/test4.bin $BUILD/t4.bin
echo Test 3
./vm $BUILD/b3.bin $TEST/bootstrap3/test5.s $BUILD/t5.bin
diff $TEST/bootstrap3/test5.bin $BUILD/t5.bin
echo Test 3
./vm $BUILD/b3.bin $TEST/bootstrap3/test6.s $BUILD/t6.bin
diff $TEST/bootstrap3/test6.bin $BUILD/t6.bin
echo Test 3
./vm $BUILD/b3.bin $TEST/bootstrap3/test7.s $BUILD/t7.bin
diff $TEST/bootstrap3/test7.bin $BUILD/t7.bin
echo Test 3
./vm $BUILD/b3.bin $TEST/bootstrap3/test8.s $BUILD/t8.bin
diff $TEST/bootstrap3/test8.bin $BUILD/t8.bin
echo Test 3
./vm $BUILD/b3.bin -I $ROOT/include $TEST/bootstrap3/test9.s $BUILD/t9.bin
diff $TEST/bootstrap3/test9.bin $BUILD/t9.bin
echo Test 3
./vm $BUILD/b3.bin $TEST/bootstrap3/test10.s $BUILD/t10.bin
diff $TEST/bootstrap3/test10.bin $BUILD/t10.bin
echo Test 3
./vm $BUILD/b3.bin $TEST/bootstrap3/test11.s $BUILD/t11.bin
diff $TEST/bootstrap3/test11.bin $BUILD/t11.bin

echo Error 3
./vm $BUILD/b3.bin $TEST/bootstrap3/error/error0.s $BUILD/out.bin && exit 1
echo Error 3
./vm $BUILD/b3.bin $TEST/bootstrap3/error/error1.s $BUILD/out.bin && exit 1

echo Test 4
./vm $BUILD/b3.bin -l -I $ROOT/include $TEST/bootstrap4/test1.s $ROOT/bootstrap4/rt/crt0.s $ROOT/bootstrap4/rt/memory.s $ROOT/bootstrap4/rt/string.s $ROOT/bootstrap4/rt/sys.s $BUILD/t4.bin
./vm $BUILD/t4.bin
echo Test 4
./vm $BUILD/b3.bin -l -I $ROOT/include $TEST/bootstrap4/test2.s $ROOT/bootstrap4/rt/crt0.s $ROOT/bootstrap4/rt/memory.s $ROOT/bootstrap4/rt/string.s $ROOT/bootstrap4/rt/sys.s $ROOT/bootstrap4/rt/dprintf.s $BUILD/t4.bin
./vm $BUILD/t4.bin
echo Test 4
./vm $BUILD/b3.bin -l -I $ROOT/include $TEST/bootstrap4/test3.s $ROOT/bootstrap4/rt/crt0.s $ROOT/bootstrap4/rt/memory.s $ROOT/bootstrap4/rt/string.s $ROOT/bootstrap4/rt/sys.s $ROOT/bootstrap4/rt/dprintf.s $BUILD/t4.bin
./vm $BUILD/t4.bin
echo Test 4
./vm $BUILD/b3.bin -l -I $ROOT/include $TEST/bootstrap4/test4.s $ROOT/bootstrap4/rt/crt0.s $ROOT/bootstrap4/rt/memory.s $ROOT/bootstrap4/rt/string.s $ROOT/bootstrap4/rt/sys.s $ROOT/bootstrap4/rt/dprintf.s $BUILD/t4.bin
./vm $BUILD/t4.bin

echo Test 4
./vm $BUILD/b3.bin -l -I $ROOT/include $ROOT/bootstrap4/rt/*.s $ROOT/bootstrap4/rt/tests/*.s $BUILD/t4.bin
./vm $BUILD/t4.bin
echo Test 4
./vm $BUILD/b3.bin -l -I $ROOT/include $ROOT/bootstrap4/rt/*.s $ROOT/bootstrap4/lex/lex.s $ROOT/bootstrap4/lex/lex_io.s $ROOT/bootstrap4/lex/tests/*.s $BUILD/t4.bin
./vm $BUILD/t4.bin

echo Compile 4
./vm $BUILD/b3.bin -l -I $ROOT/include $ROOT/bootstrap4/rt/*.s $ROOT/bootstrap4/lex/*.s $ROOT/bootstrap4/compiler0/*.s $BUILD/t4.bin
mkdir $BUILD/b4

echo Compile 4
./vm $BUILD/t4.bin $ROOT/bootstrap4/compiler0/tests/test_basic.c $BUILD/b4/test_basic.s
echo Compile 4
./vm $BUILD/t4.bin $ROOT/bootstrap4/compiler0/tests/test_binary.c $BUILD/b4/test_binary.s
echo Compile 4
./vm $BUILD/t4.bin $ROOT/bootstrap4/compiler0/tests/test_char_literal.c $BUILD/b4/test_char_literal.s
echo Compile 4
./vm $BUILD/t4.bin $ROOT/bootstrap4/compiler0/tests/test_compare.c $BUILD/b4/test_compare.s
echo Compile 4
./vm $BUILD/t4.bin $ROOT/bootstrap4/compiler0/tests/test_deref.c $BUILD/b4/test_deref.s
echo Compile 4
./vm $BUILD/t4.bin $ROOT/bootstrap4/compiler0/tests/test_fn_args.c $BUILD/b4/test_fn_args.s
echo Compile 4
./vm $BUILD/t4.bin $ROOT/bootstrap4/compiler0/tests/test_fn_in_fn.c $BUILD/b4/test_fn_in_fn.s
echo Compile 4
./vm $BUILD/t4.bin $ROOT/bootstrap4/compiler0/tests/test_for.c $BUILD/b4/test_for.s
echo Compile 4
./vm $BUILD/t4.bin $ROOT/bootstrap4/compiler0/tests/test_fib.c $BUILD/b4/test_fib.s
echo Compile 4
./vm $BUILD/t4.bin $ROOT/bootstrap4/compiler0/tests/test_function.c $BUILD/b4/test_function.s
echo Compile 4
./vm $BUILD/t4.bin $ROOT/bootstrap4/compiler0/tests/test_global.c $BUILD/b4/test_global.s
echo Compile 4
./vm $BUILD/t4.bin $ROOT/bootstrap4/compiler0/tests/test_if_else.c $BUILD/b4/test_if_else.s
echo Compile 4
./vm $BUILD/t4.bin $ROOT/bootstrap4/compiler0/tests/test_include.c $BUILD/b4/test_include.s
echo Compile 4
./vm $BUILD/t4.bin $ROOT/bootstrap4/compiler0/tests/test_inited.c $BUILD/b4/test_inited.s
echo Compile 4
./vm $BUILD/t4.bin $ROOT/bootstrap4/compiler0/tests/test_local.c $BUILD/b4/test_local.s
echo Compile 4
./vm $BUILD/t4.bin $ROOT/bootstrap4/compiler0/tests/test_string_literal.c $BUILD/b4/test_string_literal.s
echo Compile 4
./vm $BUILD/t4.bin $ROOT/bootstrap4/compiler0/tests/test_unary.c $BUILD/b4/test_unary.s
echo Compile 4
./vm $BUILD/b3.bin -l -I $ROOT/include $ROOT/bootstrap4/rt/*.s $ROOT/bootstrap4/compiler0/tests/*.s $BUILD/b4/test_*.s $BUILD/t4_0.bin
./vm $BUILD/t4_0.bin

echo Compile 4-1
mkdir $BUILD/b4-1
./vm $BUILD/t4.bin $ROOT/bootstrap4/compiler1/rt/heap.c $BUILD/b4-1/heap.s
./vm $BUILD/t4.bin $ROOT/bootstrap4/compiler1/rt/crt1.c $BUILD/b4-1/crt1.s
./vm $BUILD/t4.bin $ROOT/bootstrap4/compiler1/rt/printf.c $BUILD/b4-1/printf.s
./vm $BUILD/t4.bin $ROOT/bootstrap4/compiler1/compile_expr.c $BUILD/b4-1/compile_expr.s
./vm $BUILD/t4.bin $ROOT/bootstrap4/compiler1/compile_util.c $BUILD/b4-1/compile_util.s
./vm $BUILD/b3.bin -l -I $ROOT/include $ROOT/bootstrap4/lex/*.s $ROOT/bootstrap4/rt/string.s $ROOT/bootstrap4/rt/hash_table.s $ROOT/bootstrap4/rt/struct.s $ROOT/bootstrap4/rt/io.s $ROOT/bootstrap4/rt/sys.s $ROOT/bootstrap4/rt/linked_list.s $ROOT/bootstrap4/compiler1/rt/*.s $BUILD/b4-1/*.s $BUILD/b4-1.bin

./vm $BUILD/b4-1.bin

#echo Compile 4-1
#./vm $BUILD/t4.bin $ROOT/bootstrap4/compiler1/main.c $BUILD/b4/compiler1_main.s
#./vm $BUILD/t4.bin $ROOT/bootstrap4/compiler1/lex.c $BUILD/b4/compiler1_lex.s
#./vm $BUILD/t4.bin $ROOT/bootstrap4/compiler1/compile_file.c $BUILD/b4/compiler1_compile_file.s
#./vm $BUILD/t4.bin $ROOT/bootstrap4/compiler1/struct.c $BUILD/b4/compiler1_struct.s
#./vm $BUILD/t4.bin $ROOT/bootstrap4/compiler1/types.c $BUILD/b4/compiler1_types.s
#mkdir $BUILD/b4/t
#./vm $BUILD/t4.bin $ROOT/bootstrap4/compiler1/tests/tests.c $BUILD/b4/t/tests.s
#./vm $BUILD/t4.bin $ROOT/bootstrap4/compiler1/tests/test_lex.c $BUILD/b4/t/test_lex.s
#./vm $BUILD/b3.bin -l -I $ROOT/include $ROOT/bootstrap4/rt/*.s $ROOT/bootstrap4/lex/*.s $BUILD/b4/compiler1_*.s $BUILD/b4/t/*.s $BUILD/b4/t/t.bin
#./vm $BUILD/b4/t/t.bin
#
#./vm $BUILD/b3.bin -l -I $ROOT/include $ROOT/bootstrap4/rt/*.s $ROOT/bootstrap4/lex/*.s $BUILD/b4/compiler1_*.s $BUILD/b4-1.bin
#
#echo Compile 4-1
#mkdir $BUILD/b4-1
#./vm $BUILD/b4-1.bin $ROOT/bootstrap4/compiler1/tests/test_simple.c $BUILD/b4-1/test_struct.s
#echo Done
