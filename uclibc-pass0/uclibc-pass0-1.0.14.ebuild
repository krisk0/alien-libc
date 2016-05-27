# Copyright      2016 Денис Крыськов
# Distributed under the terms of the GNU General Public License v3

EAPI=5

# This ebuild install 3 .o files, 2 dummy .so and all uClibc headers

inherit crosstool-meets-uclibc

HOMEPAGE=http://www.uclibc-ng.org
SRC_URI="$SRC_URI
 http://downloads.uclibc-ng.org/releases/$PV/uClibc-ng-$PV.tar.xz"

RDEPEND=$CATEGORY/sysroot

KEYWORDS='-* amd64'
SLOT=0

DEPEND="$CATEGORY/kernel-headers-uclibc $CATEGORY/wrapped-gcc"

src_unpack()
 {
  crosstool-meets-uclibc_src_unpack
 }

src_configure()
 {
  crosstool-meets-uclibc_src_configure
  mkdir -p bin.too
  cp $EPREFIX/usr/x86_64-linux-uclibc/bin/uclibc-gcc \
   bin.too/${CROSS_COMPILER_PREFIX}gcc || die
  # does this work when $S has spaces inside?
  PATH="`pwd`/bin.too:$PATH"
 }

src_compile()
 {
  o=headers
  for i in 1 i n ; do
   o="$o lib/crt$i.o"
  done
  h="$uclibc_likes_it
     PREFIX=$EPREFIX/usr/x86_64-linux-uclibc/temp.headers"
  emake $h $o
  
  $EPREFIX/usr/x86_64-linux-uclibc/bin/uclibc-gcc -nostdlib -nostartfiles \
    -shared -xc /dev/null -o libc.so || die
 }

src_install()
 {
  # install headers. Assume $EPREFIX and build directory has no : inside
  h=$(echo $h|sed "s:PREFIX=$EPREFIX/usr:PREFIX=$ED/usr:")
  emake $h install_headers

  # install dummy .so
  t=$ED/usr/x86_64-linux-uclibc/temp.headers/usr/lib64
  ( mkdir $t && cp libc.so $t/ && cd $t && ln -s libc.so libm.so ) || die

  # install .o
  cd lib || die
  unset o
  for i in 1 i n ; do
   o="$o crt$i.o"
  done
  ( mkdir -p $t && cp -d $o $t/ ) || die
  
  # link lib -> lib64
  ( cd `dirname $t` && ln -s lib64 lib ) || die

  unset h CROSS_COMPILER_PREFIX t o i uclibc_likes_it
 }
