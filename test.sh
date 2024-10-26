#!/bin/bash
set -euox pipefail
cc vm.c -std=c99 -D_ATFILE_SOURCE=1 -o vm

ROOT=.
TEST=$ROOT/tests
BUILD=out
rm -rf "$BUILD" || true
mkdir "$BUILD"

IN=$ROOT/bootstrap0.bin
OUT=$BUILD/b1.bin

echo Compile 1
./vm $IN $ROOT/bootstrap1/bootstrap1.s $OUT

echo Test 1
./vm $OUT $TEST/bootstrap1/test1.s $BUILD/t1.bin
diff $TEST/bootstrap1/test1.bin $BUILD/t1.bin

IN=$OUT
OUT=$BUILD/b2.bin

echo Compile 2
./vm $IN $ROOT/bootstrap2/bootstrap2.s $OUT

echo Test 2
./vm $OUT $TEST/bootstrap2/test1.s $BUILD/t1.bin
diff $TEST/bootstrap2/test1.bin $BUILD/t1.bin
./vm $OUT $TEST/bootstrap2/test2.s $BUILD/t2.bin
diff $TEST/bootstrap2/test2.bin $BUILD/t2.bin
./vm $OUT $TEST/bootstrap2/test3.s $BUILD/t3.bin
diff $TEST/bootstrap2/test3.bin $BUILD/t3.bin
./vm $OUT $TEST/bootstrap2/test4.s $BUILD/t4.bin
diff $TEST/bootstrap2/test4.bin $BUILD/t4.bin
./vm $OUT $TEST/bootstrap2/test5.s $BUILD/t5.bin
diff $TEST/bootstrap2/test5.bin $BUILD/t5.bin
./vm $OUT $TEST/bootstrap2/test6.s $BUILD/t6.bin
diff $TEST/bootstrap2/test6.bin $BUILD/t6.bin
./vm $OUT $TEST/bootstrap2/test7.s $BUILD/t7.bin
diff $TEST/bootstrap2/test7.bin $BUILD/t7.bin

IN=$OUT
OUT=$BUILD/b3.bin

echo Compile 3
./vm $IN $ROOT/bootstrap3/bootstrap3.s $OUT

echo Test 3
./vm $OUT $TEST/bootstrap3/test1.s $BUILD/t1.bin
diff $TEST/bootstrap3/test1.bin $BUILD/t1.bin
./vm $OUT $TEST/bootstrap3/test2.s $BUILD/t2.bin
diff $TEST/bootstrap3/test2.bin $BUILD/t2.bin
./vm $OUT $TEST/bootstrap3/test3.s $BUILD/t3.bin
diff $TEST/bootstrap3/test3.bin $BUILD/t3.bin
./vm $OUT $TEST/bootstrap3/test4.s $BUILD/t4.bin
diff $TEST/bootstrap3/test4.bin $BUILD/t4.bin
./vm $OUT $TEST/bootstrap3/test5.s $BUILD/t5.bin
diff $TEST/bootstrap3/test5.bin $BUILD/t5.bin
./vm $OUT $TEST/bootstrap3/test6.s $BUILD/t6.bin
diff $TEST/bootstrap3/test6.bin $BUILD/t6.bin
./vm $OUT $TEST/bootstrap3/test7.s $BUILD/t7.bin
diff $TEST/bootstrap3/test7.bin $BUILD/t7.bin
./vm $OUT $TEST/bootstrap3/test8.s $BUILD/t8.bin
diff $TEST/bootstrap3/test8.bin $BUILD/t8.bin
./vm $OUT $TEST/bootstrap3/test9.s $BUILD/t9.bin
diff $TEST/bootstrap3/test9.bin $BUILD/t9.bin

IN=$OUT
OUT=$BUILD/b4.bin

echo Compile 4
./vm $IN $ROOT/bootstrap4/bootstrap4.s $OUT

echo Test 4
./vm $OUT $TEST/bootstrap4/test1.s $BUILD/t1.bin
diff $TEST/bootstrap4/test1.bin $BUILD/t1.bin
./vm $OUT $TEST/bootstrap4/test2.s $BUILD/t2.bin
diff $TEST/bootstrap4/test2.bin $BUILD/t2.bin
./vm $OUT $TEST/bootstrap4/test3.s $BUILD/t3.bin
diff $TEST/bootstrap4/test3.bin $BUILD/t3.bin
./vm $OUT $TEST/bootstrap4/test4.s $BUILD/t4.bin
diff $TEST/bootstrap4/test4.bin $BUILD/t4.bin
./vm $OUT $TEST/bootstrap4/test5.s $BUILD/t5.bin
diff $TEST/bootstrap4/test5.bin $BUILD/t5.bin
./vm $OUT $TEST/bootstrap4/test6.s $BUILD/t6.bin
diff $TEST/bootstrap4/test6.bin $BUILD/t6.bin
./vm $OUT $TEST/bootstrap4/test7.s $BUILD/t7.bin
diff $TEST/bootstrap4/test7.bin $BUILD/t7.bin
./vm $OUT $TEST/bootstrap4/test8.s $BUILD/t8.bin
diff $TEST/bootstrap4/test8.bin $BUILD/t8.bin
./vm $OUT -I $ROOT/bootstrap5/include $TEST/bootstrap4/test9.s $BUILD/t9.bin
diff $TEST/bootstrap4/test9.bin $BUILD/t9.bin
./vm $OUT $TEST/bootstrap4/test10.s $BUILD/t10.bin
diff $TEST/bootstrap4/test10.bin $BUILD/t10.bin
./vm $OUT $TEST/bootstrap4/test11.s $BUILD/t11.bin
diff $TEST/bootstrap4/test11.bin $BUILD/t11.bin

