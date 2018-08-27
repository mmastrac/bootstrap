# bootstrap

Bootstrap is a small VM (< 20 ops) with an ASCII encoding. The goal of this project is to create a readable and auditable
bootstrapping process to generate C binaries for this virtual platform or any other.

## Why?

 1. Trusted compilation - every program involved in compiling a given C program can be audited (combined with diverse double-compilation https://www.dwheeler.com/trusting-trust/ by running the VM on multiple platforms)
 2. Longevity - the VM spec is small enough that it can be contained in the executables it produces, allowing them to be run
    decades into the future
