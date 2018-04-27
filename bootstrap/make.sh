cc vm.c -o vm
./vm bootstrap/bootstrap0.bin bootstrap/bootstrap1.s /tmp/b1.bin
./vm /tmp/b1.bin bootstrap/bootstrap2.s /tmp/b2.bin
./vm /tmp/b2.bin bootstrap/bootstrap3.s /tmp/b3.bin
