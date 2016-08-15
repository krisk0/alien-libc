# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=4

inherit fat-gentoo

# On stage 0 build no 32-bit library

inherit eutils libtool multilib-minimal

DESCRIPTION="An arithmetic library, required to build GMP"
HOMEPAGE=http://mpc.multiprecision.org
SRC_URI=http://www.multiprecision.org/mpc/download/$P.tar.gz

LICENSE=LGPL-2.1
SLOT=0
KEYWORDS="*- amd64"

GMP=$CATEGORY/${PN/mpc/gmp}
MPFR=$CATEGORY/${PN/mpc/mpfr}
GCC=$CATEGORY/gcc-${PN#mpc-}

RDEPEND="$GMP $MPFR"
DEPEND="$RDEPEND $([ $stage == 0 ] || echo $GCC)"

src_prepare() 
 {
  elibtoolize #347317
 }

multilib_src_configure() 
 {
  [ $stage == 0 ] &&
   local o='--disable-shared --enable-static' \
  ||
   local o='--enable-shared  --enable-static'
  ECONF_SOURCE="$S" econf $o \
   --with-gmp="$EPREFIX/$BASE_DIR/gmp" \
   --with-mpfr="$EPREFIX/$BASE_DIR/gmp" 
 }

multilib_src_install_all() 
 {
  [ $stage == 0 ] && find "$ED/usr" -name '*.la' -delete
  fat-gentoo-move_usr gmp
  unset BASE_DIR GMP MPFR GCC use_musl use_uclibc stage
 }
