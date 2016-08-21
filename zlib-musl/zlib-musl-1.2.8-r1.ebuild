# Copyright 1999-2014 Gentoo Foundation
# Copyright      2016 Денис Кыськов
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=4
AUTOTOOLS_AUTO_DEPEND=no

inherit autotools toolchain-funcs multilib multilib-minimal fat-gentoo

myP=zlib-$PV
DESCRIPTION="Standard (de)compression library"
HOMEPAGE="http://www.zlib.net/"
SRC_URI="http://zlib.net/$myP.tar.gz
 http://www.gzip.org/zlib/$myP.tar.gz
 http://www.zlib.net/current/beta/$myP.tar.gz"

LICENSE=ZLIB
SLOT=0
KEYWORDS="-* i386 amd64"
IUSE+=" minizip static-libs"

DEPEND="minizip? ( ${AUTOTOOLS_DEPEND} )"
RDEPEND=""
DOCS=( )
S="$WORKDIR/$myP"

src_prepare() {
 fat-gentoo-export_CC
 [ -z "$CXX" ] && die
 
 use minizip &&
  {
   cd contrib/minizip || die
   eautoreconf
  }

 multilib_copy_sources
}

echoit() { echo "$@"; "$@"; }

multilib_src_configure() {
 local uname=linux
 echoit ./configure \
  --shared \
  --prefix=$EPREFIX/$BASE_DIR \
  --libdir=$EPREFIX/$BASE_DIR/$(get_libdir) \
  --uname=$uname \
  || die

 use minizip && 
  {
   cd contrib/minizip || die
   econf $(use_enable static-libs static) --prefix=$EPREFIX/$BASE_DIR
  }
}

multilib_src_compile() {
 emake
 use minizip && emake -C contrib/minizip
}

sed_macros() {
 # clean up namespace a little #383179
 # we do it here so we only have to tweak 2 files
 sed -i -r 's:\<(O[FN])\>:_Z_\1:g' "$@" || die
}

multilib_src_install() {
 emake install DESTDIR=$D LDCONFIG=:
 sed_macros ${ED}$BASE_DIR/include/*.h

 use minizip &&  
  {   
   emake -C contrib/minizip install DESTDIR=$D
   sed_macros ${ED}$BASE_DIR/include/minizip/*.h
  }

 cd ${ED}$BASE_DIR || die

 rm -rf share

 use static-libs || 
  {
   find . -name '*.a' -delete
   find . -name '*.la' -delete
  }
 
 cd $(get_libdir) || die
 sed -e s://:/:g -i `find . -name '*.pc'`
 find . -type l -delete
 mv libz.so.1.* libz.so.1
 mv libminizip.so.1.* libminizip.so.1
 sed -i libm*.la -e "s:library_names=.*:library_names='libminizip.so.1':"
}

multilib_src_install_all() {
 unset myP
}
