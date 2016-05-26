# Copyright      2016 Денис Крыськов
# Distributed under the terms of the GNU General Public License v2

EAPI=5

HOMEPAGE=http://www.musl-libc.org
SRC_URI=$P.tar.gz

KEYWORDS='-* amd64'
SLOT=0

DEPEND="$CATEGORY/gcc-$PN"
RESTRICT=strip

src_configure()
 {
  b=x86_64-linux-$PN
  p=/usr/$b
  PATH=${EPREFIX}$p/bin:$PATH
  ./configure --prefix=${EPREFIX}$p --enable-optimize CROSS_COMPILE=${b}- \
   CC=${b}-gcc CFLAGS='-O2 -march=native'
 }

src_install()
 {
  emake DESTDIR=$ED install
  unset b p
 }
