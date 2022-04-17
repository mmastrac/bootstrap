#!/bin/sh
set -x
set -e

# Delete build products
mkdir -p out/
rm -f out/b1.bin out/b2.bin out/b3.bin

# Perform the build
cc vm.c -std=c99 -D_ATFILE_SOURCE=1 -o vm
./vm bootstrap/bootstrap0.bin bootstrap/bootstrap1.s out/b1.bin
./vm out/b1.bin bootstrap/bootstrap2.s out/b2.bin
./vm out/b2.bin bootstrap/bootstrap3.s out/b3.bin

# Verify correctness of build products
sha256sum -c checksums.txt || shasum -a 256 -c checksums.txt