echo Error 4
./vm $OUT $TEST/bootstrap4/error/error0.s $BUILD/out.bin && exit 1
./vm $OUT $TEST/bootstrap4/error/error1.s $BUILD/out.bin && exit 1

IN=$OUT
OUT0=$BUILD/b5-0.bin
OUT1=$BUILD/b5-1.bin

echo Test RT 5
./vm $IN -l -I $ROOT/bootstrap5/include $TEST/bootstrap5/test1.s $ROOT/bootstrap5/rt/crt0.s $ROOT/bootstrap5/rt/memory.s $ROOT/bootstrap5/rt/string.s $ROOT/bootstrap5/rt/sys.s $BUILD/t4.bin
./vm $BUILD/t4.bin
./vm $IN -l -I $ROOT/bootstrap5/include $TEST/bootstrap5/test2.s $ROOT/bootstrap5/rt/crt0.s $ROOT/bootstrap5/rt/memory.s $ROOT/bootstrap5/rt/string.s $ROOT/bootstrap5/rt/sys.s $ROOT/bootstrap5/rt/dprintf.s $BUILD/t4.bin
./vm $BUILD/t4.bin
./vm $IN -l -I $ROOT/bootstrap5/include $TEST/bootstrap5/test3.s $ROOT/bootstrap5/rt/crt0.s $ROOT/bootstrap5/rt/memory.s $ROOT/bootstrap5/rt/string.s $ROOT/bootstrap5/rt/sys.s $ROOT/bootstrap5/rt/dprintf.s $BUILD/t4.bin
./vm $BUILD/t4.bin
./vm $IN -l -I $ROOT/bootstrap5/include $TEST/bootstrap5/test4.s $ROOT/bootstrap5/rt/crt0.s $ROOT/bootstrap5/rt/memory.s $ROOT/bootstrap5/rt/string.s $ROOT/bootstrap5/rt/sys.s $ROOT/bootstrap5/rt/dprintf.s $BUILD/t4.bin
./vm $BUILD/t4.bin

