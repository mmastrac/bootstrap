#!/bin/sh
set -x
set -e

# Delete build products
mkdir -p out/
rm -f out/b1.bin out/b2.bin out/b3.bin out/b4.bin out/b5-0.bin

# Perform the build
cc vm.c -std=c99 -D_ATFILE_SOURCE=1 -o vm
./vm bootstrap0.bin bootstrap1/bootstrap1.s out/b1.bin
./vm out/b1.bin bootstrap2/bootstrap2.s out/b2.bin
./vm out/b2.bin bootstrap3/bootstrap3.s out/b3.bin
./vm out/b3.bin bootstrap4/bootstrap4.s out/b4.bin
./vm out/b4.bin -l -I bootstrap5/include bootstrap5/rt/*.s bootstrap5/lex/*.s bootstrap5/compiler0/*.s out/b5-0.bin

# Verify correctness of build products
sha256sum -c checksums.txt || shasum -a 256 -c checksums.txt
