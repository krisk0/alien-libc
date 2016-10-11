# Copyright      2016 Денис Крыськов
# Distributed under the terms of the GNU General Public License v3

EAPI=5

inherit fat-gentoo

HOMEPAGE=http://www.musl-libc.org
myP=musl-$PV
SRC_URI=$myP.tar.gz

KEYWORDS='-* i386 amd64'
SLOT=0
S="$WORKDIR/$myP"

DEPEND="$CATEGORY/gcc-$PN"
RESTRICT=strip
QA_SONAME="${BASE_DIR#/}.*/libc.so"
QA_DT_NEEDED="${BASE_DIR#/}.*/libc.so"

src_prepare()
 {
  local q=/lib:/usr/local/lib:/usr/lib
  # shared object search path $q is all wrong
  sed -i ldso/dynlink.c -e s=$q=$LIBRARY_PATH= || die
 }

src_configure()
 {
  local b=`basename $BASE_DIR`
  [ $stage == 1 ] && fat-gentoo-export_CC || CC=${b}-gcc
  local t=$b cross=
  PATH=${EPREFIX}$BASE_DIR/bin:$PATH
  [ $CPU == i386 ] && 
   {
    t=i386-${b#*-}
    cross="CROSS_COMPILE=${b}-"
    CFLAGS='-march=atom -m32'
   }
  local c="CC=$CC --syslibdir=$LIBRARY_PATH --disable-gcc-wrapper 
           --prefix=${EPREFIX}$BASE_DIR --build=$b --host=$b --target=$t"
  ./configure $cross $c
 }

src_install()
 {
  emake DESTDIR=$ED install
  einfo BITS=$BITS
  [ $BITS == 64 ] &&
   {
    # install ldd executale
    {
     cd ${ED}$BASE_DIR && 
     mkdir bin && cd bin
     ln -s ../lib/libc.so ldd &&
     ln -s ../lib/libc.so ${CPU}-linux-musl-ldd 
    } || die
   }
  # TODO: for i386 don't install headers to avoid file collision
  unset myP x
  unset use_musl use_uclibc stage BITS BASE_DIR LIBRARY_PATH
 }