echo Test 5
./vm $IN -l -I $ROOT/bootstrap5/include $ROOT/bootstrap5/rt/*.s $ROOT/bootstrap5/rt/tests/*.s $BUILD/t4.bin
./vm $BUILD/t4.bin
./vm $IN -l -I $ROOT/bootstrap5/include $ROOT/bootstrap5/rt/*.s $ROOT/bootstrap5/lex/lex.s $ROOT/bootstrap5/lex/lex_io.s $ROOT/bootstrap5/lex/tests/*.s $BUILD/t4.bin
./vm $BUILD/t4.bin

echo Compile 5
./vm $IN -l -I $ROOT/bootstrap5/include $ROOT/bootstrap5/rt/*.s $ROOT/bootstrap5/lex/*.s $ROOT/bootstrap5/compiler0/*.s $OUT0

echo Compile 5
mkdir $BUILD/b5-0
./vm $OUT0 $ROOT/bootstrap5/compiler0/tests/test_basic.c $BUILD/b5-0/test_basic.s
./vm $OUT0 $ROOT/bootstrap5/compiler0/tests/test_binary.c $BUILD/b5-0/test_binary.s
./vm $OUT0 $ROOT/bootstrap5/compiler0/tests/test_char_literal.c $BUILD/b5-0/test_char_literal.s
./vm $OUT0 $ROOT/bootstrap5/compiler0/tests/test_compare.c $BUILD/b5-0/test_compare.s
./vm $OUT0 $ROOT/bootstrap5/compiler0/tests/test_deref.c $BUILD/b5-0/test_deref.s
./vm $OUT0 $ROOT/bootstrap5/compiler0/tests/test_fn_args.c $BUILD/b5-0/test_fn_args.s
./vm $OUT0 $ROOT/bootstrap5/compiler0/tests/test_fn_in_fn.c $BUILD/b5-0/test_fn_in_fn.s
./vm $OUT0 $ROOT/bootstrap5/compiler0/tests/test_for.c $BUILD/b5-0/test_for.s
./vm $OUT0 $ROOT/bootstrap5/compiler0/tests/test_fib.c $BUILD/b5-0/test_fib.s
./vm $OUT0 $ROOT/bootstrap5/compiler0/tests/test_function.c $BUILD/b5-0/test_function.s
./vm $OUT0 $ROOT/bootstrap5/compiler0/tests/test_global.c $BUILD/b5-0/test_global.s
./vm $OUT0 $ROOT/bootstrap5/compiler0/tests/test_if_else.c $BUILD/b5-0/test_if_else.s
./vm $OUT0 $ROOT/bootstrap5/compiler0/tests/test_include.c $BUILD/b5-0/test_include.s
./vm $OUT0 $ROOT/bootstrap5/compiler0/tests/test_inited.c $BUILD/b5-0/test_inited.s
./vm $OUT0 $ROOT/bootstrap5/compiler0/tests/test_local.c $BUILD/b5-0/test_local.s
./vm $OUT0 $ROOT/bootstrap5/compiler0/tests/test_string_literal.c $BUILD/b5-0/test_string_literal.s
./vm $OUT0 $ROOT/bootstrap5/compiler0/tests/test_unary.c $BUILD/b5-0/test_unary.s
./vm $IN -l -I $ROOT/bootstrap5/include $ROOT/bootstrap5/rt/*.s $ROOT/bootstrap5/compiler0/tests/*.s $BUILD/b5-0/test_*.s $BUILD/t5_0.bin
./vm $BUILD/t5_0.bin

echo Compile 5-1
mkdir $BUILD/b5-1
./vm $OUT0 $ROOT/bootstrap5/compiler1/rt/heap.c $BUILD/b5-1/heap.s
./vm $OUT0 $ROOT/bootstrap5/compiler1/rt/crt1.c $BUILD/b5-1/crt1.s
./vm $OUT0 $ROOT/bootstrap5/compiler1/rt/printf.c $BUILD/b5-1/printf.s
./vm $OUT0 $ROOT/bootstrap5/compiler1/compile_expr.c $BUILD/b5-1/compile_expr.s
./vm $OUT0 $ROOT/bootstrap5/compiler1/compile_type.c $BUILD/b5-1/compile_type.s
./vm $OUT0 $ROOT/bootstrap5/compiler1/compile_unit.c $BUILD/b5-1/compile_unit.s
./vm $OUT0 $ROOT/bootstrap5/compiler1/compile_util.c $BUILD/b5-1/compile_util.s
./vm $OUT0 $ROOT/bootstrap5/compiler1/main.c $BUILD/b5-1/main.s
./vm $IN -l -I $ROOT/bootstrap5/include $ROOT/bootstrap5/lex/*.s $ROOT/bootstrap5/rt/string.s $ROOT/bootstrap5/rt/hash_table.s $ROOT/bootstrap5/rt/struct.s $ROOT/bootstrap5/rt/io.s $ROOT/bootstrap5/rt/sys.s $ROOT/bootstrap5/rt/linked_list.s $ROOT/bootstrap5/compiler1/rt/*.s $BUILD/b5-1/*.s $OUT1

echo Test 5-1
mkdir $BUILD/b5-1t
./vm $OUT1 $ROOT/bootstrap5/compiler1/tests/c/test_varied_types.c $BUILD/b5-1t

#echo Compile 5-1
#./vm $BUILD/t4.bin $ROOT/bootstrap5/compiler1/main.c $BUILD/b5-0/compiler1_main.s
#./vm $BUILD/t4.bin $ROOT/bootstrap5/compiler1/lex.c $BUILD/b5-0/compiler1_lex.s
#./vm $BUILD/t4.bin $ROOT/bootstrap5/compiler1/compile_file.c $BUILD/b5-0/compiler1_compile_file.s
#./vm $BUILD/t4.bin $ROOT/bootstrap5/compiler1/struct.c $BUILD/b5-0/compiler1_struct.s
#./vm $BUILD/t4.bin $ROOT/bootstrap5/compiler1/types.c $BUILD/b5-0/compiler1_types.s
#mkdir $BUILD/b5-0/t
#./vm $BUILD/t4.bin $ROOT/bootstrap5/compiler1/tests/tests.c $BUILD/b5-0/t/tests.s
#./vm $BUILD/t4.bin $ROOT/bootstrap5/compiler1/tests/test_lex.c $BUILD/b5-0/t/test_lex.s
#./vm $BUILD/b3.bin -l -I $ROOT/include $ROOT/bootstrap5/rt/*.s $ROOT/bootstrap5/lex/*.s $BUILD/b5-0/compiler1_*.s $BUILD/b5-0/t/*.s $BUILD/b5-0/t/t.bin
#./vm $BUILD/b5-0/t/t.bin
#
#./vm $BUILD/b3.bin -l -I $ROOT/include $ROOT/bootstrap5/rt/*.s $ROOT/bootstrap5/lex/*.s $BUILD/b5-0/compiler1_*.s $BUILD/b4-1.bin
#
#echo Compile 5-1
#mkdir $BUILD/b4-1
#./vm $BUILD/b4-1.bin $ROOT/bootstrap5/compiler1/tests/test_simple.c $BUILD/b4-1/test_struct.s
#echo Done
