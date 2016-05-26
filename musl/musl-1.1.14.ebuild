# Copyright      2016 Денис Крыськов
# Distributed under the terms of the GNU General Public License v2

EAPI=5

HOMEPAGE=http://www.musl-libc.org
SRC_URI=$P.tar.gz

KEYWORDS='-* amd64'
SLOT=0

DEPEND="$CATEGORY/gcc-$PN"
RESTRICT=strip

src_prepare()
 {
  b=x86_64-linux-$PN
  p=/usr/$b
  q=/lib:/usr/local/lib:/usr/lib
  # shared object search path $q is all wrong
  sed -i ldso/dynlink.c -e s=$q=${EPREFIX}$p/lib64= || die
 }

src_configure()
 {
  PATH=${EPREFIX}$p/bin:$PATH
  ./configure --prefix=${EPREFIX}$p --enable-optimize CROSS_COMPILE=${b}- \
   CC=${b}-gcc CFLAGS='-O2 -march=native'
 }

src_install()
 {
  emake DESTDIR=$ED install
  unset b p q
 }
