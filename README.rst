toolchain that targets musl and uclibc
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

on x86_64 Gentoo. Compiled from source with glibc-targeting GCC

Design goals:
1. No need for extra compiler options. If something builds with x86_64-pc-linux-gnu-gcc,  it should build with x86_64-linux-musl-gcc and x86_64-linux-uclibc-gcc with exactly same flags.
 
2. No difficulties running compiled code. Dynamic executables find all standard libraries automatically, no need to set LD_LIBRARY_PATH. Code compiled with other compiler that targets musl or uclibc should work, too.
