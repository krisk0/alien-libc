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
  local t=$b
  [ $CPU == i386 ] || PATH=${EPREFIX}$BASE_DIR/bin:$PATH
  [ $CPU == i386 ] && 
   {
    t=i386-${b#*-}
    die 'try CROSS_COMPILE=${b}-'
    local BIN=$WORKDIR/bin.utils
    mkdir -p $BIN
    for x in ar as c++filt dwp elfedit gprof ld ld.bfd ld.gold nm objcopy \
             objdump ranlib readelf size strings strip ; do
     ln -s ${EPREFIX}$BASE_DIR/bin/x86_64-linux-musl-$x \
           $BIN/i386-linux-musl-$x || die
    done
    PATH=$BIN:$PATH
   }
  local c="CC=$CC --syslibdir=$LIBRARY_PATH --disable-gcc-wrapper 
           --prefix=${EPREFIX}$BASE_DIR --build=$b --host=$b --target=$t"
  ./configure $c
 }

src_install()
 {
  emake DESTDIR=$ED install
  # for i386 don't install headers to avoid file collision
  unset myP x
  unset use_musl use_uclibc stage BITS BASE_DIR LIBRARY_PATH
 }
