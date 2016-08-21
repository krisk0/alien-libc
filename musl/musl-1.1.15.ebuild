# Copyright      2016 Денис Крыськов
# Distributed under the terms of the GNU General Public License v3

EAPI=5

inherit fat-gentoo

HOMEPAGE=http://www.musl-libc.org
SRC_URI=$P.tar.gz

KEYWORDS='-* i386 amd64'
SLOT=0

DEPEND="$CATEGORY/gcc-$PN"
RESTRICT=strip
QA_SONAME="/usr/lib/libc.so"
QA_DT_NEEDED="/usr/lib/libc.so"

src_prepare()
 {
  local q=/lib:/usr/local/lib:/usr/lib
  # shared object search path $q is all wrong
  sed -i ldso/dynlink.c -e s=$q=$LIBRARY_PATH= || die
 }

src_configure()
 {
  PATH=${EPREFIX}$BASE_DIR/bin:$PATH
  local b=`basename $BASE_DIR`
  ./configure --prefix=$BASE_DIR \
   --libdir=$LIBRARY_PATH \
   --syslibdir=$LIBRARY_PATH \
  --enable-optimize CROSS_COMPILE=${b}- \
   CC=${b}-gcc
 }

src_install()
 {
  emake DESTDIR=$ED install
  unset PATH
  unset use_musl use_uclibc stage BITS BASE_DIR LIBRARY_PATH
 }
