# Copyright      2016 Денис Крыськов
# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit crosstool-meets-uclibc fat-gentoo

HOMEPAGE=http://www.uclibc-ng.org
SRC_URI="$SRC_URI
 http://downloads.uclibc-ng.org/releases/$PV/uClibc-ng-$PV.tar.xz"

KEYWORDS='-* amd64'
SLOT=0

DEPEND="$CATEGORY/gcc-$PN"
RESTRICT=strip

src_unpack()
 {
  crosstool-meets-uclibc_src_unpack
 }

src_prepare()
 {
  # aint no usr/ in /usr/x86_64-linux-$PN/
  sed \
   -e 's|UCLIBC_RUNTIME_PREFIX "lib:.*|UCLIBC_RUNTIME_PREFIX "lib"|' \
   -e '/":" UCLIBC_RUNTIME_PREFIX/d' \
   -i utils/ldd.c || die

  sed \
   -e '/UCLIBC_RUNTIME_PREFIX "usr/d' \
   -i utils/ldconfig.c ldso/ldso/dl-elf.c

  sed s-lib:-lib- -i ldso/ldso/dl-elf.c

  # According to line
  #  TRUSTED_LDSO	UCLIBC_RUNTIME_PREFIX "lib/" UCLIBC_LDSO
  # ld64-uClibc.so.* is expected to be in $t/lib64. TODO: fix it?
 }

src_configure()
 {
  crosstool-meets-uclibc_src_configure

  # cook sysroot with all necessary headers
  sysroot=$S/sysroot
  fat-gentoo-copy_sysroot $sysroot temp.headers include
  i=$sysroot/usr/include
  # change .config accordingly
  sed -i .config -e s:KERNEL_HEADERS=.*:KERNEL_HEADERS=\"$i\": || die
 }

src_compile()
 {
  # TODO: CFLAGS='-O2 -march=native'
  PATH="$EPREFIX/usr/x86_64-linux-uclibc/bin:$PATH"
  uclibc_likes_it="$uclibc_likes_it STRIPTOOL=true"
  emake -j1 $uclibc_likes_it pregen
  # To get full command-line, add V=1 after emake
  emake $uclibc_likes_it all
 }

src_install()
 {
  t=$ED/usr/x86_64-linux-$PN
  PREFIX=$t emake $uclibc_likes_it install

  # aint no usr/ in $t
  { cd $t/usr && mv `ls` ../ && cd .. && rm -r usr; } || die

  # rename lib to lib64, adjust links accordingly
  b=$(basename $t)
  ( cd $b && mv lib lib64 ) || die
  cd lib || die
  for i in $(find . -name '*.so' -type l) ; do
   j=$(realpath -m --relative-to . $i)
   j=$(echo $j|sed s:/lib/:/lib64/:)
   ln -sf $j $i || die
   [ -h $i ] || die
  done
  { cd $t && mv lib lib64; } || die

  # /lib should contain loader ld64-uClibc.so.0. Create link
  (
   mkdir -p $ED/lib && cd $ED/lib &&
   ln -s ../usr/$b/$b/lib64/ld64-uClibc.so.0 && [ -h ld64-* ]
  ) \
  || die

  # script lib64/libc.so is broken, must fix file names
  f0=$EPREFIX/usr/$b/$b/lib64/libc.so.1
  f1=$EPREFIX/usr/$b/lib64/uclibc_nonshared.a
  f2=$(dirname $f0)/ld64-uClibc.so.1
  g=$(printf '%s %s AS_NEEDED ( %s )' $f0 $f1 $f2)
  g="GROUP ( $g )"
  sed -i lib64/libc.so -e "s:GROUP.*:$g:" || die

  # fix script lib64/libpthread.so, too
  f0=$(dirname $f0)/libpthread.so.1
  f1=$(dirname $f1)/libpthread_nonshared.a
  g=$(printf 'GROUP ( %s %s )' $f0 $f1)
  sed -i lib64/libpthread.so -e "s:GROUP.*:$g:" || die

  # libpthread.so wants libdl.so.1 and linker has problems finding it. Solve
  #  the problem by creating 10 symbolic links in /usr/x86_64-linux-$PN/lib64
  cd $t/$b/lib64 || die
  for i in $(find . -type l -name '*.so.1') ; do
   j=$(basename $i)
   ln -s ../$b/lib64/$j $t/lib64/ || die
  done

  unset CROSS_COMPILER_PREFIX uclibc_likes_it t b i j f0 f1 f2 g sysroot REALM
 }
